//
//  Debugging.swift
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

import ResolveKit

extension MapViewController: CorePrintsStateRestoration /*, CorePrintsViewControllerLayout*/ {

	override var debugDescription: String {
		return "\(type(of: self)).\(self.hashValue)" // TODO: Maybe include the current location in the scrollview
	}
}

#if canImport(UIKit)

extension SettingsTableViewCell {

	override var debugDescription: String {
		let title = textLabel?.text ?? "<none>"
		return "\(type(of: self))[\(title)]"
	}
}

extension SettingsTableViewController {

	override var debugDescription: String {
		return "\(type(of: self))"
	}
}

#endif
