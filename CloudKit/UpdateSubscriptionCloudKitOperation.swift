//
//  UpdateSubscriptionCloudKitOperation.swift
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

internal final class UpdateSubscriptionCloudKitOperation: CloudKitGroupOperation {
	
	public var subscribedUsers: Set<CKRecord.ID>?
	public var userRecordIDs: Set<CKRecord.ID>?
	
	public override func main() {
		guard #available(watchOS 6.0, *), let userRecordIDs = userRecordIDs, userRecordIDs != subscribedUsers else {
			finish()
			return
		}
		let fetchOperation = CKFetchSubscriptionsOperation(subscriptionIDs: [CloudKitContext.sharedEventsSubscriptionID])
		fetchOperation.fetchSubscriptionCompletionBlock = fetchOperationHandler
		fetchOperation.setOperationQuality(from: self)
		cloudDatabase.add(fetchOperation)
	}
	
	@available(watchOS 6.0, *)
	private func fetchOperationHandler(_ subscriptions: [CKSubscription.ID : CKSubscription]?, _ error: Error?) {
		// TODO: Determine if we need to examine partial errors -- for now it seems like no
		guard /*let subscriptions = subscriptions,*/ let userIDs = userRecordIDs else {
			let operationError = error ?? CloudKitError.internalInconsistency("unknown fetch subscription error")
			finish(withError: operationError)
			return
		}
		var subscriptionsToSave = [CKSubscription]()
		// It is necessary to go to the `SharedEvent` schema in the CloudKit Dashboard and ensure the system field `createdBy` is queryable
		let predicate = NSPredicate(format: "%K in %@", #keyPath(CKRecord.creatorUserRecordID), predicateReferences(userIDs))
		if #available(iOS 10.0, macOS 10.12.0, tvOS 10.0, *), let subscription = subscriptions?[CloudKitContext.sharedEventsSubscriptionID] as? CKQuerySubscription {
			// TODO: Find a nice way to determine if the predicates are equivalent (the formats are not equal)
			if subscription.predicate != predicate {
				subscriptionsToSave.append(createSubscription(predicate: predicate))
			}
		} else {
			subscriptionsToSave.append(createSubscription(predicate: predicate))
		}
		
		if subscriptionsToSave.count == 0 {
			finish()
		} else {
			let modifyOperation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptionsToSave, subscriptionIDsToDelete: nil)
			modifyOperation.modifySubscriptionsCompletionBlock = modifyOperationHandler
			modifyOperation.setOperationQuality(from: self)
			cloudDatabase.add(modifyOperation)
		}
	}
	
	@available(watchOS 6.0, *)
	private func modifyOperationHandler(_ modified: [CKSubscription]?, _ deleted: [CKSubscription.ID]?, _ error: Error?) {
		// TODO: Determine if we need to examine partial errors -- for now it seems like no
		if let error = error {
			finish(withError: error)
			return
		}
		print("CKModifySubscriptionsOperation results")
		if let modified = modified, modified.contains(where: { $0.subscriptionID == CloudKitContext.sharedEventsSubscriptionID }) {
			print(" - updated: \(modified)")
			subscribedUsers = userRecordIDs
		}
		if let deleted = deleted, deleted.count > 0 {
			print(" - deleted: \(deleted)")
		}
		finish()
	}
	
	private var cloudDatabase: CKDatabase {
		return workflowContext.cloudContainer.publicCloudDatabase
	}
	
	@available(watchOS 6.0, *)
	private func createSubscription(predicate: NSPredicate) -> CKSubscription {
		let result: CKSubscription
		#if os(watchOS)
		let options: CKQuerySubscription.Options = [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
		result = CKQuerySubscription(recordType: SharedEvent.cloudRecordType, predicate: predicate, subscriptionID: CloudKitContext.sharedEventsSubscriptionID, options: options)
		#else
		if #available(iOS 10.0, macOS 10.12.0, tvOS 10.0, *) {
			let options: CKQuerySubscription.Options = [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
			result = CKQuerySubscription(recordType: SharedEvent.cloudRecordType, predicate: predicate, subscriptionID: CloudKitContext.sharedEventsSubscriptionID, options: options)
		} else {
			let options: CKSubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
			result = CKSubscription(recordType: SharedEvent.cloudRecordType, predicate: predicate, subscriptionID: CloudKitContext.sharedEventsSubscriptionID, options: options)
		}
		#endif
		let notification = CKSubscription.NotificationInfo()
		notification.shouldSendContentAvailable = true
		result.notificationInfo = notification
		return result
	}
	
	private func predicateReferences(_ recordIDs: Set<CKRecord.ID>) -> CVarArg {
		// CKSubscriptions need CKRecord.References
//		if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
//			return recordIDs
//		}
		return recordIDs.map { CKRecord.Reference(recordID: $0, action: .none) }
	}
}
