//
//  SetupCloudKitOperations.swift
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
import CoreResolve

internal struct SetupCloudKitOperations {
    
    let accountStatusOperation: AccountStatusCloudKitOperation
    let fetchUserOperation: FetchCurrentUserIDCloudKitOperation
    let linkUserOperation: LinkUserCloudKitDataOperation
    
    init(with context: CloudKitContext, configuration: CloudKitManagerConfigurationProviding, dependentOperation: Operation? = nil) {
        accountStatusOperation = AccountStatusCloudKitOperation(with: context)
        fetchUserOperation = FetchCurrentUserIDCloudKitOperation(with: context)
        linkUserOperation = LinkUserCloudKitDataOperation(with: context, dataService: configuration.dataService, loggingService: configuration.loggingService, userService: configuration.userService)
        if let dependentOperation = dependentOperation {
            accountStatusOperation.addDependency(dependentOperation)
        }
        linkOperations()
    }

    private func linkOperations() {
        accountStatusOperation.linkWorkflow(to: fetchUserOperation)
        fetchUserOperation.linkWorkflow(to: linkUserOperation) { fetchUser, linkUser in
            linkUser.currentUserRecordID = fetchUser.currentUserRecordID
        }
    }
}

extension SetupCloudKitOperations: CloudKitManagerOperationGroup {
    
    var firstOperation: CloudKitOperation {
        return accountStatusOperation
    }
    
    var lastOperation: CloudKitOperation {
        return linkUserOperation
    }
    
    var progress: Progress {
        let retVal = Progress(totalUnitCount: 3)
        retVal.addChild(accountStatusOperation.progress, withPendingUnitCount: 1)
        retVal.addChild(fetchUserOperation.progress, withPendingUnitCount: 1)
        retVal.addChild(linkUserOperation.progress, withPendingUnitCount: 1)
        return retVal
    }
	
	@available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *)
	func applyOperationGroup(_ operationGroup: CKOperationGroup) {

	}
}
