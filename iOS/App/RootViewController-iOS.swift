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
	
	// MARK: - Extension methods
	
	func extensionViewDidLoad() {
		#if !targetEnvironment(macCatalyst) // UIKeyboard doens't make sense on Mac
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
		#endif
	}
	
	// MARK: - Private methods
	
	#if !targetEnvironment(macCatalyst)
	
	@objc internal func keyboardWillChangeFrame(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
			let activeChild = activeChild,
			let activeView = activeChild.viewIfLoaded,
			let window = view.window else { return }
		
		let keyboardBeginRect = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect
		let keyboardEndRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
		guard keyboardBeginRect != keyboardEndRect else { return }
		
		let curve = UIView.AnimationCurve(rawValue: userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int)!
		UIView.beginAnimations("keyboardWillChangeFrame", context: nil)
		UIView.setAnimationBeginsFromCurrentState(true)
		UIView.setAnimationCurve(curve)
		UIView.setAnimationDuration(userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval)
		if #available(iOS 11.0, *) {
			let rect = window.convert(keyboardEndRect, to: activeView).intersection(activeView.bounds)
			activeChild.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: rect.height, right: 0)
		} else {
			// Fallback on earlier versions (use a custom UILayoutGuide)
		}
		view.layoutIfNeeded()
		UIView.commitAnimations()
	}
	
	#endif
}
