//
//  NotificationService.swift
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

import Foundation
import CoreLocation
import CoreResolve

protocol NotificationService {

	typealias Provider = CoreNotificationProviding

	#if os(iOS) || os(macOS)

	func notify(withMessage message: String, _ completion: ((_ error: Error?) -> ())?)

	#endif

	#if os(iOS) || os(macOS) || os(tvOS)

	func registerUserNotifications()

	#endif

	#if os(iOS)
	
	func clearBeaconNotifications()
	
	func notifyBeaconEntry()

	func notifyBeaconExit()
	
	@available(iOS 10.0, *)
	func notifyVisit(_ visit: CLVisit)
	
	#endif

	@available(macOS 10.14, watchOS 6.0, *)
	func registerRemoteNotifications()
}
