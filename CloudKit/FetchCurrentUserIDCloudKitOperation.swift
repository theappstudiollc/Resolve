//
//  FetchCurrentUserIDCloudKitOperation.swift
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

import CloudKit

internal final class FetchCurrentUserIDCloudKitOperation: CloudKitOperation {

	public private(set) var currentUserRecordID: CKRecord.ID?

	public override func main() {
		guard workflowContext.currentUserRecordID == nil else {
			finish()
			return
		}
		workflowContext.cloudContainer.fetchUserRecordID(completionHandler: responseHandler)
	}

	public override var shouldCancelOnContextError: Bool {
		// Always run this so that we get CKRecordID's that don't say "__defaultOwner__" for the main user
		return false
	}

	private func responseHandler(_ recordID: CKRecord.ID?, _ error: Error?) {
		switch (recordID, error) {
		case (_, .some(let error)):
			self.finish(withError: error)
		case (.some(let recordID), _):
			self.currentUserRecordID = recordID
			self.finish()
		default:
			let error = CloudKitError.internalInconsistency("No user record ID nor error reported")
			self.finish(withError: error)
		}
	}
}
