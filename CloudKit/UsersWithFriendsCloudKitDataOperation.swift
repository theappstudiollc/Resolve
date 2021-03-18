//
//  UsersWithFriendsCloudKitDataOperation.swift
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

internal final class UsersWithFriendsCloudKitDataOperation: CloudKitDataOperation {
	
	// MARK: - Public properties

	public private(set) var userObjectIDs: Set<NSManagedObjectID>?
	
	public private(set) var userRecordIDs: Set<CKRecord.ID>?
	
	override final public func main() {
		dataService.performAndWait { context in
			do {
				// This implicitly includes multiple logged in users that have had friends
				let request: NSFetchRequest<User> = User.fetchRequest()
				let friendsPredicate = NSPredicate(format: "%K.@count>0", #keyPath(User.friends))
				if let linkedUserObjectID = workflowContext.linkedUserObjectID {
					let userPredicate = NSPredicate(format: "SELF=%@", linkedUserObjectID)
					request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [userPredicate, friendsPredicate])
				} else {
					request.predicate = friendsPredicate
				}
				let usersWithFriends = try context.fetch(request)
				
				// First create the objectIDs
				var objectIDs = Set<NSManagedObjectID>(minimumCapacity: usersWithFriends.count)
				objectIDs.formUnion(usersWithFriends.map { $0.objectID })
				self.userObjectIDs = objectIDs
				
				// Now create the recordIDs
				var recordIDs = Set<CKRecord.ID>(minimumCapacity: usersWithFriends.count)
				recordIDs.formUnion(usersWithFriends.compactMap { $0.cloudRecordID })
				self.userRecordIDs = recordIDs
				// Now we can return
				finish(withContext: context)
			} catch {
				finish(withError: error)
			}
		}
	}
}
