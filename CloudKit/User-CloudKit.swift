//
//  User-CloudKit.swift
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
import CoreData

extension User {
	
	public class func create<T>(with recordID: CKRecord.ID, using context: NSManagedObjectContext) -> T where T: User {
		let record = CKRecord(recordType: T.cloudRecordType, recordID: recordID)
		return create(with: record, using: context)
	}
	
	public class func create<T>(with record: CKRecord, using context: NSManagedObjectContext) -> T where T: User {
		let retVal = try! context.create(T.self)
		retVal.createICloudReference(for: .public, with: record)
		return retVal
	}
}

extension User: PublicCloudKitEntity, PrivateCloudKitEntity {

	public var cloudRecordID: CKRecord.ID? {
		return iCloudReference(for: .public)?.cloudRecordID ?? iCloudReference(for: .private)?.cloudRecordID
	}
	
	public override class var cloudRecordType: String {
		return CKRecord.SystemType.userRecord
	}

	public override func apply(cloudKitRecord: CKRecord, for databaseType: CloudKitDatabaseType) throws {
		switch databaseType {
		case .public:
			applyValue(from: cloudKitRecord, for: #keyPath(User.userAlias), as: String.self)
		case .private:
			assert(cloudKitRecord.creatorIsCurrentUser)
			applyValue(from: cloudKitRecord, for: #keyPath(User.userFirstName), as: String.self)
			applyValue(from: cloudKitRecord, for: #keyPath(User.userLastName), as: String.self)
			// If we see CKReferences for friends, add the relationship here (but we need a context)
			guard let context = managedObjectContext else {
				throw CloudKitError.internalInconsistency("Cannot apply CKRecord to \(self) without a managedObjectContext")
			}
			guard let friendReferences = cloudKitRecord[#keyPath(User.friends)] as? [CKRecord.Reference] else {
				return
			}
			let friendSet = try Set(friendReferences.map { friend -> User in
				// The existing record may be in private -- we must ensure there is a public iCloudReference
				let friendRecord = CKRecord(recordType: User.cloudRecordType, recordID: friend.recordID)
				if let existingRecord = try User.instance(for: friend.recordID, in: .private, using: context) {
					if existingRecord.iCloudReference(for: .public) == nil {
						existingRecord.createICloudReference(for: .public, with: friendRecord)
					}
					return existingRecord
				} else if let existingRecord = try User.instance(for: friend.recordID, in: .public, using: context) {
					return existingRecord
				}
				let newRecord = try context.create(User.self)
				newRecord.createICloudReference(for: .public, with: friendRecord)
				return newRecord
			})
			if friends == nil || friendSet != friends as! Set<User> {
				self.friends = friendSet as NSSet
			}
		}
	}
	
	public override func update(cloudKitRecord: CKRecord, for databaseType: CloudKitDatabaseType) throws {
		switch databaseType {
		case .public:
			applyValue(to: cloudKitRecord, for: #keyPath(User.userAlias), as: String.self)
		case .private:
			// TODO: Consider a "Friends" CKRecord that we link to, which can contain first name and last name, etc.
			// This will make it possible to create new records in the private database that represents user, without being a "user" record
			applyValue(to: cloudKitRecord, for: #keyPath(User.userFirstName), as: String.self)
			applyValue(to: cloudKitRecord, for: #keyPath(User.userLastName), as: String.self)
			guard let friends = friends as? Set<User> else { return }
			let friendReferences = friends.compactMap { user -> CKRecord.Reference? in
				guard let friendRecordID = user.cloudRecordID else { return nil }
				return CKRecord.Reference(recordID: friendRecordID, action: .none)
			}
			cloudKitRecord[#keyPath(User.friends)] = friendReferences.count > 0 ? friendReferences : nil
		}
	}
	
	public override class func localRecord(_ localRecord: CKRecord, isEqualTo serverRecord: CKRecord, in databaseType: CloudKitDatabaseType) -> Bool {
		guard localRecord.recordID.indexableRepresentation == serverRecord.recordID.indexableRepresentation else {
			return false
		}
		switch databaseType {
		case .private:
			guard localRecord.fieldEquals(#keyPath(User.userFirstName), to: serverRecord, as: String.self),
				localRecord.fieldEquals(#keyPath(User.userLastName), to: serverRecord, as: String.self),
				localRecord.fieldEquals(#keyPath(User.friends), to: serverRecord, as: [CKRecord.Reference].self) else {
					// TODO: Convert friends to a Set<CKRecord.Reference> so that we can have better comparisons
					return false
			}
		case .public:
			guard localRecord.fieldEquals(#keyPath(User.userAlias), to: serverRecord, as: String.self) else {
				return false
			}
		}
		return true
	}

	public override class func userFieldNames(for databaseType: CloudKitDatabaseType) -> [String] {
		switch databaseType {
		case .private: return [#keyPath(User.userFirstName), #keyPath(User.userLastName), #keyPath(User.friends)]
		case .public: return [#keyPath(User.userAlias)]
		}
	}

	public func hasFriend(_ user: User) -> Bool {
		guard let friendsAsUsers = friends as? Set<User> else {
			return false
		}
		return friendsAsUsers.contains(user)
	}
}
