//
//  CustomRestorable.swift
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

import UIKit

open class CustomRestorable: NSObject, UIObjectRestoration, UIStateRestoring {
	
	// MARK: - NSObject overrides
	
	deinit {
		print("\(self) deinit")
	}
	
	required override public init() {
		super.init()
		UIApplication.registerObject(forStateRestoration: self, restorationIdentifier: "\(self)")
	}
	
	// MARK: - Public properties and methods
	
	public private(set) var isRestoring = false
	
	// MARK: - UIObjectRestoration properties and methods
	
	public static func object(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIStateRestoring? {
		let retVal = self.init()
		retVal.isRestoring = true
		return retVal
	}
	
	// MARK: - UIStateRestoring properties and methods
	
	public var objectRestorationClass: UIObjectRestoration.Type? {
		return type(of: self)
	}
}
