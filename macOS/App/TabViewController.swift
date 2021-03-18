//
//  TabViewController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2020 The App Studio LLC.
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

import AppKit
import ResolveKit

final class TabViewController: NSTabViewController {

	@Service var userActivityService: UserActivityService

	// MARK: - NSTabViewController overrides

	override func restoreUserActivityState(_ userActivity: NSUserActivity) {
		// We want to ensure the correct viewController is selected and restored
		super.restoreUserActivityState(userActivity)
		guard let activityType = userActivityService.activityType(with: userActivity.activityType) else { return }
		let tab = self.tab(for: activityType)
		selectTab(tab)
		tabViewItem(for: tab).viewController?.restoreUserActivityState(userActivity)
	}

	// MARK: - Private properties and methods

	enum Tab: Int {
		case camera
		case conversation
		case coreData
		case map
		case photos
		case iBeacon
	}

	func selectTab(_ tab: Tab) {
		selectedTabViewItemIndex = tab.rawValue
	}

	func tab(for activityType: CustomActivityType) -> Tab {
		switch activityType {
		case .camera: return .camera
		case .conversation: return .conversation
		case .coreData: return .coreData
		case .iBeacon: return .iBeacon
		case .map: return .map
		case .photos: return .photos
		}
	}

	func tabViewItem(for tab: Tab) -> NSTabViewItem {
		return tabViewItems[tab.rawValue]
	}
}
