//
//  SharedEventPrefetchDataSource.swift
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

import ResolveKit

@available(iOS 10.0, macOS 10.13.0, tvOS 10.0, *)
final class SharedEventPrefetchDataSource: FetchedResultsControllerPrefetchDataSource<SharedEvent> {

	override func fetchRequestForPrefetching(results: [SharedEvent], from fetchRequest: NSFetchRequest<SharedEvent>) -> NSFetchRequest<NSFetchRequestResult>? {
		guard fetchRequest.returnsObjectsAsFaults == true else {
			loggingService.log(.info, "no need to prefetch, default fetch request result types do not return faults")
			return nil
		}
		guard let entityName = fetchRequest.entityName else {
			loggingService.log(.info, "entity name cannot be found -- this is surprising")
			return nil
		}
		let filteredResult = results.filter { $0.isFault || $0.hasFault(forRelationshipNamed: "syncReferences") }
		guard filteredResult.count > 0 else {
//			loggingService.log(.debug, "Nothing to prefetch -- all %ld objects not faulted", results.count)
			return nil
		}
		// Default behavior resolves any faults in ResultType, if they exist
		let result = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
		result.predicate = NSPredicate(format: "SELF IN %@", filteredResult)
		result.relationshipKeyPathsForPrefetching = ["syncReferences"]
		result.returnsObjectsAsFaults = false
		return result
	}
}
