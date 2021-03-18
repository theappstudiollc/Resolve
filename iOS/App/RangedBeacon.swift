//
//  RangedBeacon.swift
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

import CoreLocation
import ResolveKit

internal struct RangedBeacon: CoreBeaconIdentity, Equatable, Hashable {
	
	let uuid: UUID
	let major: CLBeaconMajorValue
	let minor: CLBeaconMajorValue

	let accuracy: CLLocationAccuracy
	let proximity: CLProximity

	func hash(into hasher: inout Hasher) {
		hasher.combine(uuid)
		hasher.combine(major)
		hasher.combine(minor)
	}

	static func == (lhs: RangedBeacon, rhs: RangedBeacon) -> Bool {
		return lhs.uuid == rhs.uuid && lhs.major == rhs.major && lhs.minor == rhs.minor
	}
}

internal extension RangedBeacon {

	init(_ beacon: CLBeacon) {
		guard #available(iOS 13.0, *) else {
			self.init(uuid: beacon.proximityUUID, major: beacon.major.uint16Value, minor: beacon.minor.uint16Value, accuracy: beacon.accuracy, proximity: beacon.proximity)
			return
		}
		self.init(uuid: beacon.uuid, major: beacon.major.uint16Value, minor: beacon.minor.uint16Value, accuracy: beacon.accuracy, proximity: beacon.proximity)
	}
}
