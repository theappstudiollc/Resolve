//
//  SyncUserCloudKitOperations.swift
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

internal struct SyncUserCloudKitOperations {
    
	let cloudKitContext: CloudKitContext
	let unsyncedUsersPrivateOperation: CollectEntityInfoCloudKitDataOperation
	let unsyncedUsersPublicOperation: CollectEntityInfoCloudKitDataOperation
    let syncUsersPrivateOperation: SyncEntitiesCloudKitOperation
    let syncUsersPublicOperation: SyncEntitiesCloudKitOperation
    let updateUsersOperation: UpdateUserInfosCloudKitOperation
	
	init(with context: CloudKitContext, configuration: CloudKitManagerConfigurationProviding) {
		
		cloudKitContext = context
		
		// Create all operations
		unsyncedUsersPrivateOperation = CollectEntityInfoCloudKitDataOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService) { context in
			let entityDescriptions = [User.entityDescription(in: context)]
			return ICloudSyncReference.fetchRequest(in: .private, for: entityDescriptions, using: context)
		}
		syncUsersPrivateOperation = SyncEntitiesCloudKitOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService, in: .private)

		unsyncedUsersPublicOperation = CollectEntityInfoCloudKitDataOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService) { context in
			let entityDescriptions = [User.entityDescription(in: context)]
			let predicates = [NSPredicate(format: "%K=NO", #keyPath(ICloudSyncReference.synchronized))]
			return ICloudSyncReference.fetchRequest(in: .public, for: entityDescriptions, andPredicates: predicates, using: context)
		}
		syncUsersPublicOperation = SyncEntitiesCloudKitOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService, in: .public)

		updateUsersOperation = UpdateUserInfosCloudKitOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService, userService: configuration.userService)

		// Now link them
        linkOperations()
	}
    
    private func linkOperations() {
		updateUsersOperation.linkWorkflow(to: unsyncedUsersPrivateOperation)
		unsyncedUsersPrivateOperation.linkWorkflow(to: syncUsersPrivateOperation, performing: linkUnsyncedToSync)
		syncUsersPrivateOperation.linkWorkflow(to: unsyncedUsersPublicOperation)
		unsyncedUsersPublicOperation.linkWorkflow(to: syncUsersPublicOperation, performing: linkUnsyncedToSync)
    }
	
	private func linkUnsyncedToSync(_ unsynced: CollectEntityInfoCloudKitDataOperation, _ toSync: SyncEntitiesCloudKitOperation) {
		// TODO: If we leave without finishing (maybe there's an iCloud login hangup) we can get a nil here
		cloudKitContext.logger.log(.default, "    - %ld [recordIDs:ObjectIDs] and %ld [recordIDs:NSManagedObject]", unsynced.recordIDsToObjectIDs!.count, unsynced.recordIDsToRecords!.count)
		toSync.addRecordIDsToObjectIDs(from: unsynced.recordIDsToObjectIDs!)
		toSync.addRecordsToFetch(from: unsynced.recordIDsToFetch!)
		toSync.addRecordsToSave(from: unsynced.recordIDsToRecords!)
	}
}

extension SyncUserCloudKitOperations: CloudKitManagerOperationGroup {
    
    var firstOperation: CloudKitOperation {
		return updateUsersOperation
    }
    
    var lastOperation: CloudKitOperation {
		return syncUsersPublicOperation
		// This is used later to sync SharedEvents, which are by nature public operations
    }

    var progress: Progress {
		let retVal = Progress(totalUnitCount: 5)
		retVal.addChild(updateUsersOperation.progress, withPendingUnitCount: 1)
		retVal.addChild(unsyncedUsersPrivateOperation.progress, withPendingUnitCount: 1)
		retVal.addChild(unsyncedUsersPublicOperation.progress, withPendingUnitCount: 1)
		retVal.addChild(syncUsersPrivateOperation.progress, withPendingUnitCount: 1)
		retVal.addChild(syncUsersPublicOperation.progress, withPendingUnitCount: 1)
		return retVal
    }
	
	@available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *)
	func applyOperationGroup(_ operationGroup: CKOperationGroup) {
		syncUsersPrivateOperation.operationGroup = operationGroup
		syncUsersPublicOperation.operationGroup = operationGroup
	}
}
