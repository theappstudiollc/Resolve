//
//  WatchSessionService.swift
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

extension Notification.Name {

	static let watchSessionContextUpdatedNotification = Notification.Name(rawValue: "\(WatchSessionService.self)ContextUpdatedNotification")
	static let watchSessionStateChangedNotification = Notification.Name(rawValue: "\(WatchSessionService.self)StateChangedNotification")
}

public protocol WatchSessionService {

	var applicationContext: [String : Any]? { get }

	var receivedApplicationContext: [String : Any]? { get }

	var state: WatchSessionState { get }

	#if os(watchOS)

	func fetchSharedEventCount(_ handler: @escaping (Result<Int, WatchSessionError>) -> Void)

	func sendMessageCount(_ count: Int, handler: @escaping (Result<Bool, WatchSessionError>) -> Void)

	#endif

	func updateApplicationContext(_ applicationContext: [String : Any]) throws
}
