//
//  CloudKitModel.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2019 The App Studio LLC.
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

public struct CloudSyncStatus: OptionSet {
	
	public let rawValue: Int16
	
	public init(rawValue: Int16) {
		self.rawValue = rawValue
	}
	
	public static let normal: CloudSyncStatus = []
	/// Informs the UI to either hide or otherwise not interact with this object because it is being deleted
	public static let markedForDeletion = CloudSyncStatus(rawValue: 1 << 0)
	/// Informs the UI to either hide or otherwise not show this object because some necessary relationships are not yet synchronized
	public static let synchronizingRelationships = CloudSyncStatus(rawValue: 1 << 1)
}

public protocol CloudSynchronizing {
	
    var cloudSyncStatus: CloudSyncStatus { get set } // Figure out how best to co-exist with the NSManagedObject syncStatus
}

@objc public enum CloudKitDatabaseType: Int {
	case `public`
	case `private`
	// TODO: Add shared and update affected switch statements
}

public protocol CloudKitEntity: CloudSynchronizing {
	
	static var cloudRecordType: String { get }
	
	func apply(cloudKitRecord: CKRecord, for databaseType: CloudKitDatabaseType) throws

	func update(cloudKitRecord: CKRecord, for databaseType: CloudKitDatabaseType) throws

	static func localRecord(_ localRecord: CKRecord, isEqualTo serverRecord: CKRecord, in databaseType: CloudKitDatabaseType) -> Bool

	static func userFieldNames(for databaseType: CloudKitDatabaseType) -> [String]
}

public protocol PublicCloudKitEntity: CloudKitEntity {
	
	var publicCloudRecord: CKRecord? { get }
}

public protocol PrivateCloudKitEntity: CloudKitEntity {
	
	var privateCloudRecord: CKRecord? { get }
}

extension CloudKitDatabaseType: LosslessStringConvertible {
	public init?(_ description: String) {
		switch description {
		case "public":
			self.init(rawValue: 0)
		case "private":
			self.init(rawValue: 1)
		default:
			return nil
		}
	}
	
	public var description: String {
		switch self {
		case .public: return "public"
		case .private: return "private"
		}
	}
}
