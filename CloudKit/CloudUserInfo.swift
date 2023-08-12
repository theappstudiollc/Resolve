//
//  CloudUserInfo.swift
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

import CloudKit
import CoreResolve_ObjC // iOS 9 support

internal struct CloudUserInfo: Hashable {
	let firstName: String
	let lastName: String
	let recordID: CKRecord.ID
}

internal extension CloudUserInfo {

	@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
	init?(userIdentity: CKUserIdentity) {
		guard let recordID = userIdentity.userRecordID, let nameComponents = userIdentity.nameComponents else { return nil }
		guard let firstName = nameComponents.givenName, let lastName = nameComponents.familyName else { return nil }
		self.firstName = firstName
		self.lastName = lastName
		self.recordID = recordID
	}

	#if (os(iOS) || os(macOS)) && !targetEnvironment(macCatalyst)

	@available(iOS, deprecated: 10.0)
	@available(macOS, deprecated: 10.12)
	init?(discoveredUserInfo: CKDiscoveredUserInfo) {
		guard let recordID = discoveredUserInfo.userRecordID else { return nil }
		if #available(iOS 9.0, *) {
			guard let displayContact = discoveredUserInfo.displayContact else { return nil }
			self.firstName = displayContact.givenName
			self.lastName = displayContact.familyName
		} else {
			guard let firstName = discoveredUserInfo.firstName, let lastName = discoveredUserInfo.lastName else { return nil }
			self.firstName = firstName
			self.lastName = lastName
		}
		self.recordID = recordID
	}

	#endif
}
