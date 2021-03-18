//
//  UserActivityManager.swift
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

public final class UserActivityManager: CoreUserActivityManager<CustomActivityType> {

	override public func userActivity(for activityType: CustomActivityType) -> NSUserActivity {
		let result = super.userActivity(for: activityType)
		applyCommonProperties(for: activityType, to: result)
		#if os(iOS) // TODO: Find a nice way to optionally introduce this to various platforms without having to use #if
		// The implementations of this method belong in UserActivityManager-[platform].swift
		applyCustomProperties(for: activityType, to: result)
		#endif
		return result
	}

	override public init(with bundle: Bundle = .main) {
		super.init(with: bundle)
		assert(identifiers.count == CustomActivityType.allCases.count, "Misconfigured NSUserActivity entries in the app's Info Dictionary")
		for (identifier, activityType) in zip(identifiers, CustomActivityType.allCases) {
			assert(identifier.caseInsensitiveCompare("\(activityType)") == .orderedSame || identifier.hasSuffix(".\(activityType)"), "Mismatching NSUserActivity in the app's Info Dictionary: `\(identifier)` does not equal or end with `.\(activityType)`")
		}
	}

	func applyCommonProperties(for activityType: CustomActivityType, to activity: NSUserActivity) {
		activity.isEligibleForHandoff = true
		activity.title = activityType.activityTitle
		activity.userInfo = ["version" : "1.0"]
	}
}

extension CustomActivityType {

	var activityTitle: String {
		// TODO: Use localizable strings so that `self` can be a key
		return "Open \(self)"
	}

	var suggestedInvocationPhrase: String {
		// TODO: Use localizable strings so that `self` can be a key
		return "Open \(self)"
	}
}
