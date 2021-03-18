//
//  WatchSessionSettingsService.swift
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

#if os(iOS)

extension Notification.Name {

	static let messageCountChanged: Notification.Name = "WatchSessionSettingsService.messageCountChanged"
}

extension Notification.Name: ExpressibleByStringLiteral {

	public init(stringLiteral value: String) {
		self.init(value)
	}
}

#endif

/// Provides settings for an app and its extensions that share an App Group
public protocol WatchSessionSettingsService: class {

	#if os(watchOS)

	/// Represents the last value written to the SharedEvent complication, so that unnecessary updates can be avoided
	var lastSharedEventComplicationCount: Int { get set }

	#endif

	var messageCount: Int { get set }
}
