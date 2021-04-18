//
//  KeyboardLayoutPlugin.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2021 The App Studio LLC.
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

public class KeyboardLayoutPlugin {

	public let layoutGuide = UILayoutGuide()

	var constraints: BoundingConstraints!
	var keyboardFrameObserver: NSObjectProtocol? {
		willSet {
			guard let oldValue = keyboardFrameObserver else { return }
			notificationCenter.removeObserver(oldValue)
		}
	}
	var lastKeyboardRect: CGRect = .zero
	let notificationCenter: NotificationCenter

	public init(viewController: UIViewController, for view: UIView?, notificationCenter: NotificationCenter = .default) {
		self.notificationCenter = notificationCenter
		layoutGuide.identifier = "\(type(of: viewController)).\(Self.self)"
		let view = view ?? viewController.view!
		view.addLayoutGuide(layoutGuide)
		if #available(iOS 13, *) {
			constraints = layoutGuide.constrain(to: view.safeAreaLayoutGuide)
		} else {
			let topConstraint = layoutGuide.topAnchor.constraint(equalTo: viewController.topLayoutGuide.bottomAnchor)
			let bottomConstraint = viewController.bottomLayoutGuide.topAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
			let horizontalConstraints = layoutGuide.constrainHorizontally(to: view)
			constraints = BoundingConstraints(horizontal: horizontalConstraints, vertical: VerticalBoundingConstraints(top: topConstraint, bottom: bottomConstraint))
		}
		NSLayoutConstraint.activate(constraints)

		keyboardFrameObserver = notificationCenter.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: nil, using: keyboardWillChangeFrame(_:))
	}

	private func keyboardWillChangeFrame(_ notification: Notification) {
		guard let userInfo = notification.userInfo, let owningView = layoutGuide.owningView, let window = owningView.window else { return }

		let keyboardBeginRect = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect
		let keyboardEndRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
		guard keyboardBeginRect != keyboardEndRect || keyboardEndRect != lastKeyboardRect else { return }
		lastKeyboardRect = keyboardEndRect // Record the destination keyboard rect for future comparisons

		let curve = UIView.AnimationCurve(rawValue: userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int)!
		UIView.beginAnimations("\(layoutGuide.identifier).keyboardWillChangeFrame", context: nil)
		UIView.setAnimationBeginsFromCurrentState(true)
		UIView.setAnimationCurve(curve)
		UIView.setAnimationDuration(userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval)

		if #available(iOS 11, *) {
			update(owningView, keyboardRect: keyboardEndRect, safeAreaInsets: owningView.safeAreaInsets)
		} else {
			update(owningView, keyboardRect: keyboardEndRect, safeAreaInsets: .zero)
		}
		window.layoutIfNeeded()

		UIView.commitAnimations()
	}

	private func update(_ view: UIView, keyboardRect: CGRect, safeAreaInsets: UIEdgeInsets) {
		guard let window = view.window else { return }
		let rect = window.convert(keyboardRect, to: view).intersection(view.bounds)
		let additionalBottom = max(0, rect.height - safeAreaInsets.bottom)
		if let scrollView = view as? UIScrollView {
			if scrollView.contentInset.bottom != additionalBottom {
				var inset = scrollView.contentInset
				inset.bottom = additionalBottom
				scrollView.contentInset = inset
			}
			if scrollView.scrollIndicatorInsets.bottom != additionalBottom {
				var indicatorInsets = scrollView.scrollIndicatorInsets
				indicatorInsets.bottom = additionalBottom
				scrollView.scrollIndicatorInsets = indicatorInsets
			}
		}
		if constraints.vertical.bottom.constant != additionalBottom {
			constraints.vertical.bottom.constant = additionalBottom
		}
	}
}
