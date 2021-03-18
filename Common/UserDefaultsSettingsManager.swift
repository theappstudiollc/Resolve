//
//  UserDefaultsSettingsManager.swift
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

import Foundation

/// Manages settings stored in a UserDefaults container
open class UserDefaultsSettingsManager {

	/// The provided UserDefaults where the subclass stores settings
	public let userDefaults: UserDefaults

	/// Initializes a new instance of the CoreUserDefaultsSettingsManager
	///
	/// - Parameters:
	///   - userDefaults: The UserDefaults where the subclass will store settings
	public init(userDefaults: UserDefaults = UserDefaults.standard) {
		self.userDefaults = userDefaults
	}
}
