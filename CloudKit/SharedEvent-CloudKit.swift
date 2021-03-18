//
//  SharedEvent-CloudKit.swift
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

extension SharedEvent {
	
	public class func create<T>(with recordID: CKRecord.ID, using context: NSManagedObjectContext) -> T where T: SharedEvent {
		let retVal = try! context.create(T.self)
		let record = CKRecord(recordType: T.cloudRecordType, recordID: recordID)
		retVal.createICloudReference(for: .public, with: record)
		return retVal
	}
}

extension SharedEvent: PublicCloudKitEntity {
	
	public override func apply(cloudKitRecord: CKRecord, for databaseType: CloudKitDatabaseType) throws {
		switch databaseType {
		case .public:
			applyValue(from: cloudKitRecord, for: #keyPath(SharedEvent.createdLocallyAt), as: Date.self)
			applyValue(from: cloudKitRecord, for: #keyPath(SharedEvent.createdByDevice), as: String.self)
			applyValue(from: cloudKitRecord, for: #keyPath(SharedEvent.uniqueIdentifier), as: String.self)
		case .private:
			throw CloudKitError.unsupportedWorkflow("\(self) does not support \(databaseType)")
		}
	}
	
	public override func update(cloudKitRecord: CKRecord, for databaseType: CloudKitDatabaseType) throws {
		switch databaseType {
		case .public:
			applyValue(to: cloudKitRecord, for: #keyPath(SharedEvent.createdLocallyAt), as: Date.self)
			applyValue(to: cloudKitRecord, for: #keyPath(SharedEvent.createdByDevice), as: String.self)
			applyValue(to: cloudKitRecord, for: #keyPath(SharedEvent.uniqueIdentifier), as: String.self)
		case .private:
			throw CloudKitError.unsupportedWorkflow("\(self) does not support \(databaseType)")
		}
	}
	
	public override class func localRecord(_ localRecord: CKRecord, isEqualTo serverRecord: CKRecord, in databaseType: CloudKitDatabaseType) -> Bool {
		guard localRecord.fieldEquals(#keyPath(SharedEvent.createdLocallyAt), to: serverRecord, as: Date.self),
			localRecord.fieldEquals(#keyPath(SharedEvent.createdByDevice), to: serverRecord, as: String.self),
			localRecord.fieldEquals(#keyPath(SharedEvent.uniqueIdentifier), to: serverRecord, as: String.self) else {
			return false
		}
		return true
	}

	public override class func userFieldNames(for databaseType: CloudKitDatabaseType) -> [String] {
		switch databaseType {
		case .public:
			return [#keyPath(SharedEvent.createdLocallyAt), #keyPath(SharedEvent.createdByDevice), #keyPath(SharedEvent.uniqueIdentifier)]
		case .private:
			return []
		}
	}
}

extension CloudKitEntity where Self: SharedEvent {
	
	private static func userPredicate(for users: Set<User>?) -> NSPredicate? {
		guard let users = users else { return nil }
		// This predicate _must_ be used after other predicates that establish SharedEvents as the 'syncableEntity'
		return NSPredicate(format: "%K in %@", "\(#keyPath(ICloudSyncReference.syncableEntity)).\(#keyPath(SharedEvent.user))", users)
	}
	
	public static func fetchRequestForRecords(in databaseType: CloudKitDatabaseType, for users: Set<User>?, using context: NSManagedObjectContext) -> NSFetchRequest<ICloudSyncReference> {
		var predicates = [NSPredicate]()
		predicates.reserveCapacity(1)
		if let userPredicate = Self.userPredicate(for: users) {
			predicates.append(userPredicate)
		}
		let entityDescription = Self.entityDescription(in: context)
		return ICloudSyncReference.fetchRequest(in: databaseType, for: [entityDescription], andPredicates: predicates, using: context)
	}
	
	public static func fetchRequestForUnsyncedRecords(in databaseType: CloudKitDatabaseType, for users: Set<User>?, using context: NSManagedObjectContext) -> NSFetchRequest<ICloudSyncReference> {
		var predicates = [NSPredicate]()
		predicates.reserveCapacity(2)
		predicates.append(NSPredicate(format: "%K=NO", #keyPath(ICloudSyncReference.synchronized)))
		if let userPredicate = Self.userPredicate(for: users) {
			predicates.append(userPredicate)
		}
		let entityDescription = Self.entityDescription(in: context)
		return ICloudSyncReference.fetchRequest(in: databaseType, for: [entityDescription], andPredicates: predicates, using: context)
//		request.resultType = .dictionaryResultType
//		let entityObjectID = NSExpressionDescription()
//		entityObjectID.name = "entityObjectID"
//		entityObjectID.expression = NSExpression(forKeyPath: #keyPath(ICloudReference.cloudEntity))
//		entityObjectID.expressionResultType = .objectIDAttributeType
//		request.propertiesToFetch = [#keyPath(ICloudReference.iCloudRecordID), entityObjectID]
//		request.relationshipKeyPathsForPrefetching = [#keyPath(ICloudReference.cloudEntity)]
	}
}
