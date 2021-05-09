//
//  ResolveViewController.swift
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

import CoreResolve

open class ResolveViewController: CoreViewController {

	@Service public var loggingService: CoreLoggingService

	// MARK: - CoreViewController overrides

	#if os(iOS) || os(tvOS)

	#elseif os(macOS)
	
	/// Common version of `viewDidAppear` matching UIKit. `animated` will always be false on macOS
	open func viewDidAppear(_ animated: Bool) { }

	/// Common version of `viewDidDisappear` matching UIKit. `animated` will always be false on macOS
	open func viewDidDisappear(_ animated: Bool) { }

	/// Common version of `viewWillAppear` matching UIKit. `animated` will always be false on macOS
	open func viewWillAppear(_ animated: Bool) { }
	
	/// Common version of `viewWillDisappear` matching UIKit. `animated` will always be false on macOS
	open func viewWillDisappear(_ animated: Bool) { }
	
	open override func viewDidAppear() {
		super.viewDidAppear()
		viewDidAppear(false)
	}
	
	open override func viewDidDisappear() {
		super.viewDidDisappear()
		viewDidDisappear(false)
	}
	
	open override func viewWillAppear() {
		super.viewWillAppear()
		viewWillAppear(false)
	}
	
	open override func viewWillDisappear() {
		super.viewWillDisappear()
		viewWillDisappear(false)
	}

	#endif
}
