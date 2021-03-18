//
//  MapViewController.swift
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

import ResolveKit

final class MapViewController: ResolveViewController {

	@Service var userActivityService: UserActivityService

	// MARK: - Interface Builder properties and methods
	
	@IBOutlet var mapScrollView: MapScrollView!
	@IBOutlet var mapView: MapView!

	// MARK: - ResolveViewController overrides

	override func restoreUserActivityState(_ activity: NSUserActivity) {
		super.restoreUserActivityState(activity)
		#if !os(tvOS)
		guard userActivityService.activityType(with: activity.activityType) == .some(.map) else { return }
		#endif
		userActivity = activity
		if isViewLoaded {
			userActivity?.becomeCurrent()
		}
	}

	override func updateUserActivityState(_ activity: NSUserActivity) {
		defer {
			super.updateUserActivityState(activity)
		}
		// TODO: This can be called _after_ the scene has notified which NSUserActivity to restore with (determine whether this matters)
		guard isViewLoaded else { return }
		#if !os(tvOS)
		guard userActivityService.activityType(with: activity.activityType) == .some(.map) else { return }
		activity.addUserInfoEntries(from: [scrollViewUserInfoKey : mapScrollView.getUserActivityInfo()])
		#endif
	}

	override var userActivity: NSUserActivity? {
		didSet { updateUserActivity(userActivity) }
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		#if !os(tvOS) // for now
		if userActivity == nil {
			userActivity = userActivityService.userActivity(for: .map)
		}
		#endif
		userActivity?.needsSave = true
		userActivity?.becomeCurrent()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		mapScrollView.delegate = self
		guard let userActivity = userActivity else { return }
		updateUserActivity(userActivity)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		userActivity?.resignCurrent()
	}

	// MARK - Private properties and methods

	private let scrollViewUserInfoKey = "\(MapScrollView.self)"

	private func updateUserActivity(_ activity: NSUserActivity?) {
		guard isViewLoaded, let activity = activity else { return }
		#if !os(tvOS)
		guard userActivityService.activityType(with: activity.activityType) == .some(.map), let userInfo = activity.userInfo else { return }
		if let mapUserInfo = userInfo[scrollViewUserInfoKey] as? [AnyHashable : Any] {
			mapScrollView.applyUserActivityInfo(mapUserInfo)
		}
		#endif
	}
}

#if os(iOS) || os(tvOS)

extension MapViewController: UIScrollViewDelegate {

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		userActivity?.needsSave = true
	}

	func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
		return false
	}

	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return mapView
	}
}

#elseif os(macOS)

extension MapViewController: MapScrollViewDelegate {

	func mapScrollViewDidScroll(_ mapScrollView: MapScrollView) {
		userActivity?.needsSave = true
	}
}

#endif
