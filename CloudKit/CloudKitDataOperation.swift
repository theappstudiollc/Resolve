//
//  CloudKitDataOperation.swift
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

internal class CloudKitDataOperation: AsynchronousDataOperation<CloudKitContext> {
	
	internal var loggingService: CoreLoggingService
	
	public init(with workflowContext: CloudKitContext, dataService: CoreDataService, loggingService: CoreLoggingService) {
		self.loggingService = loggingService
		super.init(with: workflowContext, dataService: dataService)
	}
}
