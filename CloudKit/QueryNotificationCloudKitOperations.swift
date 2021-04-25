//
//  QueryNotificationCloudKitOperations.swift
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
import CoreResolve

internal struct QueryNotificationCloudKitOperations {
    
	let cloudKitContext: CloudKitContext
	let deleteSharedEventOperation: DeleteRecordDataOperation?
	let fetchSharedEventOperation: SyncEntitiesCloudKitOperation
	let lookupSharedEventOperation: CollectEntityInfoCloudKitDataOperation

	init?(with context: CloudKitContext, configuration: CloudKitManagerConfigurationProviding, queryNotification: CKQueryNotification) {
		guard let recordID = queryNotification.recordID else {
			context.logger.log(.error, "CKQueryNotification did not provide a recordID")
			return nil // This is a pretty big surprise
		}
		cloudKitContext = context
		
		switch queryNotification.subscriptionID {
		case .some(CloudKitContext.sharedEventsSubscriptionID):

			fetchSharedEventOperation = SyncEntitiesCloudKitOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService, in: queryNotification.cloudDatabase)
			lookupSharedEventOperation = Self.configureLookupOperation(for: recordID, with: context, configuration: configuration, in: queryNotification.cloudDatabase)

			switch queryNotification.queryNotificationReason {
			case .recordCreated: // We don't/shouldn't have the record in our system (should we look up in CoreData anyway?)
				/* Why submit a query when we know the recordID?
				let predicate = NSPredicate(format: "%K=%@", #keyPath(CKRecord.recordID), recordID)
				let query = SharedEvent.cloudQuery(with: predicate)
				query.sortDescriptors = [NSSortDescriptor(key: #keyPath(SharedEvent.createdLocallyAt), ascending: true)]
				fetchSharedEventOperation.addQueries(from: [query])
				*/
				// It is still possible the device that created the record may receive a notification about the CKRecord creation
				// TODO: If lookup determines that we already have the record, do we _really_ need to fetch? What if lookup determines we've since updated or even deleted?
				lookupSharedEventOperation.linkWorkflow(to: fetchSharedEventOperation, cancelOnError: true) { lookup, fetch in
					context.logger.log(.default, "    - %ld [recordIDs:ObjectIDs] and %ld [recordIDs:NSManagedObject]", lookup.recordIDsToObjectIDs!.count, lookup.recordIDsToRecords!.count)
					fetch.addRecordIDsToObjectIDs(from: lookup.recordIDsToObjectIDs!)
					fetch.addRecordsToFetch(from: Set(arrayLiteral: recordID))
				}
				deleteSharedEventOperation = nil
			case .recordUpdated: // We should look up the record and sync as normal
				lookupSharedEventOperation.linkWorkflow(to: fetchSharedEventOperation, cancelOnError: true) { lookup, fetch in
					context.logger.log(.default, "    - %ld [recordIDs:ObjectIDs] and %ld [recordIDs:NSManagedObject]", lookup.recordIDsToObjectIDs!.count, lookup.recordIDsToRecords!.count)
					fetch.addRecordIDsToObjectIDs(from: lookup.recordIDsToObjectIDs!)
					fetch.addRecordsToDelete(from: lookup.recordIDsToDelete!)
					fetch.addRecordsToFetch(from: Set(arrayLiteral: recordID))
					fetch.addRecordsToSave(from: lookup.recordIDsToRecords!.filter { $0.value.recordChangeTag != nil })
				}
				deleteSharedEventOperation = nil
			case .recordDeleted: // We should mark as deleted and remove the cloud sync reference
				// The recordID in this notification may have a zone that breaks the hashing for recordIDsToObjectIDs
				deleteSharedEventOperation = DeleteRecordDataOperation(with: context, dataService: configuration.dataService, loggingService: context.logger, in: queryNotification.cloudDatabase)
				lookupSharedEventOperation.linkWorkflow(to: deleteSharedEventOperation!, cancelOnError: true) { lookup, fetch in
					context.logger.log(.default, "    - %ld [recordIDs:ObjectIDs] and %ld [recordIDs:NSManagedObject]", lookup.recordIDsToObjectIDs!.count, lookup.recordIDsToRecords!.count)
					fetch.recordsToDelete = lookup.recordIDsToObjectIDs
				}
			@unknown default:
				return nil
			}
		default:
			return nil
		}
	}
	
	private static func configureLookupOperation(for recordID: CKRecord.ID, with context: CloudKitContext, configuration: CloudKitManagerConfigurationProviding, in databaseType: CloudKitDatabaseType) -> CollectEntityInfoCloudKitDataOperation {
		return CollectEntityInfoCloudKitDataOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService) { context in
			let entityDescriptions = [SharedEvent.entityDescription(in: context)]
			let predicates = [NSPredicate(format: "%K=%@", #keyPath(ICloudSyncReference.iCloudRecordID), recordID.indexableRepresentation)]
			return ICloudSyncReference.fetchRequest(in: databaseType, for: entityDescriptions, andPredicates: predicates, using: context)
		}
	}
}

extension QueryNotificationCloudKitOperations: CloudKitManagerOperationGroup {
    
    var firstOperation: CloudKitOperation {
		return lookupSharedEventOperation
    }
    
    var lastOperation: CloudKitOperation {
		return deleteSharedEventOperation ?? fetchSharedEventOperation
    }

    var progress: Progress {
		let retVal = Progress(totalUnitCount: 2)
		retVal.addChild(lookupSharedEventOperation.progress, withPendingUnitCount: 1)
        retVal.addChild(fetchSharedEventOperation.progress, withPendingUnitCount: 1)
        return retVal
    }
	
	@available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *)
	func applyOperationGroup(_ operationGroup: CKOperationGroup) {
		fetchSharedEventOperation.operationGroup = operationGroup
	}
}

extension CKQueryNotification {
	
	internal var cloudDatabase: CloudKitDatabaseType {
		guard #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) else {
			guard let isPublicDatabase = value(forKey: "isPublicDatabase") as? Bool else {
				return .private
			}
			return isPublicDatabase ? .public : .private
		}
		switch databaseScope {
		case .private: return .private
		case .public: return .public
		default: fatalError("Not currently supported by CloudKitManager")
		}
	}
}
