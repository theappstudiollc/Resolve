//
//  LookupFriendsCloudKitOperations.swift
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

#if canImport(Contacts)

import CloudKit
import Contacts

internal struct LookupFriendsCloudKitOperations {
    
    let userDiscoverabilityStatusOperation: UserDiscoverabilityPermissionStatusCloudKitOperation
    let userDiscoverabilityRequestOperation: UserDiscoverabilityPermissionRequestCloudKitOperation
    let lookupUsersOperation: LookupUsersCloudKitOperation
    
	init(with context: CloudKitContext, contacts: [CNContact], dependentOperation: Operation? = nil) {
		// This operation group does not support finding friends without first granting permission to be discovered
        userDiscoverabilityStatusOperation = UserDiscoverabilityPermissionStatusCloudKitOperation(with: context)
        userDiscoverabilityRequestOperation = UserDiscoverabilityPermissionRequestCloudKitOperation(with: context)
		lookupUsersOperation = LookupUsersCloudKitOperation(with: context, contacts: contacts)
        if let dependentOperation = dependentOperation {
            userDiscoverabilityStatusOperation.addDependency(dependentOperation)
        }
        linkOperations()
    }

    private func linkOperations() {
        userDiscoverabilityStatusOperation.linkWorkflow(to: userDiscoverabilityRequestOperation)
        userDiscoverabilityRequestOperation.linkWorkflow(to: lookupUsersOperation, cancelOnError: true)
    }
}

extension LookupFriendsCloudKitOperations: CloudKitManagerOperationGroup {
    
    var firstOperation: CloudKitOperation {
        return userDiscoverabilityStatusOperation
    }
    
    var lastOperation: CloudKitOperation {
        return lookupUsersOperation
    }
    
    var progress: Progress {
        let retVal = Progress(totalUnitCount: 3)
        retVal.addChild(userDiscoverabilityStatusOperation.progress, withPendingUnitCount: 1)
        retVal.addChild(userDiscoverabilityRequestOperation.progress, withPendingUnitCount: 1)
        retVal.addChild(lookupUsersOperation.progress, withPendingUnitCount: 1)
        return retVal
    }
	
	@available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *)
	func applyOperationGroup(_ operationGroup: CKOperationGroup) {
		lookupUsersOperation.operationGroup = operationGroup
	}
}

#endif
