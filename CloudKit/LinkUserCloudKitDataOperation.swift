//
//  LinkUserCloudKitDataOperation.swift
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

internal final class LinkUserCloudKitDataOperation: CloudKitDataOperation {
	
	public var currentUserRecordID: CKRecord.ID?
	public private(set) var currentUserObjectID: NSManagedObjectID?
	
	private let userService: AppUserService
	
	required public init(with workflowContext: WorkflowContext, dataService: CoreDataService, loggingService: CoreLoggingService, userService: AppUserService) {
		self.userService = userService
		super.init(with: workflowContext, dataService: dataService, loggingService: loggingService)
	}
	
	public override func main() {
		guard let currentUserRecordID = currentUserRecordID ?? workflowContext.currentUserRecordID else {
			finish(withError: CloudKitError.internalInconsistency("Could not obtain current user record id"))
			return
		}
		dataService.performAndWait { [userService] context in
			let transactionContext = context.beginTransaction()

			do {
				let candidate: User?
				// Check if the appropriate User is already in CoreData
				if let existingUser = try User.instance(for: currentUserRecordID, in: .public, using: context) {
					candidate = existingUser
				} else if let currentAppUser = try? userService.currentAppUser(using: context) {
					if let cloudRecordID = currentAppUser.cloudRecordID, cloudRecordID.indexableRepresentation != currentUserRecordID.indexableRepresentation {
						candidate = nil // Only nil or matching representations may be candidates, so we reject this one
					} else {
						candidate = currentAppUser
					}
				} else {
					candidate = nil
				}
				// Check if we need to create the User, or assign an existing
				let appUser: User
				if let matchedUser = candidate {
					appUser = matchedUser
				} else if let recentAppUser = try? userService.mostRecentUnlinkedAppUser(using: context) {
					// TODO: perhaps eliminate mostRecentUnlinkedAppUser. Also consider uniqueness constraints
					appUser = recentAppUser
				} else { // we need to up and create one
					appUser = User.create(with: currentUserRecordID, using: context)
				}
				// Ensure both Public and Private iCloud records exist for the `appUser`
				if appUser.iCloudReference(for: .public) == nil {
					let record = User.createICloudRecord(with: currentUserRecordID)
					appUser.createICloudReference(for: .public, with: record)
				}
				if appUser.iCloudReference(for: .private) == nil {
					let record = User.createICloudRecord(with: currentUserRecordID)
					appUser.createICloudReference(for: .private, with: record)
				}
				try context.commitTransaction(transactionContext: transactionContext)
				userService.assignCurrent(appUser: appUser, using: context)
				self.currentUserObjectID = appUser.objectID
				self.finish()
			} catch {
				context.cancelTransaction(transactionContext: transactionContext)
				self.finish(withError: error)
			}
		}
	}
}
