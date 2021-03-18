//
//  MapScrollView.swift
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
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit

protocol MapScrollViewDelegate: class {

	func mapScrollViewDidScroll(_ mapScrollView: MapScrollView)
}

#endif

final class MapScrollView: ScrollView {

	// MARK: - ScrollView overrides
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupMapScrollView()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupMapScrollView()
	}

	#if os(iOS) || os(tvOS)

	override func layoutSubviews() {
		super.layoutSubviews()
		layoutWithUserActivityInfo()
	}

	#elseif os(macOS)

	@objc func clipViewBoundsChanged(notification: Notification) {
		layoutWithUserActivityInfo()
		delegate?.mapScrollViewDidScroll(self)
	}

	weak var delegate: MapScrollViewDelegate?

	#endif

	// MARK: - Public methods

	public func applyUserActivityInfo(_ userInfo: [AnyHashable : Any]?) {
		userActivityInfo = userInfo
	}

	public func getUserActivityInfo() -> [AnyHashable : Any] {
		#if os(iOS) || os(tvOS)
		let rect = CGRect(origin: contentOffset, size: bounds.size)
		return [
			currentCenterKey : [rect.center.x, rect.center.y],
			currentZoomKey : zoomScale
		]
		#elseif os(macOS)
		return [
			currentCenterKey : [documentVisibleRect.center.x * magnification, documentVisibleRect.center.y * magnification],
			currentZoomKey : magnification
		]
		#endif
	}

	// MARK: - Private properties and methods

	private let currentCenterKey = "currentCenter"
	private let currentZoomKey = "currentZoom"
	private var needsUserActivityUpdate = false
	private var userActivityInfo: [AnyHashable : Any]? {
		didSet { layoutWithUserActivityInfo() }
	}

	private func setupMapScrollView() {
		#if os(iOS) || os(tvOS)
		decelerationRate = .fast
		#elseif os(macOS)
		contentView.postsBoundsChangedNotifications = true
		NotificationCenter.default.addObserver(self, selector: #selector(clipViewBoundsChanged(notification:)), name: NSView.boundsDidChangeNotification, object: contentView)
		#endif
	}

	private func layoutWithUserActivityInfo() {
		guard window != nil, let mapInfo = userActivityInfo, let zoomScale = mapInfo[currentZoomKey] as? CGFloat, let points = mapInfo[currentCenterKey] as? [CGFloat], points.count == 2 else {
			return
		}
		userActivityInfo = nil // Clear this out so that we don't get stack overflows
		#if os(iOS) || os(tvOS)
		setZoomScale(zoomScale, animated: false)
		let size = bounds.size
		let origin = CGPoint(x: points[0] - size.width / 2, y: points[1] - size.height / 2)
		setContentOffset(origin, animated: false)
		#elseif os(macOS)
		let center = NSPoint(x: points[0] / zoomScale, y: points[1] / zoomScale)
		setMagnification(zoomScale, centeredAt: center)
		#endif
	}
}
