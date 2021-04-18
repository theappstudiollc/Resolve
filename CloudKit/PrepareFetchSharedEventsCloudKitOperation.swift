//
//  PrepareFetchSharedEventsCloudKitOperation.swift
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

internal final class PrepareFetchSharedEventsCloudKitOperation: CloudKitDataOperation {
	
	// MARK: - Properties and initializers

	public let iCloudDatabaseType: CloudKitDatabaseType
	
	public private(set) var query: CKQuery?
	
	public private(set) var recordIDsToObjectIDs: [CKRecord.ID : NSManagedObjectID]?

	public var fetchedUserUriRepresentations: Set<URL>?

	public var fullRefresh = false

	public var userObjectIDs: Set<NSManagedObjectID>?

	public required init(with workflowContext: CloudKitContext, dataService: CoreDataService, loggingService: CoreLoggingService, in databaseType: CloudKitDatabaseType = .public) {
		iCloudDatabaseType = databaseType
		super.init(with: workflowContext, dataService: dataService, loggingService: loggingService)
	}
	
	// MARK: - CloudKitDataOperation overrides
	
	public override func main() {
		guard let userObjectIDs = userObjectIDs else { fatalError("\(self) requires `userObjectIDs` to be set") }
		dataService.performAndWait { context in
			do {
				let userRequest: NSFetchRequest<User> = User.fetchRequest()
				userRequest.predicate = NSPredicate(format: "SELF in %@", userObjectIDs)
				let users = try context.fetch(userRequest)
				// First create the recordIDsToObjectIDs mapping for all SharedEvents from the provided userIDs
				let cloudReferences = try fetchCloudReferences(for: Set(users), in: context)
				var recordIDsToObjectIDs = [CKRecord.ID : NSManagedObjectID](minimumCapacity: cloudReferences.count)
				var newestRecord: Date?
				for cloudReference in cloudReferences {
					let cloudRecord = cloudReference.cloudRecord
					recordIDsToObjectIDs[cloudRecord.recordID] = cloudReference.syncableEntity!.objectID
					if let creationDate = cloudRecord.creationDate, newestRecord == nil || creationDate > newestRecord! {
						newestRecord = creationDate
					}
				}
				self.recordIDsToObjectIDs = recordIDsToObjectIDs
				// Now generate the CKQuery
				let recordIDs = users.compactMap { $0.cloudRecordID }
				var predicate = NSPredicate(format: "%K in %@", #keyPath(CKRecord.creatorUserRecordID), predicateReferences(recordIDs))
				if fullRefresh == false, let newestRecord = newestRecord,
					let fetchedUserUriRepresentations = fetchedUserUriRepresentations,
					let persistentStoreCoordinator = context.persistentStoreCoordinator,
					userObjectIDs == Set(fetchedUserUriRepresentations.compactMap { persistentStoreCoordinator.managedObjectID(forURIRepresentation: $0) }) {
					// It is necessary to go to the `SharedEvent` schema in the CloudKit Dashboard and ensure the system field `createdAt` is queryable
					let datePredicate = NSPredicate(format: "%K > %@", #keyPath(CKRecord.creationDate), newestRecord as NSDate)
					predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, datePredicate])
				}
				let query = SharedEvent.cloudQuery(with: predicate)
				query.sortDescriptors = [NSSortDescriptor(key: #keyPath(SharedEvent.createdLocallyAt), ascending: false)]
				self.query = query
				// Now finish
				fetchedUserUriRepresentations = Set(userObjectIDs.map { $0.uriRepresentation() })
				finish()
			} catch {
				finish(withError: error)
			}
		}
	}
	
	private func fetchCloudReferences(for users: Set<User>, in context: NSManagedObjectContext) throws -> [ICloudSyncReference] {
		guard #available(iOS 10.0, macOS 10.12.0, tvOS 10.0, watchOS 3.0, *) else {
			// Slower process but required for iOS 9
			let request = SharedEvent.fetchRequestForRecords(in: iCloudDatabaseType, for: nil, using: context)
			let allReferences = try context.fetch(request)
			return allReferences.filter {
				guard let sharedEvent = $0.syncableEntity as? SharedEvent, let user = sharedEvent.user else { return false }
				return users.contains(user)
			}
		}
		let request = SharedEvent.fetchRequestForRecords(in: iCloudDatabaseType, for: users, using: context)
		return try context.fetch(request)
	}
	
	// MARK: - Private properties and methods -
	
	private func predicateReferences(_ recordIDs: [CKRecord.ID]) -> CVarArg {
		if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
			return recordIDs
		}
		return recordIDs.map { CKRecord.Reference(recordID: $0, action: .none) }
	}
}
