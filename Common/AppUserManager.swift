//
//  AppUserManager.swift
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

public class AppUserManager {
	
	fileprivate var dataService: CoreDataService
	fileprivate var loggingService: CoreLoggingService
	fileprivate var settings: CoreDataSettingsService

	public init(dataService: CoreDataService, loggingService: CoreLoggingService, settings: CoreDataSettingsService) {
		self.dataService = dataService
		self.loggingService = loggingService
		self.settings = settings
	}
}

extension AppUserManager: AppUserService {
	
	public func assignCurrent(appUser: User, using context: NSManagedObjectContext) {
		guard settings.appUserPersistentReference != appUser.persistentReference else {
			return
		}
		if settings.appUserPersistentReference != nil {
			// TODO: Consider whether we need an alert or something
		}
		settings.appUserPersistentReference = appUser.persistentReference
	}
	
	public func currentAppUser(using context: NSManagedObjectContext) throws -> User? {
		guard let appUserPersistentReference = settings.appUserPersistentReference else {
			return nil
		}
		guard let retVal = try User.loadUser(with: appUserPersistentReference, using: context) else {
			settings.appUserPersistentReference = nil
			return nil
		}
		return retVal
	}
	
	public func establishUser(_ completion: @escaping (Bool) -> Void) {
		dataService.perform { [loggingService] context in
			var success = true
			let transactionContext = context.undoManager
			do {
				var appUser = try self.currentAppUser(using: context)
				if appUser == nil {
					context.beginTransaction()
					appUser = try context.create(User.self)
					try context.commitTransaction(transactionContext: transactionContext)
					self.assignCurrent(appUser: appUser!, using: context)
				}
			} catch {
				context.cancelTransaction(transactionContext: transactionContext)
				loggingService.log(.error, "Error establishing user: %{public}@", error.localizedDescription)
				success = false
			}
			completion(success)
		}
	}
	
	public func mostRecentUnlinkedAppUser(using context: NSManagedObjectContext) throws -> User? {
		let request: NSFetchRequest<User> = User.fetchRequest()
		request.predicate = NSPredicate(format: "%K.@count=0", #keyPath(User.syncReferences))
		request.fetchLimit = 1
		request.includesSubentities = false
//		request.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.userCreatedAt), ascending: false)]
		return try context.fetch(request).first
	}
}
