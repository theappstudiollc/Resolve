//
//  CloudKitService.swift
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
#if canImport(Contacts)
import Contacts
#endif
import CoreData

public protocol CloudKitService {

	typealias CloudKitServiceSynchronizationCompletion = (_ result: Result<Void, Error>) -> Void
	
	// TODO: Maybe some of the next four really need to be returned with a completion handler...
	var accountStatus: CKAccountStatus { get }
	var currentUserRecordID: CKRecord.ID? { get }
	var linkedUserObjectID: NSManagedObjectID? { get }
	var userDiscoverabilityPermissionStatus: CKContainer.Application.PermissionStatus { get }

	/// Returns the date of the last sync utilizing .fullSync (or .distantPast if never performed)
	var lastFullSync: Date { get }
	
	func cancelAllOperations()
	func canProcess(notification: CKNotification) -> Bool

	#if canImport(Contacts)
	// TODO: Report the number of records found & possibly newly added in the completion
	@discardableResult func addFriends(contacts: [CNContact], _ completion: CloudKitServiceSynchronizationCompletion?) -> Progress?
	#endif
	
	@discardableResult func fetchChanges(notification: CKNotification, qualityOfService: QualityOfService, _ completion: @escaping CloudKitServiceSynchronizationCompletion) -> Progress?

	@discardableResult func requestUserDiscoverabilityPermission(_ completion: @escaping CloudKitServiceSynchronizationCompletion) -> Progress?
	
	@discardableResult func synchronize(syncOptions: CloudKitServiceSyncOptions, qualityOfService: QualityOfService, _ completion: CloudKitServiceSynchronizationCompletion?) -> Progress?
}

public struct CloudKitServiceSyncOptions: OptionSet {
	
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let `default`: CloudKitServiceSyncOptions = []
	public static let fetchAll = CloudKitServiceSyncOptions(rawValue: 1 << 0)
	public static let refreshAll = CloudKitServiceSyncOptions(rawValue: 1 << 1)
	public static let fullSync: CloudKitServiceSyncOptions = [.fetchAll, .refreshAll]
}
