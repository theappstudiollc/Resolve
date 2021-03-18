//
//  UserActivityService.swift
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
#if canImport(CoreSpotlight)
import CoreSpotlight
#endif

#if os(iOS)

/// The User Activities supported by this app (restorable and intents)
public enum CustomActivityType: Int {
	case alternateIcons
	case beacon
	case camera
	case cloudKit
	case conversation
	case coreData
	case homeKit
	case map
	case photos
	case watchConnectivity
	// SiriKit Intents start here
	case createSharedEventIntent
}

#elseif os(macOS)

/// The User Activities supported by this app (restorable and intents)
public enum CustomActivityType: Int {
	case camera
	case conversation
	case coreData
	case iBeacon
	case map
	case photos
}

#elseif os(tvOS)

/// The User Activities supported by this app (restorable and intents)
public enum CustomActivityType: Int {
	case conversation
	case coreData
	case iBeacon
	case homeKit
	case photos
}

#elseif os(watchOS)

/// The User Activities supported by this app (restorable and intents)
public enum CustomActivityType: Int {
	case coreData
	case watchConnectivity
	// SiriKit Intents start here
	case createSharedEventIntent
}

#endif

extension CustomActivityType: CaseIterable { }

public enum UserActivityType {
	case appSpecific(activityType: CustomActivityType)
	case browsingWeb
	case queryContinuation
	case searchableItem
	case unknown
}

public struct UserActivityService: CoreUserActivityService {

	public typealias ActivityType = CustomActivityType

	public func activityType(with identifier: String) -> ActivityType? {
		return activityTypeClosure(identifier)
	}

	public func userActivity(for activityType: ActivityType) -> NSUserActivity {
		return userActivityClosure(activityType)
	}

	public func userActivityType(with identifier: String) -> UserActivityType {
		switch identifier {
		case NSUserActivityTypeBrowsingWeb:
			return .browsingWeb
		default:
			#if !os(tvOS) && !os(watchOS)
				if identifier == CSSearchableItemActionType {
					return .searchableItem
				}
				if #available(iOS 10.0, *), identifier == CSQueryContinuationActionType {
					return .queryContinuation
				}
			#endif
			if let result = activityType(with: identifier) {
				return .appSpecific(activityType: result)
			}
		}
		return .unknown
	}

	private let activityTypeClosure: (String) -> ActivityType?
	private let userActivityClosure: (ActivityType) -> NSUserActivity

	internal init<ConcreteUserActivityService>(implementation: ConcreteUserActivityService) where ConcreteUserActivityService: CoreUserActivityService, ConcreteUserActivityService.ActivityType == ActivityType {
		activityTypeClosure = implementation.activityType
		userActivityClosure = implementation.userActivity
	}
}
