//
//  MapLayerDelegate.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2016 The App Studio LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//	   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CoreResolve
import QuartzCore
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class MapLayerDelegate: NSObject, CALayerDelegate {
	
	// MARK: - NSObject overrides
	
	override init() {
		srand48(Int(Date.timeIntervalSinceReferenceDate))
		super.init()
	}
	
	// MARK: - Private methods
	
	typealias APIRequestTask = CoreAPIRequestTask<MapTileAPIRequest>
	
	private var _currentZoom = Int(0)
	private var currentZoom: Int {
		get { return syncQueue.sync { _currentZoom } }
		set { syncQueue.sync(flags: .barrier) { _currentZoom = newValue } }
	}
	private let apiRequest = MapTileAPIRequest(baseURL: URL(string: "https://c.tile.openstreetmap.org/")!)
	private var mapCache = Dictionary<MapTileIdentifierComponents, Image>(minimumCapacity: 1024)
	private var syncQueue = DispatchQueue(label: "\(type(of: MapLayerDelegate.self)).syncQueue", attributes: .concurrent)
	private var taskCache = Dictionary<MapTileIdentifierComponents, APIRequestTask>(minimumCapacity: 256)
	
	private func image(for components: MapTileIdentifierComponents) -> Image? {
		return syncQueue.sync { mapCache[components] }
	}
	
	private func updateImage(_ image: Image, for components: MapTileIdentifierComponents) {
		syncQueue.sync(flags: .barrier) { mapCache[components] = image }
	}
	
	private func task(for components: MapTileIdentifierComponents) -> APIRequestTask? {
		return syncQueue.sync { taskCache[components] }
	}
	
	private func updateTask(_ task: APIRequestTask?, for components: MapTileIdentifierComponents) {
		syncQueue.sync(flags: .barrier) {
			if let task = task {
				taskCache.updateValue(task, forKey: components)?.cancel()
			} else {
				taskCache.removeValue(forKey: components)?.cancel()
			}
		}
	}

	// MARK: - CALayerDelegate methods
	
	func draw(_ layer: CALayer, in context: CGContext) {
		#if os(iOS) || os(tvOS)
		UIGraphicsPushContext(context)
		#else
		NSGraphicsContext.saveGraphicsState()
		NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
		#endif
		let rect = context.boundingBoxOfClipPath
		let zoomRatio = (layer as! CATiledLayer).tileSize.width / (rect.width * layer.contentsScale)
		let drawRect = rect.insetBy(dx: CGFloat(0.5 / zoomRatio), dy: CGFloat(0.5 / zoomRatio))
		let zoom = Int(round(log2(zoomRatio))) + 2
		let column = Int(round(rect.minX / rect.width))
		let row = Int(round(rect.minY / rect.height))
		currentZoom = zoom
		let identifierComponents = MapTileIdentifierComponents(column: column, row: row, zoom: zoom)
		if let tileImage = image(for: identifierComponents) {
			if zoom > 10, #available(iOS 13.0, *) {
				context.saveGState()
				context.translateBy(x: 0, y: rect.maxY)
				context.scaleBy(x: 1, y: -1)
				let inRect = CGRect(x: drawRect.minX, y: drawRect.minY - rect.minY, width: drawRect.width, height: drawRect.height)
				if let cgImage = tileImage.cgImage {
					context.draw(cgImage, in: inRect)
				}
				context.restoreGState()
			} else { // Not sure why this fails at high zoom levels on iOS 13.2
				tileImage.draw(in: drawRect)
			}
		} else if let task = self.task(for: identifierComponents), task.state == .running {
			context.setFillColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
			context.fill(drawRect)
		} else {
			let task = CoreAPIRequestTask(apiRequest: apiRequest, priority: URLSessionTask.highPriority)
			if let tileImage = task.cachedResponse(for: identifierComponents) {
				updateImage(tileImage, for: identifierComponents)
				updateTask(nil, for: identifierComponents)
				tileImage.draw(in: drawRect)
			} else {
				context.setFillColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
				context.fill(drawRect)
				updateTask(task, for: identifierComponents)
				task.performRequest(requestData: identifierComponents) { result in
					switch result {
					case .failure(let error):
						// TODO: Some errors contain a URL Response (maybe add them to error.localized description)
						print("\(identifierComponents) error: \(error.localizedDescription)")
					case .success(let tileImage):
						self.updateImage(tileImage, for: identifierComponents)
						DispatchQueue.main.async {
							if zoom == self.currentZoom {
								layer.setNeedsDisplay(rect)
							}
						}
					}
					self.updateTask(nil, for: identifierComponents)
				}
			}
		}
		let fontSize = CGFloat(24 / zoomRatio)
		let stringPosition = rect.offsetBy(dx: 2 / zoomRatio, dy: 2 / zoomRatio).origin
		NSString(string: identifierComponents.debugDescription).draw(at: stringPosition, withAttributes: [
			.foregroundColor : Color.black.withAlphaComponent(0.6),
			.font : Font.systemFont(ofSize: fontSize)
		])
		#if os(iOS) || os(tvOS)
		UIGraphicsPopContext()
		#else
		NSGraphicsContext.restoreGraphicsState()
		#endif
	}
}

#if os(macOS)
fileprivate extension Image {

	var cgImage: CGImage? {
		var rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
		return cgImage(forProposedRect: &rect, context: nil, hints: nil)
	}
}
#endif
