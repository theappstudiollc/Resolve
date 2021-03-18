//
//  ManagedObject-Extensions.swift
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
import CoreResolve

public extension NSManagedObject {
	
	// TODO: This function should probably also throw an exception
	class func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
		return NSEntityDescription.entity(forEntityName: "\(Self.self)", in: context)!
	}
}

public extension NSManagedObjectContext {
	
	func create<T>(_ objectType: T.Type, withTransaction transaction: (() throws -> Void)? = nil) throws -> T where T: NSManagedObject {
		let entityName = "\(T.self)"
		guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: self) else {
			throw ResolveKitDataError.unknownEntity(named: entityName)
		}
		if let transaction = transaction {
			// TODO: This is experimental -- remove if it promotes bad practices
			let existingUndoManager = undoManager
			do {
				beginTransaction()
				let result = T(entity: entityDescription, insertInto: self)
				try transaction()
				try commitTransaction()
				undoManager = existingUndoManager
				return result
			}
			catch {
				cancelTransaction()
				undoManager = existingUndoManager
				throw ResolveKitDataError.initializationFailure(error)
			}
		}
		return T(entity: entityDescription, insertInto: self)
	}
}
