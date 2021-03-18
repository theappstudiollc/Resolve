//
//  LookupUsersCloudKitOperation.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2021 The App Studio LLC.
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

#if canImport(Contacts)

import Foundation
import CloudKit
import CoreResolve
import Contacts

internal final class LookupUsersCloudKitOperation: CloudKitGroupOperation {

	private var cloudOperation: CKOperation?

	public let contacts: [CNContact]

	public private(set) var userInfos = Set<CloudUserInfo>()

	public required init(with workflowContext: CloudKitContext, contacts: [CNContact]) {
		self.contacts = contacts
		super.init(with: workflowContext)
	}

	override public func cancel() {
		cloudOperation?.cancel()
		super.cancel()
	}

	override public func finish(withError error: Error) {
		switch error {
		case let cloudKitError as CKError where cloudKitError.code == CKError.requestRateLimited:
			guard let retryAfterDuration = cloudKitError.errorUserInfo[CKErrorRetryAfterKey] as? TimeInterval else {
				workflowContext.logger.log(.error, "Unexpected error without a retryAfter value: %{public}@", cloudKitError.localizedDescription)
				super.finish(withError: cloudKitError)
				return
			}
			let retryAfter = Date(timeIntervalSinceNow: retryAfterDuration)
			super.finish(withError: CloudKitError.cloudBusy(retryAfter))
		default:
			super.finish(withError: error)
		}
	}

	override public func main() {
		let emailAddresses: [String] = contacts.flatMap { contact in
			return contact.emailAddresses.map { String($0.value) }
		}
		let userRecordIDs: [CKRecord.ID]
		if let userRecordID = workflowContext.currentUserRecordID {
			userRecordIDs = [userRecordID]
		} else {
			userRecordIDs = []
		}
		let operation = configuredOperation(emailAddresses: emailAddresses, userRecordIDs: userRecordIDs)
		operation.setOperationQuality(from: self)
		cloudOperation = operation
		workflowContext.cloudContainer.add(operation)
	}
	
	#if os(watchOS) || targetEnvironment(macCatalyst)

	private func configuredOperation(emailAddresses: [String], userRecordIDs: [CKRecord.ID]) -> CKOperation {
		let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: lookupInfos(emailAddresses: emailAddresses, userRecordIDs: userRecordIDs))
		operation.userIdentityDiscoveredBlock = userIdentityResponseHandler
		operation.discoverUserIdentitiesCompletionBlock = userIdentitiesCompletedResponseHandler
		return operation
	}

	#elseif !os(tvOS)

	private func configuredOperation(emailAddresses: [String], userRecordIDs: [CKRecord.ID]) -> CKOperation {
		guard #available(iOS 10.0, macOS 10.12, watchOS 3.0, *) else {
			let operation = CKDiscoverUserInfosOperation(emailAddresses: emailAddresses, userRecordIDs: userRecordIDs)
			operation.discoverUserInfosCompletionBlock = discoveredUsersResponseHandler
			return operation
		}
		let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: lookupInfos(emailAddresses: emailAddresses, userRecordIDs: userRecordIDs))
		operation.userIdentityDiscoveredBlock = userIdentityResponseHandler
		operation.discoverUserIdentitiesCompletionBlock = userIdentitiesCompletedResponseHandler
		return operation
	}

	@available(macOS, deprecated: 10.12)
	private func discoveredUsersResponseHandler(_ emailsToUserInfos: [String : CKDiscoveredUserInfo]?, _ userRecordIDsToUserInfos: [CKRecord.ID : CKDiscoveredUserInfo]?, _ operationError: Error?) {
		if let error = error {
			finish(withError: error)
		} else {
			if let emailsToUserInfos = emailsToUserInfos {
				let mappedUserInfos = emailsToUserInfos.compactMap { CloudUserInfo(discoveredUserInfo: $0.value) }
				self.userInfos.formUnion(mappedUserInfos)
			}
			if let userRecordIDsToUserInfos = userRecordIDsToUserInfos {
				let mappedUserInfos = userRecordIDsToUserInfos.compactMap { CloudUserInfo(discoveredUserInfo: $0.value) }
				self.userInfos.formUnion(mappedUserInfos)
			}
			finish()
		}
	}

	#endif

	@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
	private func lookupInfos(emailAddresses: [String], userRecordIDs: [CKRecord.ID]) -> [CKUserIdentity.LookupInfo] {
		return emailAddresses.map { emailAddress in
			return CKUserIdentity.LookupInfo(emailAddress: emailAddress)
		} + userRecordIDs.map { userRecordID in
			return CKUserIdentity.LookupInfo(userRecordID: userRecordID)
		}
	}

	@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
	private func userIdentityResponseHandler(_ userIdentity: CKUserIdentity, _ lookupInfo: CKUserIdentity.LookupInfo) {
		guard let userInfo = CloudUserInfo(userIdentity: userIdentity) else { return }
		userInfos.insert(userInfo)
	}

	private func userIdentitiesCompletedResponseHandler(_ error: Error?) {
		if let error = error {
			finish(withError: error)
		} else {
			finish()
		}
	}
}

#endif
