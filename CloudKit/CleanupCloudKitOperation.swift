//
//  CleanupCloudKitOperation.swift
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

internal final class CleanupCloudKitOperation: CloudKitOperation {
	
	public private(set) var retryAfter: Date?
	
	public override func main() {
		guard let error = workflowContext.error else {
			finish()
			return
		}
		switch error {
		case let cloudKitError as CKError where cloudKitError.code == CKError.notAuthenticated:
			// TODO: Maybe this indicates that we need to merge the operation with the completion handler operation
//			workflowContext.accountStatus = .couldNotDetermine
			finish(withError: cloudKitError)
		case let cloudKitError as CKError where [CKError.requestRateLimited, CKError.serviceUnavailable, CKError.zoneBusy].contains(cloudKitError.code):
			guard let retryAfterDuration = cloudKitError.errorUserInfo[CKErrorRetryAfterKey] as? TimeInterval else {
				finish(withError: cloudKitError)
				return
			}
			let retryAfter = Date(timeIntervalSinceNow: retryAfterDuration)
			self.retryAfter = retryAfter
			finish(withError: CloudKitError.cloudBusy(retryAfter))
		default:
			// TODO: Consider an error reporting / logging service
			finish(withError: error)
		}
	}
	
	public override var shouldCancelOnContextError: Bool {
		return false
	}
}
