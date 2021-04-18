//
//  AccountStatusCloudKitOperation.swift
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

internal final class AccountStatusCloudKitOperation: CloudKitOperation {
	
	public private(set) var accountStatus = CKAccountStatus.couldNotDetermine
	
	public override func main() {
		guard workflowContext.accountStatus != .available else {
			finish()
			return
		}
		workflowContext.cloudContainer.accountStatus(completionHandler: responseHandler)
	}
	
	private func responseHandler(_ accountStatus: CKAccountStatus, _ error: Error?) {
		if let error = error {
			finish(withError: error)
		} else {
			switch accountStatus {
			case .noAccount, .restricted, .couldNotDetermine:
				finish(withError: CloudKitError.updatesNotPermitted(accountStatus))
			default:
				finish()
			}
		}
	}
}
