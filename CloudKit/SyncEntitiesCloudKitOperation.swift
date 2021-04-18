//
//  SyncEntitiesCloudKitOperation.swift
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
import CoreResolve

internal class SyncEntitiesCloudKitOperation: CloudKitSyncOperation {

	// MARK: - Public properties

	/// Declares which user-defined keys should be fetched and added to the resulting `CKRecord`s for all RecordTypes in fetches and queries
	///
	/// If `nil`, declares the entire record should be downloaded. If set to an empty array, declares that no user fields should be downloaded.
	/// Defaults to `nil`.
	public var desiredKeys: [String]?
	
	// MARK: - CloudKitSyncOperation overrides

	open override func deleteRecord(with recordID: CKRecord.ID, using context: NSManagedObjectContext) {
		guard let cloudEntity = entityForRecordID(recordID, using: context) else {
			fatalError("Should have a record of this")
		}
		// First remove the sync reference for this iCloudDatabaseType
		if let syncReference = cloudEntity.iCloudReference(for: iCloudDatabaseType) {
			loggingService.log(.info, "%{public}@ deleting %{public}@ reference for %{public}@", nameForLogging, "\(iCloudDatabaseType)" , recordID.indexableRepresentation)
			cloudEntity.removeFromSyncReferences(syncReference)
			context.delete(syncReference)
		} else { // This is unusual
			loggingService.log(.error, "%{public}@ cannot find sync reference for recordID %{public}@", nameForLogging, recordID.recordName)
		}
		// We can only actually delete when _all_ syncReferences are gone
		if cloudEntity.notLinked {
			loggingService.log(.info, "%{public}@ deleting %{public}@ for %{public}@", nameForLogging, "\(type(of: cloudEntity))", recordID.indexableRepresentation)
			context.delete(cloudEntity)
		} else if cloudEntity.cloudSyncStatus.insert(.markedForDeletion).inserted {
			loggingService.log(.info, "%{public}@ marking recordID %{public}@ for deletion", nameForLogging, recordID.recordName)
		}
	}

	open override func fetchRecordsOperation(for recordsToFetch: [CKRecord.ID]) -> CKFetchRecordsOperation {
		let result = super.fetchRecordsOperation(for: recordsToFetch)
		result.desiredKeys = desiredKeys
		return result
	}

	open override func handleUnknownItem(_ error: Error, for recordID: CKRecord.ID, from modifyOperation: Bool, in context: NSManagedObjectContext) throws {
		// TODO: Does `modifyOperation` matter here?
		guard let cloudEntity = entityForRecordID(recordID, using: context) else {
			// We don't know it either
			loggingService.log(.debug, "%{public}@ doesn't know record %{public}@ either", nameForLogging, recordID.indexableRepresentation)
			return
		}
		// First remove the sync reference for this iCloudDatabaseType
		if let syncReference = cloudEntity.iCloudReference(for: iCloudDatabaseType) {
			loggingService.log(.info, "%{public}@ deleting %{public}@ reference for unknown %{public}@", nameForLogging, "\(iCloudDatabaseType)" , recordID.indexableRepresentation)
			cloudEntity.removeFromSyncReferences(syncReference)
			context.delete(syncReference)
		} else { // This is unusual (maybe not for unknown)
			loggingService.log(.error, "%{public}@ cannot find sync reference for recordID %{public}@", nameForLogging, recordID.recordName)
		}
		// We can only actually delete when _all_ syncReferences are gone and when we understand it to be marked for deletion
		if cloudEntity.notLinked, cloudEntity.cloudSyncStatus.contains(.markedForDeletion) {
			loggingService.log(.info, "%{public}@ deleting %{public}@ for unknown %{public}@", nameForLogging, "\(type(of: cloudEntity))", recordID.indexableRepresentation)
			context.delete(cloudEntity)
		}
	}

	open override func main() {
		assert(workflowContext.linkedUserObjectID != nil, "\(self) is expecting a linkedUserObjectID")
		super.main()
	}
	
	open override func mergeServerRecord(_ serverRecord: CKRecord, from modifyOperation: Bool, using context: NSManagedObjectContext) throws -> Bool {
		
		let recordID = serverRecord.recordID
		var entity: SyncableEntity!
		if let objectID = _recordIDsToObjectIDs[recordID], let existingEntity = try context.existingObject(with: objectID) as? SyncableEntity {
			entity = existingEntity
		} else if modifyOperation {
			// Do a lookup because this operation was not provided with sufficient info, which is slower, but at least we get something
			loggingService.log(.default, "--WARNING-- Slow lookup for recordID `%{public}@`", recordID)
			guard let existingEntity = try SyncableEntity.instance(for: recordID, in: iCloudDatabaseType, using: context, includesSubentities: true) else {
				throw CloudKitError.internalInconsistency("Could not find existing syncable entity by record id")
			}
			entity = existingEntity
		} else { // TODO: A query operation may return a record that exists, but was not included in recordIDsToObjectIDs (this should utilize the search for the modify operation)
			entity = try resolveMissingEntity(from: serverRecord, in: context)
		}
		guard let iCloudReference = entity.iCloudReference(for: iCloudDatabaseType) else {
			if modifyOperation {
				throw CloudKitError.internalInconsistency("Could not find iCloudReference in modify operation")
			}
			// This is a fetch, so create the iCloudReference
			let iCloudReference = entity.createICloudReference(for: iCloudDatabaseType, with: serverRecord)
			try entity.apply(cloudKitRecord: serverRecord, for: iCloudDatabaseType)
			iCloudReference.synchronized = true
			return false // A subsequent save is not necessary
		}
        if entity.cloudSyncStatus.contains(.markedForDeletion) {
			// We've received data from the server, but we are also planning on deleting it
            assert(modifyOperation, "We're expecting markedForDeletions to come from a modify")
            if iCloudReference.synchronized {
                // We don't expect this anymore
                iCloudReference.synchronized = false
			} else {
				// Fixing some bad data on my end for a fetch
				entity.cloudSyncStatus = .normal
			}
			return false // A subsequent save is not necessary
		}
		let localRecord = iCloudReference.cloudRecord
		let equal: Bool
		switch localRecord.recordType {
		case User.cloudRecordType:
			equal = User.localRecord(localRecord, isEqualTo: serverRecord, in: iCloudDatabaseType)
		case SharedEvent.cloudRecordType:
			equal = SharedEvent.localRecord(localRecord, isEqualTo: serverRecord, in: iCloudDatabaseType)
		default:
			throw CloudKitError.internalInconsistency("Unexpected server record type")
		}
		let outdated = CKRecord.serverRecord(serverRecord, isNewerThan: localRecord)
		if equal || outdated {
			if outdated {
				if !iCloudReference.synchronized {
					// Trigger refreshes with NSFetchedResultsController by simulating a change to a common value
					entity.willChangeValue(for: \.syncStatus)
					entity.didChangeValue(for: \.syncStatus)
				}
				try entity.apply(cloudKitRecord: serverRecord, for: iCloudDatabaseType)
				iCloudReference.cloudRecord = serverRecord
            }
			iCloudReference.synchronized = true
			return false // A subsequent save is not necessary
		}
		// The local record has the latest data, we need to push to server (this should never happen, actually)
		// TODO: Consider a way to re-use the work done by 'let localRecord = iCloudReference.cloudRecord'
		try entity.update(cloudKitRecord: serverRecord, for: iCloudDatabaseType)
		iCloudReference.cloudRecord = serverRecord
		return true // A subsequent save is necessary
	}
	
	open override func modifyOperation(with recordsToSave: [CKRecord], recordIDsToDelete: [CKRecord.ID]) -> CKModifyRecordsOperation {
		let operation = super.modifyOperation(with: recordsToSave, recordIDsToDelete: recordIDsToDelete)
		// TODO: Find out why it was determined this is ideal and comment here
		operation.savePolicy = .changedKeys
		return operation
	}

	open override func nextQueryOperation() -> CKQueryOperation? {
		guard let operation = super.nextQueryOperation() else { return nil }
		operation.desiredKeys = desiredKeys
		return operation
	}
	
	open override func sortResults(_ results: [CKRecord]) -> [CKRecord] {
		// User records always come first
		return results.sorted {
			$0.recordType == CKRecord.SystemType.userRecord && $1.recordType != CKRecord.SystemType.userRecord
		}
	}

	// MARK: - Private methods

	private func entityForRecordID(_ recordID: CKRecord.ID, using context: NSManagedObjectContext) -> SyncableEntity? {
		guard let objectID = _recordIDsToObjectIDs[recordID], let cloudEntity = try? context.existingObject(with: objectID) as? SyncableEntity else {
			return nil
		}
		return cloudEntity
	}

	private func resolveMissingEntity(from record: CKRecord, in context: NSManagedObjectContext) throws -> SyncableEntity {
		switch record.recordType {
		case User.cloudRecordType:
			if let existingUser = try User.instance(for: record.recordID, in: iCloudDatabaseType, using: context) {
				loggingService.log(.info, "User record %{public}@ already exists", record.recordID)
				return existingUser
			} else if record.creatorIsCurrentUser, let linkedUserObjectID = workflowContext.linkedUserObjectID, let currentUser = try context.existingObject(with: linkedUserObjectID) as? User {
				return currentUser
			} else if iCloudDatabaseType != .public, let existingUser = try User.instance(for: record.recordID, in: .public, using: context) {
				return existingUser // We might be syncing private, so let's check public for the User...
			} else {
				throw CloudKitError.internalInconsistency("\(self) cannot create missing User")
			}
		case SharedEvent.cloudRecordType:
			let sharedEventUser: User
			if let userRecordId = record.creatorUserRecordID, let existingUser = try User.instance(for: userRecordId, in: .public, using: context) {
				sharedEventUser = existingUser
			} else if record.creatorIsCurrentUser, let linkedUserObjectID = workflowContext.linkedUserObjectID, let currentUser = try context.existingObject(with: linkedUserObjectID) as? User {
				// if the creatorUserRecordID is the "default user"
				sharedEventUser = currentUser
			} else { // Else we can leave this record orphaned, if we support the synchronizingRelationships state
				throw CloudKitError.internalInconsistency("\(self) cannot find user to create a new SharedEvent")
			}
			loggingService.log(.info, "%{public}@ creating SharedEvent for missing %{public}@", nameForLogging, record.recordID.indexableRepresentation)
			let sharedEvent = try context.create(SharedEvent.self)
			sharedEvent.user = sharedEventUser
			return sharedEvent
		default:
			throw CloudKitError.internalInconsistency("\(self) cannot create missing syncable entity")
		}
	}
}
