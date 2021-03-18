//
//  CloudKitGroupOperation.swift
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
import CoreResolve

internal protocol CloudKitGroupMember: Operation {

	var operationGroup: NSObject? { get set }
}

internal class CloudKitGroupOperation: CloudKitOperation, CloudKitGroupMember {

	public var operationGroup: NSObject? {
		didSet {
			if #available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *) {
				assert(operationGroup == nil || operationGroup is CKOperationGroup)
			} else {
				assert(operationGroup == nil, "`operationGroup` must be of type `CKOperationGroup`")
			}
		}
	}
}

internal extension CKOperation {

	func setOperationQuality(from groupMember: CloudKitGroupMember) {
		if #available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *), let operationGroup = groupMember.operationGroup as? CKOperationGroup {
			group = operationGroup
		} else {
			qualityOfService = groupMember.qualityOfService
		}
		queuePriority = groupMember.queuePriority
	}
}
