//
//  AppInfoService.swift
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

/// Provides app information to an application
public protocol AppInfoService {
	
	/// The app's `build` string
	var appBuild: String { get }
	
	/// The app's `version` string (e.g. 1.0.0). Does not include build
	var appVersion: String { get }
}
