//
//  NavigationController-iOS.swift
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

extension NavigationController {

	// MARK: - Interface Builder properties and methods

	@IBAction private func navigationBarHideTapGestureRecognized(_ sender: Any) {
		setNeedsStatusBarAppearanceUpdate()
	}

	// MARK: - ResolveNavigationController overrides
	
	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		if let visibleViewController = visibleViewController {
			return visibleViewController.preferredInterfaceOrientationForPresentation
		}
		return super.preferredInterfaceOrientationForPresentation
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		if let presentedViewController = presentedViewController, presentedViewController.modalPresentationCapturesStatusBarAppearance {
			return presentedViewController.preferredStatusBarStyle
		}
		if let topViewController = topViewController {
			return topViewController.preferredStatusBarStyle
		}
		return super.preferredStatusBarStyle
	}

	override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
		super.setNavigationBarHidden(hidden, animated: animated)
		setNeedsStatusBarAppearanceUpdate()
	}

	override var shouldAutorotate: Bool {
		guard let visibleViewController = visibleViewController else { return true }
		return visibleViewController.shouldAutorotate
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		var retVal = super.supportedInterfaceOrientations
		if let presentedViewController = presentedViewController, !presentedViewController.isKind(of: UIAlertController.self) {
			retVal = retVal.intersection(presentedViewController.supportedInterfaceOrientations)
		}
		if let topViewController = topViewController {
			retVal = retVal.intersection(topViewController.supportedInterfaceOrientations)
		}
		return retVal
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		#if targetEnvironment(macCatalyst)
			hidesBarsOnTap = false
		#else
			barHideOnTapGestureRecognizer.addTarget(self, action: #selector(navigationBarHideTapGestureRecognized(_:)))
			if #available(iOS 11.0, tvOS 11.0, *) {
				navigationBar.prefersLargeTitles = true
			}
		#endif
	}
}
