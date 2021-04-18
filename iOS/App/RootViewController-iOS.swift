//
//  RootViewController-iOS.swift
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

import UIKit

extension RootViewController {
	
	// MARK: - UIViewController overrides
	
	override func addChild(_ childController: UIViewController) {
		super.addChild(childController)
		guard childController === activeChild else { return }
		UIView.animate(withDuration: activeChildTransitionDuration, animations: { self.setNeedsStatusBarAppearanceUpdate() })
	}
	
	override var childForStatusBarHidden: UIViewController? {
		if let presentedViewController = presentedViewController, presentedViewController.modalPresentationCapturesStatusBarAppearance {
			return presentedViewController
		}
		return activeChild
	}
	
	override var childForStatusBarStyle: UIViewController? {
		if let presentedViewController = presentedViewController, presentedViewController.modalPresentationCapturesStatusBarAppearance {
			return presentedViewController
		}
		return activeChild
	}
	
	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		if let activeChild = activeChild {
			return activeChild.preferredInterfaceOrientationForPresentation
		}
		return super.preferredInterfaceOrientationForPresentation
	}

	override var shouldAutorotate: Bool {
		if let activeChild = activeChild {
			return activeChild.shouldAutorotate
		}
		return super.shouldAutorotate
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		if let activeChild = activeChild {
			return activeChild.supportedInterfaceOrientations
		}
		return super.supportedInterfaceOrientations
	}
}
