//
//  DeleteRecordDataOperation.swift
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

internal final class DeleteRecordDataOperation: CloudKitDataOperation {
	
	// MARK: - Public properties
	
	public var iCloudDatabaseType: CloudKitDatabaseType

	public var recordsToDelete: Dictionary<CKRecord.ID, NSManagedObjectID>?
	
	public init(with workflowContext: CloudKitContext, dataService: CoreDataService, loggingService: CoreLoggingService, in databaseType: CloudKitDatabaseType) {
		iCloudDatabaseType = databaseType
		super.init(with: workflowContext, dataService: dataService, loggingService: loggingService)
	}
	
	override final public func main() {
		dataService.performAndWait { context in
			
			let transactionContext = context.beginTransaction()

			do {
				guard let recordsToDelete = recordsToDelete else {
					fatalError()
				}
				try recordsToDelete.forEach { record in
					guard let cloudEntity = try context.existingObject(with: record.value) as? SyncableEntity else {
						return
					}
					// We can only actually delete when _all_ syncReferences are gone
					if let syncReference = cloudEntity.iCloudReference(for: iCloudDatabaseType) {
						cloudEntity.removeFromSyncReferences(syncReference)
						context.delete(syncReference)
					} else { // This is unusual
						loggingService.log(.error, "%{public}@ cannot find sync reference for recordID %{public}@", nameForLogging, record.key.indexableRepresentation)
					}
					// We can only actually delete when _all_ syncReferences are gone
					if cloudEntity.notLinked {
						loggingService.log(.info, "%{public}@ deleting %{public}@ for %{public}@", nameForLogging, "\(type(of: cloudEntity))", record.key.indexableRepresentation)
						context.delete(cloudEntity)
					} else if cloudEntity.cloudSyncStatus.insert(.markedForDeletion).inserted {
						loggingService.log(.info, "%{public}@ marking recordID %{public}@ for deletion", nameForLogging, record.key.indexableRepresentation)
					}
				}
				try context.commitTransaction(transactionContext: transactionContext)
				finish(withContext: context)
			} catch {
				context.cancelTransaction(transactionContext: transactionContext)
				finish(withError: error)
			}
		}
	}
}
