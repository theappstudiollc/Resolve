//
//  AppGroupProviding.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2018 The App Studio LLC.
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

/// Provides App Group information to an app and its extensions. Requires a properly configured app through its Info.plist and entitlements, otherwise these properties will throw a fatal error.
public protocol AppGroupProviding {

	/// The local file URL for the App Group directory
	var appGroupContainer: URL { get }
	
	/// The UserDefaults that may be shared by the App Group
	var appGroupDefaults: UserDefaults { get }
	
	/// The shared HTTPCookieStorage that may be shared by the App Group
	var appGroupCookies: HTTPCookieStorage { get }
}
