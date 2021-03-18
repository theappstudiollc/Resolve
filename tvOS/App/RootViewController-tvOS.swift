//
//  RootViewController-tvOS.swift
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

import UIKit

extension RootViewController {
	
	// MARK: - UIViewController overrides
	
	override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
		// Automatically embed inside a NavigationController
		guard let storyboard = storyboard, let navigationController = storyboard.instantiateViewController(withIdentifier: "\(NavigationController.self)") as? NavigationController else {
			super.showDetailViewController(vc, sender: sender)
			return
		}
		navigationController.viewControllers = [vc]
		activeChild = navigationController
	}
}
