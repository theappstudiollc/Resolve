//
//  SyncEntitiesCloudKitOperations.swift
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

internal struct SyncEntitiesCloudKitOperations {
    
	let cloudKitContext: CloudKitContext
	let unsyncedRecordsPrivateOperation: CollectEntityInfoCloudKitDataOperation
	let unsyncedRecordsPublicOperation: CollectEntityInfoCloudKitDataOperation
	let usersWithFriendsOperation: UsersWithFriendsCloudKitDataOperation
	let prepareOperation: PrepareFetchSharedEventsCloudKitOperation?
    let syncRecordsPrivateOperation: SyncEntitiesCloudKitOperation
    let syncRecordsPublicOperation: SyncEntitiesCloudKitOperation

	init(with context: CloudKitContext, configuration: CloudKitManagerConfigurationProviding, syncOptions: CloudKitServiceSyncOptions) {
		
		cloudKitContext = context

		// Create all operations
		let syncPrivate = Self.collectAndSyncOperations(in: .private, with: context, configuration: configuration, syncOptions: syncOptions, for: [User.self])
		unsyncedRecordsPrivateOperation = syncPrivate.collectOperation
		syncRecordsPrivateOperation = syncPrivate.syncOperation

		usersWithFriendsOperation = UsersWithFriendsCloudKitDataOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService)
		if syncOptions.contains(.fetchAll) {
			prepareOperation = PrepareFetchSharedEventsCloudKitOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService)
			if syncOptions.contains(.fullSync) {
				prepareOperation!.fullRefresh = true
			}
		} else {
			prepareOperation = nil
		}

		let syncPublic = Self.collectAndSyncOperations(in: .public, with: context, configuration: configuration, syncOptions: syncOptions, for: [User.self, SharedEvent.self])
		unsyncedRecordsPublicOperation = syncPublic.collectOperation
		syncRecordsPublicOperation = syncPublic.syncOperation

		// Now link them
		linkOperations(with: configuration.settingsService)
	}

	private static func collectAndSyncOperations(in databaseType: CloudKitDatabaseType, with context: CloudKitContext, configuration: CloudKitManagerConfigurationProviding, syncOptions: CloudKitServiceSyncOptions, for syncableEntities: [(NSManagedObject & CloudKitEntity).Type]) -> (collectOperation: CollectEntityInfoCloudKitDataOperation, syncOperation: SyncEntitiesCloudKitOperation) {

		let forceAll = syncOptions.contains(.refreshAll)

		let collect = CollectEntityInfoCloudKitDataOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService) { context in
			let entityDescriptions = syncableEntities.compactMap { $0.entityDescription(in: context) }
			if forceAll {
				return ICloudSyncReference.fetchRequest(in: databaseType, for: entityDescriptions, using: context)
			}
			let predicates = [NSPredicate(format: "%K=NO", #keyPath(ICloudSyncReference.synchronized))]
			return ICloudSyncReference.fetchRequest(in: databaseType, for: entityDescriptions, andPredicates: predicates, using: context)
		}

		let sync = SyncEntitiesCloudKitOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService, in: databaseType)
		let desiredKeys = syncableEntities.flatMap { $0.userFieldNames(for: databaseType) }
		sync.desiredKeys = desiredKeys.isEmpty ? nil : desiredKeys

		return (collect, sync)
	}

    private func linkOperations(with settingsService: CloudKitSettingsService) {
		
        unsyncedRecordsPrivateOperation.linkWorkflow(to: syncRecordsPrivateOperation, performing: linkUnsyncedToSync)
		// UserAndFriends should begin when Private sync is complete
		syncRecordsPrivateOperation.linkWorkflow(to: usersWithFriendsOperation)
		usersWithFriendsOperation.linkWorkflow(to: unsyncedRecordsPublicOperation)
		if let prepareOperation = prepareOperation {
			prepareOperation.fetchedUserUriRepresentations = settingsService.fetchedUserUriRepresentations
			prepareOperation.addFinishClosure { prepare in
				// TODO: This should only be set when syncRecordsPublicOperation succeeds
				settingsService.fetchedUserUriRepresentations = prepare.fetchedUserUriRepresentations
			}
			usersWithFriendsOperation.linkWorkflow(to: prepareOperation, cancelOnError: true) { userAndFriends, prepare in
				prepare.userObjectIDs = userAndFriends.userObjectIDs
			}
			prepareOperation.linkWorkflow(to: syncRecordsPublicOperation) { prepare, toSync in
				if let query = prepare.query {
					toSync.addQueries(from: [query])
				}
				toSync.addRecordIDsToObjectIDs(from: prepare.recordIDsToObjectIDs!)
			}
		}
		unsyncedRecordsPublicOperation.linkWorkflow(to: syncRecordsPublicOperation, performing: linkUnsyncedToSync)
    }
	
	private func linkUnsyncedToSync(_ unsynced: CollectEntityInfoCloudKitDataOperation, _ toSync: SyncEntitiesCloudKitOperation) {
		cloudKitContext.logger.log(.default, "    - %ld [recordIDs:ObjectIDs] and %ld [recordIDs:NSManagedObject]", unsynced.recordIDsToObjectIDs!.count, unsynced.recordIDsToRecords!.count)
		toSync.addRecordIDsToObjectIDs(from: unsynced.recordIDsToObjectIDs!)
		toSync.addRecordsToDelete(from: unsynced.recordIDsToDelete!)
		toSync.addRecordsToFetch(from: unsynced.recordIDsToFetch!)
		toSync.addRecordsToSave(from: unsynced.recordIDsToRecords!)
	}
}

extension SyncEntitiesCloudKitOperations: CloudKitManagerOperationGroup {
    
    var firstOperation: CloudKitOperation {
		return unsyncedRecordsPrivateOperation
    }
    
    var lastOperation: CloudKitOperation {
		return syncRecordsPublicOperation
    }
	
    var progress: Progress {
		let retVal: Progress
		if let prepareOperationProgress = prepareOperation?.progress {
			retVal = Progress(totalUnitCount: 6)
			retVal.addChild(prepareOperationProgress, withPendingUnitCount: 1)
		} else {
			retVal = Progress(totalUnitCount: 5)
		}
        retVal.addChild(unsyncedRecordsPrivateOperation.progress, withPendingUnitCount: 1)
        retVal.addChild(unsyncedRecordsPublicOperation.progress, withPendingUnitCount: 1)
        retVal.addChild(usersWithFriendsOperation.progress, withPendingUnitCount: 1)
        retVal.addChild(syncRecordsPrivateOperation.progress, withPendingUnitCount: 1)
        retVal.addChild(syncRecordsPublicOperation.progress, withPendingUnitCount: 1)
        return retVal
    }
	
	@available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *)
	func applyOperationGroup(_ operationGroup: CKOperationGroup) {
		syncRecordsPrivateOperation.operationGroup = operationGroup
		syncRecordsPublicOperation.operationGroup = operationGroup
	}
}
