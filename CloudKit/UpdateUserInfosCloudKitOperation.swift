//
//  UpdateUserInfosCloudKitOperation.swift
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

internal final class UpdateUserInfosCloudKitOperation: CloudKitDataOperation {

	public var currentUserRecord: CKRecord?
	public var userInfos: Set<CloudUserInfo>?
	
	private let userService: AppUserService
	
	required public init(with workflowContext: WorkflowContext, dataService: CoreDataService, loggingService: CoreLoggingService, userService: AppUserService) {
		self.userService = userService
		super.init(with: workflowContext, dataService: dataService, loggingService: loggingService)
	}

	public override func main() {
		guard let userInfos = userInfos else {
			finish(withError: CloudKitError.internalInconsistency("user infos dictionary not provided"))
			return
		}
		dataService.perform { [loggingService] context in
			guard let currentAppUser = try? self.userService.currentAppUser(using: context) else {
				self.finish(withError: CloudKitError.internalInconsistency("Could not obtain current user record"))
				return
			}
			
			let transactionContext = context.beginTransaction()

			do {
				let users = try userInfos.compactMap { userInfo -> User in
					if let user = try User.instance(for: userInfo.recordID, in: .public, using: context) {
						let changed = user.updatePrivateFieldsWith(userInfo: userInfo)
						// TODO: Later we may create a special Friend Zone + CKRecords to contain this extra information
						if changed /*, user == currentAppUser*/ {
							loggingService.log(.info, "Changed private user info for %{public}@", userInfo.recordID.indexableRepresentation)
							/*
							if let iCloudReference = user.iCloudReference(for: .private) {
								iCloudReference.synchronized = false
							} else if let publicCloudRecord = user.publicCloudRecord {
								user.createICloudReference(for: .private, with: publicCloudRecord).synchronized = false
							} else {
								loggingService.log(.error, "Suprise! No private iCloudReference for %{private}@", user.userAlias ?? "<alias not set>")
							}
							*/
						}
						return user
					}
					let user = User.create(with: userInfo.recordID, using: context)
					// TODO: Utilize synchronizingRelationships if a user's record requires additional data before being presented in the UI
	//				user.syncStatus = CloudSyncStatus.synchronizingRelationships.rawValue
					user.updatePrivateFieldsWith(userInfo: userInfo)
					return user
				}
				var friendsChanged = false
				for user in users.filter({ $0 != currentAppUser && !currentAppUser.hasFriend($0) }) {
					currentAppUser.addToFriends(user)
					friendsChanged = true
				}
				if friendsChanged {
					if let iCloudReference = currentAppUser.iCloudReference(for: .private) {
						iCloudReference.synchronized = false
					} else if let publicCloudRecord = currentAppUser.publicCloudRecord {
						currentAppUser.createICloudReference(for: .private, with: publicCloudRecord).synchronized = false
					} else {
						loggingService.log(.error, "Suprise! No publicCloudRecord for %{private}@", currentAppUser.userAlias ?? "<alias not set>")
					}
				}
				
				try context.obtainPermanentIDs(for: users)
				try context.commitTransaction(transactionContext: transactionContext)
				self.finish()
			} catch {
				context.cancelTransaction(transactionContext: transactionContext)
				self.finish(withError: error)
			}
		}
	}
}

extension User {
	
	@discardableResult fileprivate func updatePrivateFieldsWith(userInfo: CloudUserInfo) -> Bool {
		var retVal = false
		if userFirstName != userInfo.firstName {
			userFirstName = userInfo.firstName
			retVal = true
		}
		if userLastName != userInfo.lastName {
			userLastName = userInfo.lastName
			retVal = true
		}
		return retVal
	}
}
