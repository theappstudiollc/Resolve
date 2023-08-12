//
//  CloudKitContext.swift
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
import CoreData
import CoreResolve

public final class CloudKitContext: CoreWorkflowContext {
	
	// TODO: Decide if this is the best place (it reduces #if os()) and if it should be a var that's assigned by configuration
	public static let sharedEventsSubscriptionID: CKSubscription.ID = "friend-shared-event-changes"
    
    public var accountStatus: CKAccountStatus {
        get { return cloudKitManager.accountStatus }
    }
    
    public var currentUserRecordID: CKRecord.ID? {
        get { return cloudKitManager.currentUserRecordID }
    }
	
	public var linkedUserObjectID: NSManagedObjectID? {
		get { return cloudKitManager.linkedUserObjectID }
	}
    
    public var logger: CoreLoggingService {
        return cloudKitManager.configuration.loggingService
    }

    public var userDiscoverabilityPermissionStatus: CKContainer.ApplicationPermissionStatus {
        get { return cloudKitManager.userDiscoverabilityPermissionStatus }
     }
    
    private var errors = [Error]()
    
    public var error: Error? {
        get { return syncQueue.sync { errors.first } }
    }
    
    public func addError(_ error: Error) {
        syncQueue.sync(flags: .barrier) {
            errors.append(error)
        }
    }
    
    public var cloudContainer: CKContainer {
        return cloudKitManager.configuration.container
    }
	/*
    public typealias ContextKey = String

    public subscript(key: String) -> Any? {
        get { return syncQueue.sync { contextData[key] } }
        set { syncQueue.sync(flags: .barrier) { contextData[key] = newValue } }
    }

    private var contextData = Dictionary<ContextKey, Any>()
	*/
    init(with cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
    }
    
    private var cloudKitManager: CloudKitManager
    
    private var syncQueue = DispatchQueue(label: "\(CloudKitContext.self).syncQueue", attributes: .concurrent)
}
