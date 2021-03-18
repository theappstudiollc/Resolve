//
//  CoreWorkflowOperation.swift
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

import CoreResolve

public protocol CoreWorkflowContext {
	
	var error: Error? { get }
	
	func addError(_ error: Error)
}

public protocol CoreWorkflowOperation: ProgressReporting {
	
	associatedtype WorkflowContext: CoreWorkflowContext
	
	var error: Error? { get }
	
	// With proper linking API, maybe this should not be necessary
	var shouldCancelOnContextError: Bool { get }
	
	var workflowContext: WorkflowContext { get }
}

public class CoreWorkflowOperationManager<WorkflowContext> where WorkflowContext: CoreWorkflowContext {
	
	typealias WorkflowCompletion = (Result<WorkflowContext, Error>) -> Void
	
	@discardableResult internal func start<TOperation: Operation & CoreAsynchronousOperationLinking & CoreWorkflowOperation>(operations: [TOperation], in operationQueue: OperationQueue, with context: WorkflowContext, for completionHandler: @escaping WorkflowCompletion) -> Operation {
		
		let retVal = BlockOperation {
			if let error = context.error {
				completionHandler(.failure(error))
			} else if let error = operations.first(where: { $0.error != nil })?.error {
				completionHandler(.failure(error))
			} else {
				completionHandler(.success(context))
			}
		}
		for operation in operations {
			retVal.addDependency(operation)
			/* This lets us ensure no operation begins without verifying a precondition
			let observer = operation.observe(\.isExecuting, options: .new) { wOperation, isExecuting in
				guard isExecuting.newValue == true else { return }
				precondition(!wOperation.shouldCancelOnContextError || wOperation.workflowContext.error == nil, " :: \(type(of: wOperation)) not cancelled!")
			}
			*/
//			operation.name = "\(self) \(operation.self)"
			// TODO: Determine if we need to set this, or allow more sophisticated behaviors
//			operation.qualityOfService = operationQueue.qualityOfService
		}
		operationQueue.addOperation(retVal)
		operationQueue.addOperations(operations, waitUntilFinished: false)
		return retVal
	}
}
