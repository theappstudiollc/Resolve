//
//  ICloudSyncReference-CloudKit.swift
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

internal extension ICloudSyncReference {
	
	class func fetchRequest(in databaseType: CloudKitDatabaseType, for entities: [NSEntityDescription], andPredicates predicates: [NSPredicate]? = nil, using context: NSManagedObjectContext) -> NSFetchRequest<ICloudSyncReference> {
		
		assert({
			let requiredEntities = SyncableEntity.entityDescription(in: context)
			return entities.allSatisfy { $0.isKindOf(entity: requiredEntities) }
		}(), "Only SyncableEntity descriptions are allowed")

		let request: NSFetchRequest<ICloudSyncReference> = ICloudSyncReference.fetchRequest()
		var andPredicates = [NSPredicate]()
		andPredicates.append(NSPredicate(format: "%K=%@", #keyPath(ICloudSyncReference.iCloudDatabaseType), "\(databaseType)"))
		andPredicates.append(NSPredicate(format: "%K IN %@", #keyPath(ICloudSyncReference.syncableEntity.entity), entities))
		// Always put these _after_ the entity predicate above to ensure that the predicates below are operating on the correct entities
		if let additionalPredicates = predicates {
			andPredicates.append(contentsOf: additionalPredicates)
		}
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
		request.includesSubentities = false
		return request
	}
}

extension ICloudSyncReference {

	var cloudRecordID: CKRecord.ID {
		get {
			guard let recordData = iCloudSystemFieldsData, let retVal = CKRecord(with: recordData) else {
				fatalError("\(ICloudSyncReference.self) always expects to be able to generate a \(CKRecord.self)")
			}
			return retVal.recordID
		}
	}

	// TODO: Consider changing the return type from CKRecord to [CKRecord], so that multiple CloudRecord types can represent one entity
	var cloudRecord: CKRecord {
		get {
			guard let recordData = iCloudSystemFieldsData, let retVal = CKRecord(with: recordData) else {
				fatalError("\(ICloudSyncReference.self) always expects to be able to generate a \(CKRecord.self)")
			}
			checkCompatibility(with: retVal) // This shouldn't be necessary if the set is always correct
			
            let databaseType = CloudKitDatabaseType(iCloudDatabaseType!)!
			try! syncableEntity!.update(cloudKitRecord: retVal, for: databaseType)
			return retVal
		}
		set {
			checkCompatibility(with: newValue)
			let encodedSystemFields = newValue.encodedSystemFields
			if iCloudSystemFieldsData != encodedSystemFields {
				iCloudSystemFieldsData = encodedSystemFields
			}
			let recordID = newValue.recordID.indexableRepresentation
			if iCloudRecordID != recordID {
				iCloudRecordID = recordID
			}
		}
	}
	
	private func checkCompatibility(with record: CKRecord) {
		guard let syncableEntity = syncableEntity else { fatalError("Checking compatibility with nil `syncableEntity`: \(self)")}
		let entityType = type(of: syncableEntity)
		assert(entityType.cloudRecordType == record.recordType,
			   "Mismatching CKRecord types: \(entityType.cloudRecordType) vs \(record.recordType)")
	}
}
