//
//  ResolveNavigationController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2020 The App Studio LLC.
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

import CoreResolve

/// Declares whether the NavigationController simulates prepare(for:sender:) for RootViewController relationship segues and Show segues configured via storyboard
public protocol NavigationUsesPrepareForSegue { }

open class ResolveNavigationController: CoreNavigationController {

	// MARK: - CoreNavigationController overrides

	open override func awakeFromNib() {
		super.awakeFromNib()
		if self is NavigationUsesPrepareForSegue {
			// Simulates the rootViewController segue (in the same place an embed segue would be)
			for child in children {
				let segue = UIStoryboardSegue(identifier: nil, source: self, destination: child)
				prepare(for: segue, sender: self)
			}
		}
	}

	open override func show(_ vc: UIViewController, sender: Any?) {
		// Hook in here instead of pushViewController(_,animated:) because we know who the sender is
		if self is NavigationUsesPrepareForSegue {
			let source = (sender as? UIResponder)?.findResponder(as: UIViewController.self) ?? self
			let segue = UIStoryboardSegue(identifier: nil, source: source, destination: vc)
			prepare(for: segue, sender: sender)
		}
		super.show(vc, sender: sender)
	}

	#if os(iOS)

	open override func viewWillLayoutSubviews() {
		if !once {
			// Work around an issue on iOS 11 & 12 where the large title doesn't automatically scroll
			if #available(iOS 11.0, *), let topViewController = topViewController, topViewController.navigationItem.largeTitleDisplayMode == .automatic {
				topViewController.navigationItem.largeTitleDisplayMode = .never
				topViewController.navigationItem.largeTitleDisplayMode = .automatic
			}
			once = true
		}
		super.viewWillLayoutSubviews()
	}

	var once = false

	#endif
}
