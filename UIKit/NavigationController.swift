//
//  NavigationController.swift
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

/// NavigationController base class for the Resolve app
class NavigationController: ResolveNavigationController {

	// MARK: - ResolveNavigationController overrides
	
	deinit {
		#if os(iOS) && !targetEnvironment(macCatalyst)
			barHideOnTapGestureRecognizer.removeTarget(self, action: nil)
		#endif
	}

	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		#if os(iOS)
			hidesBarsOnTap = coder.decodeBool(forKey: #keyPath(hidesBarsOnTap))
		#endif
		setNavigationBarHidden(coder.decodeBool(forKey: #keyPath(isNavigationBarHidden)), animated: false)
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		#if os(iOS)
			coder.encode(hidesBarsOnTap, forKey: #keyPath(hidesBarsOnTap))
		#endif
		coder.encode(isNavigationBarHidden, forKey: #keyPath(isNavigationBarHidden))
	}

	override func restoreUserActivityState(_ activity: NSUserActivity) {
		super.restoreUserActivityState(activity)
		viewControllers.forEach { $0.restoreUserActivityState(activity) }
	}
}
