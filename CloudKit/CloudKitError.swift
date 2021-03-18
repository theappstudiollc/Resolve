//
//  CloudKitError.swift
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

/// Error describing the reason for failures to interact with the CloudKitService
///
/// - cloudBusy: CloudKit is requesting to try again later. Provide the server's suggested `retryAfter` Date to the caller
/// - internalInconsistency: An internal inconsistency error was encountered. Provide a `failureReason` for the caller
/// - unsupportedWorkflow: An unsupported workflow was encountered. Provide a `failureReason` for the caller
/// - updatesNotPermitted: The user does not have permission to write to iCloud. Provide the current `accountStatus` to the caller
public enum CloudKitError: Error {
	
	case cloudBusy(_ retryAfter: Date) // TODO: Include the CKError that reported this condition
	
	case internalInconsistency(_ failureReason: String)
	
	case unsupportedWorkflow(_ failureReason: String)
	
	case updatesNotPermitted(_ accountStatus: CKAccountStatus)
}

extension CloudKitError: LocalizedError {
	
	public var errorDescription: String? {
		return NSLocalizedString("\(self).errorDescription", tableName: "CloudKitError", bundle: Bundle(for: CloudKitManager.self), comment: "\(self)")
	}
	
	public var failureReason: String? {
		switch self {
		case .internalInconsistency(let failureReason):
			return failureReason
		case .unsupportedWorkflow(let failureReason):
			return failureReason
		default:
			return nil
		}
	}
}
