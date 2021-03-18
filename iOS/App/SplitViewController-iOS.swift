//
//  SplitViewController-iOS.swift
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

extension SplitViewController {

	// MARK: - CoreSplitViewController overrides

	override func applicationFinishedRestoringState() {
		super.applicationFinishedRestoringState()
		if let detailViewController = self.detailViewController {
			setupDetailNavigationItems(detailViewController)
		}
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		if let detailViewController = self.detailViewController{
			return detailViewController.preferredInterfaceOrientationForPresentation
		}
		return super.preferredInterfaceOrientationForPresentation
	}
	
	override var shouldAutorotate: Bool {
		if let detailViewController = self.detailViewController {
			return detailViewController.shouldAutorotate
		}
		return super.shouldAutorotate
	}

	override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
		// TODO: Figure out how to make cells stay selected, or match Settings by defaulting to General
		setupDetailNavigationItems(vc)
		/* ASKAPPLE: These didn't work to force an orientation back (may not be possible)
		UIApplication.shared.statusBarOrientation = vc.preferredInterfaceOrientationForPresentation
		UIViewController.attemptRotationToDeviceOrientation()
		*/
		super.showDetailViewController(vc, sender: sender)
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		var retVal = super.supportedInterfaceOrientations
		if let presentedViewController = presentedViewController, !presentedViewController.isKind(of: UIAlertController.self) {
			retVal = retVal.intersection(presentedViewController.supportedInterfaceOrientations)
		}
		if let detailViewController = self.detailViewController {
			retVal = retVal.intersection(detailViewController.supportedInterfaceOrientations)
		}
		return retVal
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: { context in
			self.updateSplitViewController()
		}, completion: nil)
	}

	// MARK: - Private methods

	func setupDetailNavigationItems(_ detailViewController: UIViewController) {
		guard let viewController = topDetailViewController(detailViewController) else { return }
//		if viewController.navigationItem.leftBarButtonItem == nil {
//			viewController.navigationItem.leftBarButtonItem = displayModeButtonItem
//		} else {
			if viewController.navigationItem.leftItemsSupplementBackButton {
				var leftBarButtonItems = viewController.navigationItem.leftBarButtonItems ?? []
				leftBarButtonItems.append(displayModeButtonItem)
//				leftBarButtonItems.insert(displayModeButtonItem, at: 0)
				viewController.navigationItem.leftBarButtonItems = leftBarButtonItems
			}
//		}
	}

	func topDetailViewController(_ viewController: UIViewController) -> UIViewController? {
		if let navigationController = viewController as? UINavigationController {
			return navigationController.topViewController
		}
		return viewController
	}
}
