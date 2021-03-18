//
//  ResolveKitCoreDataStack.swift
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

public final class ResolveKitCoreDataStack: SingleCoordinatorAsynchronouslyMergingCoreDataStack {

	public override func createContext(with concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
		let result = super.createContext(with: concurrencyType)
		result.mergePolicy = ResolveKitMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
		return result
	}
}

fileprivate final class ResolveKitMergePolicy: NSMergePolicy {
	
	override func resolve(constraintConflicts list: [NSConstraintConflict]) throws {
		
		// Save all Feature.imageData so that we can restore them after the merge conflict
		var affectedEvents = Set<SharedEvent>()
		for conflict in list {
			if let feature = conflict.databaseObject as? SharedEvent {
				affectedEvents.insert(feature)
			}
			for feature in conflict.conflictingObjects.compactMap({ $0 as? SharedEvent }) {
				affectedEvents.insert(feature)
			}
		}
		
		// Call super to perform the default conflict resolution
		try super.resolve(constraintConflicts: list)
	}
}
