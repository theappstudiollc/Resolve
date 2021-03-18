//
//  MainWindowController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2019 The App Studio LLC.
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

final class MainWindowController: NSWindowController {
	
	@IBOutlet var segmentedControl: NSSegmentedControl!

	var tabViewController: TabViewController? {
		return contentViewController as? TabViewController
	}

	override func restoreUserActivityState(_ userActivity: NSUserActivity) {
		// We want to ensure the correct viewController is selected and restored
		super.restoreUserActivityState(userActivity)
		guard let tabViewController = self.tabViewController else { return }
		tabViewController.restoreUserActivityState(userActivity)
	}

	override func windowDidLoad() {
		super.windowDidLoad()
		bindSegmentedControl()
	}

	private func bindSegmentedControl() {
		guard let tabViewController = self.tabViewController else { return }
		segmentedControl.bind(.selectedIndex, to: tabViewController, withKeyPath: #keyPath(NSTabViewController.selectedTabViewItemIndex), options: nil)
	}
}
