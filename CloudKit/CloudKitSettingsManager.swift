//
//  CloudKitSettingsManager.swift
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

/// Manages CloudKit settings via implementing CloudKitSettingsService
final class CloudKitSettingsManager: UserDefaultsSettingsManager, CloudKitSettingsService {

	private let fetchDatabaseChangeTokenKey = "fetchDatabaseChangeToken"
	private let fetchedUserUriRepresentationsKey = "fetchedUserUriRepresentations"
	private let lastFullSyncKey = "cloudKitLastFullSyncDate"
	private let subscribedUsersKey = "subscribedUsers"

	// MARK: - CloudKitSettingsService properties

	public var fetchDatabaseChangeToken: CKServerChangeToken? {
		get { return try? userDefaults.secureDecode(CKServerChangeToken.self, forKey: fetchDatabaseChangeTokenKey) }
		set {
			if let value = newValue {
				try! userDefaults.secureEncode(value, forKey: fetchDatabaseChangeTokenKey)
			} else {
				userDefaults.removeObject(forKey: fetchDatabaseChangeTokenKey)
			}
		}
	}

	public var fetchedUserUriRepresentations: Set<URL>! {
		get {
			guard let result = try? userDefaults.secureDecode(NSSet.self, including: [NSURL.self], forKey: fetchedUserUriRepresentationsKey) else {
				return Set<URL>()
			}
			return result as? Set<URL>
		}
		set {
			if let value = newValue {
				try! userDefaults.secureEncode(value as NSSet, forKey: fetchedUserUriRepresentationsKey)
			} else {
				userDefaults.removeObject(forKey: fetchedUserUriRepresentationsKey)
			}
		}
	}

	public var lastFullSync: Date? {
		get { return try? userDefaults.secureDecode(NSDate.self, forKey: lastFullSyncKey) as Date? }
		set {
			if let value = newValue {
				try! userDefaults.secureEncode(value as NSDate, forKey: lastFullSyncKey)
			} else {
				userDefaults.removeObject(forKey: lastFullSyncKey)
			}
		}
	}

	public var subscribedUsers: Set<CKRecord.ID>! {
		get {
			guard let result = try? userDefaults.secureDecode(NSSet.self, including: [CKRecord.ID.self], forKey: subscribedUsersKey) else {
				return Set<CKRecord.ID>()
			}
			return result as? Set<CKRecord.ID>
		}
		set {
			if let value = newValue {
				try! userDefaults.secureEncode(value as NSSet, forKey: subscribedUsersKey)
			} else {
				userDefaults.removeObject(forKey: subscribedUsersKey)
			}
		}
	}
}
