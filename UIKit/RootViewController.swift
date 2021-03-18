//
//  RootViewController.swift
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

final class RootViewController: CoreContainerViewController {
	
	// MARK: - Interface Builder properties and methods
	
	@IBAction private func unwindToRootViewController(_ segue: UIStoryboardSegue) {
		guard segue.destination === self, let segueIdentifier = segueIdentifierForSegue(segue) else {
			return
		}
		switch segueIdentifier {
		case .leaveSplash:
			performSegue(withIdentifier: .leaveSplash, sender: self)
		default: break
		}
	}
	
	// MARK: - Public properties and methods
	
	var isRestoringState = false // TODO: Maybe we utilize the userActivity property to determine where to go, since it is needed for iOS 13+

	var restorationActivity: NSUserActivity?

	public func getRestorableActivity() -> NSUserActivity? {
		guard let activeChild = activeChild else { return nil }
		guard let splitViewController = activeChild as? SplitViewController else {
			return activeChild.userActivity
		}
		return splitViewController.getRestorableActivity()
	}

	// MARK: - ContainerViewController overrides
	
	override func applicationFinishedRestoringState() {
		super.applicationFinishedRestoringState()
		isRestoringState = false
		UIAccessibility.post(notification: .screenChanged, argument: nil)
	}

	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		guard let activeChild = activeChild, let identifier = activeChild.restorationIdentifier else { return }
		// TODO: Maybe encode the storyboard segue?
		coder.encode(activeChild, forKey: identifier)
	}

	override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
		// ASKAPPLE: How can we tell by this point whether the Adaptive segue is Present or Popover? Here's how
		#if os(iOS)
		print("Is Popover: \(viewControllerToPresent.modalPresentationStyle == .popover)")
		#endif
		super.present(viewControllerToPresent, animated: flag, completion: completion)
	}

	override func restoreUserActivityState(_ activity: NSUserActivity) {
		super.restoreUserActivityState(activity)
		if let activeChild = activeChild {
			activeChild.restoreUserActivityState(activity)
		} else if isViewLoaded {
			fatalError("Unexpected state for restoreUserActivityState(_:): isViewLoaded = true, activeChild = nil")
		} else {
			restorationActivity = activity
		}
	}
	
	@discardableResult override func setActiveChild(_ activeChild: UIViewController?, animation: Animation, completion: (() -> Void)? = nil) throws -> Bool {
		return try super.setActiveChild(activeChild, animation: animation) {
			completion?()
			UIAccessibility.post(notification: .screenChanged, argument: nil)
		}
	}
	
	override func show(_ vc: UIViewController, sender: Any?) {
		activeChild = vc
		overrideChildTraitCollection(with: view.bounds.size)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// TODO: Merge restorationActivity with isRestoringState
		if let restorationActivity = restorationActivity {
			performSegue(withIdentifier: .restoreState, sender: self)
			activeChild?.restoreUserActivityState(restorationActivity)
			self.restorationActivity = nil
		} else if isRestoringState {
			// Make sure this segue points to a view controller with the proper heirarchy
			// (including restoration identifiers) that can restore ANY child view controller
			// that may have been saved. (e.g. UISplitViewController/UINavigationController)
			performSegue(withIdentifier: .restoreState, sender: self)
		} else if #available(iOS 13.0, tvOS 13.0, *) {
			// TODO: How can we determine whether this is starting in the background or not so that we can skip the splash video?
			// Under a normal launch this UIResponder's .next is nil, and the window is nil too -- not sure how to detect a "normal" launch
			// The scene's `window`, however, DOES know about this RootViewController....
			performSegue(withIdentifier: .showSplash, sender: self)
		} else if UIApplication.shared.applicationState != .background {
			performSegue(withIdentifier: .showSplash, sender: self)
		} else {
			performSegue(withIdentifier: .leaveSplash, sender: self)
		}
//		assert(_activeChild != nil, "We do not support a nil activeChild at this point")
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		overrideChildTraitCollection(with: size)
		super.viewWillTransition(to: size, with: coordinator)
	}
	
	// MARK: - Private methods

	internal func overrideChildTraitCollection(with size: CGSize) {
		// EXPERIMENT: giving iPhone X same rotation behavior as iPhone+
		guard let activeChild = activeChild, activeChild is UISplitViewController else { return }
		if traitCollection.userInterfaceIdiom == .phone,
			traitCollection.horizontalSizeClass == .compact,
			traitCollection.displayScale == 3, size.width / size.height > 2.0 {
			setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: .regular), forChild: activeChild)
		} else {
			setOverrideTraitCollection(nil, forChild: activeChild)
		}
	}
	
	internal func presentViewController(forClass aClass: AnyClass, inStoryboard storyboardForVC: UIStoryboard? = nil, completion: (() -> Void)? = nil) {
		guard let storyboardForVC = storyboardForVC ?? storyboard else { return }
		let identifier = NSStringFromClass(aClass.self).components(separatedBy: ".").last!
		let viewController = storyboardForVC.instantiateViewController(withIdentifier: identifier)
		show(viewController, sender: self)
	}
}

extension RootViewController: CoreSegueHandling {
	
	internal enum SegueIdentifier: String, CaseIterable {
		case leaveSplash
		case restoreState
		case showSplash
	}
}
