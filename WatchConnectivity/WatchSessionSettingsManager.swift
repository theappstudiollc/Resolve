//
//  WatchSessionSettingsManager.swift
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

import ResolveKit

/// Manages WatchConnectivity settings via implementing CoreDataSettingsService
final class WatchSessionSettingsManager: UserDefaultsSettingsManager, WatchSessionSettingsService {

	#if os(watchOS)

	private let lastSharedEventComplicationCountKey = "\(WatchSessionSettingsService.self).lastSharedEventComplicationCount"

	/// Represents the last value written to the SharedEvent complication, so that unnecessary updates can be avoided
	public var lastSharedEventComplicationCount: Int {
		get { return userDefaults.integer(forKey: lastSharedEventComplicationCountKey) }
		set { userDefaults.set(newValue, forKey: lastSharedEventComplicationCountKey) }
	}

	#endif

	#if os(iOS)

	let notificationCenter: NotificationCenter

	required init(notificationCenter: NotificationCenter = .default, userDefaults: UserDefaults = .standard) {
		self.notificationCenter = notificationCenter
		super.init(userDefaults: userDefaults)
	}

	#endif

	private let messageCountKey = "\(WatchSessionSettingsService.self).messageCount"

	var messageCount: Int {
		get { return userDefaults.integer(forKey: messageCountKey) }
		set {
			userDefaults.set(newValue, forKey: messageCountKey)
			#if os(iOS)
			notificationCenter.post(name: .messageCountChanged, object: self)
			#endif
		}
	}
}
