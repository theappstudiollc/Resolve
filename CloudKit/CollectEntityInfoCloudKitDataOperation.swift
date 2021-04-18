//
//  CollectEntityInfoCloudKitDataOperation.swift
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

internal final class CollectEntityInfoCloudKitDataOperation: CloudKitDataOperation {
	
	public typealias EntityFetchRequestGenerator = (_ context: NSManagedObjectContext) throws -> NSFetchRequest<ICloudSyncReference>
	
	public private(set) var recordIDsToDelete: [CKRecord.ID : NSManagedObjectID]?
	public private(set) var recordIDsToFetch: Set<CKRecord.ID>?
	public private(set) var recordIDsToObjectIDs: [CKRecord.ID : NSManagedObjectID]?
	public private(set) var recordIDsToRecords: [CKRecord.ID : CKRecord]?
	
	private let fetchEntityRequest: EntityFetchRequestGenerator
	
	public init(with workflowContext: WorkflowContext, dataService: CoreDataService, loggingService: CoreLoggingService, fetchEntityRequest: @escaping EntityFetchRequestGenerator) {
		self.fetchEntityRequest = fetchEntityRequest
		super.init(with: workflowContext, dataService: dataService, loggingService: loggingService)
		name = "\(type(of: self))"
	}
	
	public override func main() {
		dataService.performAndWait { context in
			do {
				let request = try self.fetchEntityRequest(context)
				let cloudReferences = try context.fetch(request)
				var recordIDsToDelete = [CKRecord.ID : NSManagedObjectID](minimumCapacity: cloudReferences.count)
				var recordIDsToFetch = Set<CKRecord.ID>(minimumCapacity: cloudReferences.count)
				var recordIDsToObjectIDs = [CKRecord.ID : NSManagedObjectID](minimumCapacity: cloudReferences.count)
				var recordIDsToRecords = [CKRecord.ID : CKRecord](minimumCapacity: cloudReferences.count)
				for cloudReference in cloudReferences {
					guard let syncableEntity = cloudReference.syncableEntity else {
						continue
					}
					let cloudRecord = cloudReference.cloudRecord
					recordIDsToObjectIDs[cloudRecord.recordID] = syncableEntity.objectID
					if cloudRecord.recordType == CKRecord.SystemType.userRecord {
						// NOTE: CloudKit does not accept deleting User Records -- consider what should happen if we want to mark for deletion for other reasons
						recordIDsToFetch.insert(cloudRecord.recordID)
						if cloudRecord.creatorIsCurrentUser {
							recordIDsToRecords[cloudRecord.recordID] = cloudRecord
						} else { // We cannot create user records on the private side (maybe we can create a proxy record type)
							workflowContext.logger.log(.info, "Skipping sync of CloudKitUser(%d): %{public}@ - %{private}@", cloudReference.synchronized, cloudRecord.creatorUserRecordID?.recordName ?? "<no creator record id>", "\(cloudRecord)")
						}
					} else if syncableEntity.cloudSyncStatus.contains(.markedForDeletion) {
						recordIDsToDelete[cloudRecord.recordID] = syncableEntity.objectID
					} else { // This is not a user record and it is not marked for deletion -- we intend to sync it out
						if cloudRecord.recordChangeTag != nil {
							recordIDsToFetch.insert(cloudRecord.recordID)
						}
						recordIDsToRecords[cloudRecord.recordID] = cloudRecord
					}
				}
				self.recordIDsToDelete = recordIDsToDelete
				self.recordIDsToFetch = recordIDsToFetch
				self.recordIDsToObjectIDs = recordIDsToObjectIDs
				self.recordIDsToRecords = recordIDsToRecords
				finish(withContext: context)
			} catch {
				finish(withError: error)
			}
		}
	}
}
