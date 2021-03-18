//
//  User-Extensions.swift
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

import CoreData

public extension User {
	
	static func loadUser(with persistentReference: URL, using context: NSManagedObjectContext) throws -> User? {
		guard let coordinator = context.persistentStoreCoordinator, let userID = coordinator.managedObjectID(forURIRepresentation: persistentReference) else {
			return nil
		}
		let retVal = try context.existingObject(with: userID)
		guard let appUser = retVal as? User else {
			fatalError("\(retVal) is not an \(self)")
		}
		return appUser
	}
	
	// MARK: - Public properties
	
	var persistentReference: URL? {
		precondition(!objectID.isTemporaryID, "We cannot return a temporary identifier")
		return objectID.uriRepresentation()
	}
}
