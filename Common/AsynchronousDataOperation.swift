//
//  AsynchronousDataOperation.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2018 The App Studio LLC.
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

import CoreData
import CoreResolve

/// An AsynchronousOperation subclass that provides a way for finish closures to utilize a ManagedObjectContext used by the operation
open class AsynchronousDataOperation<TWorkflowContext>: AsynchronousWorkflowOperation<TWorkflowContext> where TWorkflowContext: CoreWorkflowContext {

	/// The CoreDataService to be used by the Operation
	public private(set) var dataService: CoreDataService!
	
	/// A ManagedObjectContext that is accessible only during a finish closure when there is no error and the operation has not been cancelled
	public private(set) var dataContext: NSManagedObjectContext?
	
	/// Complete the operation if you want finish closures to access the same context used by the operation. All paths, including cancellation, must lead to finish, otherwise the operation will forever consume its operation queue. This class' implementation of `start` already calls `finish` if the operation is cancelled before it begins
	///
	/// - Parameter context: A context to pass to finish closures so that they may perform additional work. Callers are expected to call finish(withContext:) within a perform or performAndWait closure
	open func finish(withContext context: NSManagedObjectContext) {
		dataContext = isCancelled ? nil : context
		super.finish()
		dataContext = nil
	}
	
	/// Initializes a new instance of the operation with a workflow context and data service
	///
	/// - Parameter workflowContext: The WorkflowContext
	/// - Parameter dataService: The CoreDataService implementation that will access Core Data
	public init(with workflowContext: WorkflowContext, dataService: CoreDataService) {
		self.dataService = dataService
		super.init(with: workflowContext)
	}
}
