//
//  SplitViewController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2018 The App Studio LLC.
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

final class SplitViewController: CoreSplitViewController {

	// MARK: - Public properties and methods

	public func getRestorableActivity() -> NSUserActivity? {
		guard let detailViewController = self.detailViewController else { return nil }
		if let navigationController = detailViewController as? UINavigationController, let topViewController = navigationController.topViewController {
			return topViewController.userActivity
		}
		return detailViewController.userActivity
	}

	// MARK: - CoreSplitViewController overrides

	override func restoreUserActivityState(_ activity: NSUserActivity) {
		super.restoreUserActivityState(activity)
		// UISplitViewController only ever has 1 or 2 viewcontrollers
		guard let masterViewController = viewControllers.first else { return }
		masterViewController.restoreUserActivityState(activity)
		// Restoring activity on the masterViewController may have created a detailViewController
		guard let detailViewController = self.detailViewController else { return }
		detailViewController.restoreUserActivityState(activity)
	}

	@available(iOS 9.0, tvOS 9.0, *)
	override var preferredFocusEnvironments: [UIFocusEnvironment] {
		if let viewController = viewControllers.last {
			return viewController.preferredFocusEnvironments
		}
		return super.preferredFocusEnvironments
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		setNeedsFocusUpdate()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		#if os(iOS) && targetEnvironment(macCatalyst)
		primaryBackgroundStyle = .sidebar
		#endif
		updateSplitViewController()
	}

	// MARK: - Private properties and methods

	func updateSplitViewController() {
		// TODO: Don't perform during state restoration?
		guard traitCollection.horizontalSizeClass == .regular, detailViewController == nil else { return }
		guard let masterNavigationController = viewControllers.first as? UINavigationController else { return }
		guard let settingsViewController = masterNavigationController.topViewController as? SettingsTableViewController else { return }
		settingsViewController.showDefaultDetailViewController(self)
	}
}
