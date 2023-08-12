//
//  DiscoverUsersCloudKitOperation.swift
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

import Foundation
import CloudKit
import CoreResolve
import CoreResolve_ObjC // iOS 9 support
#if canImport(Contacts)
import Contacts
#endif

// TODO: Consider making this class unavailable to tvOS

internal final class DiscoverUsersCloudKitOperation: CloudKitGroupOperation {
	
	private var cloudOperation: CKOperation?
	
	private static var retryAfter: Date?
	
	public private(set) var userInfos = Set<CloudUserInfo>()
	
	public override func cancel() {
		cloudOperation?.cancel()
		super.cancel()
	}
	
	public override func finish(withError error: Error) {
		switch error {
		case let cloudKitError as CKError where cloudKitError.code == CKError.requestRateLimited:
			guard let retryAfterDuration = cloudKitError.errorUserInfo[CKErrorRetryAfterKey] as? TimeInterval else {
				workflowContext.logger.log(.error, "Unexpected error without a retryAfter value: %{public}@", cloudKitError.localizedDescription)
				super.finish(withError: cloudKitError)
				return
			}
			let retryAfter = Date(timeIntervalSinceNow: retryAfterDuration)
			DiscoverUsersCloudKitOperation.retryAfter = retryAfter
			super.finish(withError: CloudKitError.cloudBusy(retryAfter))
		default:
			super.finish(withError: error)
		}
	}
	
	public override func main() {
		if let retryAfter = DiscoverUsersCloudKitOperation.retryAfter, retryAfter > Date() {
			finish(withError: CloudKitError.cloudBusy(retryAfter))
			return
		}
		DiscoverUsersCloudKitOperation.retryAfter = nil
		#if os(tvOS)
			finish()
		#else
			let operation = configuredOperation()
			operation.setOperationQuality(from: self)
			cloudOperation = operation
			workflowContext.cloudContainer.add(operation)
		#endif
	}
	
	#if os(watchOS) || targetEnvironment(macCatalyst)
	
	private func configuredOperation() -> CKOperation {
		let retVal = CKDiscoverAllUserIdentitiesOperation()
		retVal.userIdentityDiscoveredBlock = userIdentityResponseHandler
		retVal.discoverAllUserIdentitiesCompletionBlock = userIdentitiesCompletedResponseHandler
		return retVal
	}
	
	#elseif !os(tvOS)
	
	private func configuredOperation() -> CKOperation {
		guard #available(iOS 10.0, macOS 10.12, watchOS 3.0, *) else {
			let retVal = CKDiscoverAllContactsOperation()
			retVal.discoverAllContactsCompletionBlock = contactsResponseHandler
			return retVal
		}
		let retVal = CKDiscoverAllUserIdentitiesOperation()
		retVal.userIdentityDiscoveredBlock = userIdentityResponseHandler
		if #available(iOS 15.0, macOS 10.12, *) {
			retVal.discoverAllUserIdentitiesResultBlock = userIdentitiesCompletedResponseHandler
		} else { // This is both introduced and deprecated in macOS 10.12
			retVal.discoverAllUserIdentitiesCompletionBlock = userIdentitiesCompletedResponseHandler
		}
		return retVal
	}

	@available(iOS, deprecated: 10.0)
	@available(macOS, deprecated: 10.12)
	private func contactsResponseHandler(_ discoveredUserInfos: [CKDiscoveredUserInfo]?, _ error: Error?) {
		if let error = error {
			finish(withError: error)
		} else if let discoveredUserInfos = discoveredUserInfos {
			let mappedUserInfos = discoveredUserInfos.compactMap { CloudUserInfo(discoveredUserInfo: $0) }
			self.userInfos.formUnion(mappedUserInfos)
			finish()
		} else { // TODO: Return an error (we know this won't happen)
			finish()
		}
	}

	#endif

	@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
	private func userIdentityResponseHandler(_ userIdentity: CKUserIdentity) {
		guard let userInfo = CloudUserInfo(userIdentity: userIdentity) else { return }
		userInfos.insert(userInfo)
	}
	
	private func userIdentitiesCompletedResponseHandler(_ result: Result<Void,Error>)
	{
		switch result {
		case .failure(let error):
			finish(withError: error)
		case .success:
			finish()
		}
	}
	
	private func userIdentitiesCompletedResponseHandler(_ error: Error?) {
		if let error = error {
			userIdentitiesCompletedResponseHandler(.failure(error))
		} else {
			userIdentitiesCompletedResponseHandler(.success(()))
		}
	}
}
