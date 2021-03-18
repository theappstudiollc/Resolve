//
//  CustomViewController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2017 The App Studio LLC.
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

open class CustomViewController: CoreViewController {
	
	// MARK: - UIViewController overrides
	
	override open func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		modalPresentationStyle = UIModalPresentationStyle(rawValue: coder.decodeInteger(forKey: #keyPath(modalPresentationStyle)))!
		#if os(iOS)
		modalPresentationCapturesStatusBarAppearance = coder.decodeBool(forKey: #keyPath(modalPresentationCapturesStatusBarAppearance))
		#endif
		transitioningDelegate = coder.decodeObject(forKey: #keyPath(transitioningDelegate)) as? UIViewControllerTransitioningDelegate
	}
	
	override open func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		for childViewController in children {
			if let restorationIdentifier = childViewController.restorationIdentifier {
				coder.encode(childViewController, forKey: restorationIdentifier)
			}
		}
		coder.encode(modalPresentationStyle.rawValue, forKey: #keyPath(modalPresentationStyle))
		#if os(iOS)
		coder.encode(modalPresentationCapturesStatusBarAppearance, forKey: #keyPath(modalPresentationCapturesStatusBarAppearance))
		#endif
		if let restorableTransitioningDelegate = transitioningDelegate as? UIStateRestoring {
			coder.encode(restorableTransitioningDelegate, forKey: #keyPath(transitioningDelegate))
		}
	}
	
	override open var transitioningDelegate: UIViewControllerTransitioningDelegate? {
		didSet {
			strongTransitioningDelegate = transitioningDelegate
		}
	}
	
	// MARK: - Private properties and methods
	
	private var strongTransitioningDelegate: UIViewControllerTransitioningDelegate?
}
