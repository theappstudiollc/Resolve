//
//  SharedEventIntentHandler.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2020 The App Studio LLC.
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

import Intents
import CoreData

@available(iOS 12.0, watchOS 5.0, *)
public final class SharedEventIntentHandler: NSObject, CreateSharedEventIntentHandling {

	private let cloudService: CloudKitService
	private let dataService: DataService
	private let userService: AppUserService

	public init(cloudService: CloudKitService, dataService: DataService, userService: AppUserService) {
		self.cloudService = cloudService
		self.dataService = dataService
		self.userService = userService
	}

	public func handle(intent: CreateSharedEventIntent, completion: @escaping (CreateSharedEventIntentResponse) -> Void) {
		print("Handle Intent: \(intent)")

		dataService.performAndWait { [dataService, userService] context in
			let transactionContext = context.beginTransaction()
			do {
				// Get the current user
				let appUser = try userService.currentAppUser(using: context)
				let sharedEvent = try context.create(SharedEvent.self)
				#if os(iOS)
				sharedEvent.createdByDevice = UIDevice.current.name
				#elseif os(watchOS)
				sharedEvent.createdByDevice = WKInterfaceDevice.current().name
				#endif
				sharedEvent.createdLocallyAt = Date().withoutMilliseconds
				sharedEvent.uniqueIdentifier = UUID().uuidString
				sharedEvent.user = appUser
				sharedEvent.createICloudReference(for: .public, with: nil)
				try context.commitTransaction(transactionContext: transactionContext)
				cloudService.synchronize(syncOptions: .default, qualityOfService: .userInitiated) { result in
					switch result {
					case .failure(let error):
						completion(CreateSharedEventIntentResponse.failure(errorMessage: error.localizedDescription))
					default:
						dataService.perform { context in
							let request: NSFetchRequest<SharedEvent> = SharedEvent.fetchRequest()
							request.predicate = SharedEvent.predicateForNotSyncedAs([.synchronizingRelationships, .markedForDeletion])
							let totalRecords = try? context.count(for: request)
							completion(CreateSharedEventIntentResponse.success(totalRecords: NSNumber(integerLiteral: totalRecords ?? 0)))
						}
					}
				}
			} catch {
				context.cancelTransaction(transactionContext: transactionContext)
				completion(CreateSharedEventIntentResponse.failure(errorMessage: error.localizedDescription))
			}
		}
	}
}
