//
//  MapView.swift
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

@IBDesignable final class MapView: View {

	// MARK: - View overrides
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupMapView()
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupMapView()
	}
	
	override var intrinsicContentSize: CGSize {
		return mapSize
	}

	#if os(iOS) || os(tvOS)

	override func layoutSublayers(of layer: CALayer) {
		guard layer === mapLayer.superlayer else { return }
		mapLayer.frame = layer.bounds
	}

	override func willMove(toWindow newWindow: UIWindow?) {
		super.willMove(toWindow: newWindow)
		guard window == nil, let newWindow = newWindow else { return }
		assignContentScale(newWindow.traitCollection.displayScale)
	}
	
	#elseif os(macOS)
	
	override var isFlipped: Bool {
		return true
	}

	override func viewWillMove(toWindow newWindow: NSWindow?) {
		super.viewWillMove(toWindow: newWindow)
		guard window == nil, let newWindow = newWindow else { return }
		assignContentScale(newWindow.backingScaleFactor)
	}

	#endif
	
	// MARK: - Private properties and methods
		
	private var mapLayer = CATiledLayer()
	private var mapLayerDelegate = MapLayerDelegate()
	private var mapSize = CGSize(width: View.noIntrinsicMetric, height: View.noIntrinsicMetric) {
		didSet {
			invalidateIntrinsicContentSize()
		}
	}

	private func assignContentScale(_ contentScale: CGFloat) {
		mapLayer.contentsScale = contentScale
		mapLayer.tileSize = CGSize(width: 256 * contentScale, height: 256 * contentScale)
	}
	
	private func setupMapView() {
		mapLayer.contentsGravity = .center
		mapLayer.levelsOfDetail = 19
		mapLayer.levelsOfDetailBias = 18
		mapLayer.delegate = mapLayerDelegate
		#if os(iOS) || os(tvOS)
		layer.addSublayer(mapLayer)
		#else
		mapLayer.needsDisplayOnBoundsChange = true
		self.layer = mapLayer
		#endif
		mapSize = CGSize(width: 1024, height: 1024)
	}
}
