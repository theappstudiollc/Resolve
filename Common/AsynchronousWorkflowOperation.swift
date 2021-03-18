//
//  AsynchronousWorkflowOperation.swift
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

import CoreResolve

/// Error describing the reason for failures with the AsynchronousWorkflowOperation
///
/// - cancelled: The operation was cancelled, with an optional error representing a possible error caused by the cancel
public enum AsynchronousOperationError: Error {
	case cancelled(error: Error?)
}

/// An AsynchronousOperation subclass that provides a consistent way to set operation errors
open class AsynchronousWorkflowOperation<TWorkflowContext>: CoreAsynchronousOperation, CoreWorkflowOperation where TWorkflowContext: CoreWorkflowContext {
	
	/// Initializes a new instance of the operation with a workflow context
	///
	/// - Parameter workflowContext: The WorkflowContext
	public init(with workflowContext: TWorkflowContext) {
		self.workflowContext = workflowContext
		super.init()
	}
	
	// MARK: - Public properties -
	
	/// An Error encountered during the processing of the operation, if reported by the subclass. This may be an AsynchronousOperationError.cancelled(error:) if the operation was cancelled
	public private(set) var error: Error?
	
	open lazy var progress: Progress = {
		let retVal = Progress(totalUnitCount: -1)
		retVal.cancellationHandler = { [weak self] in
			self?.cancel()
		}
		return retVal
	}()

	open var shouldCancelOnContextError: Bool {
		return true
	}
	
	public var workflowContext: TWorkflowContext
	
	// MARK: - Public methods -

	/// Complete the operation. All paths, including cancellation, must lead to finish, otherwise the operation will forever consume its operation queue. This class' implementation of `start` already calls `finish` if the operation is cancelled before it begins
	override open func finish() {
		if isCancelled {
			error = AsynchronousOperationError.cancelled(error: nil)
		}
		finishProgress()
		super.finish()
	}
	
	/// Complete the operation and report an Error. All paths, including cancellation, must lead to finish, otherwise the operation will forever consume its operation queue. This class' implementation of `start` already calls `finish` if the operation is cancelled before it begins
	///
	/// - Parameter error: An error to report if one is encountered during the processing of the operation
	open func finish(withError error: Error) {
		if isCancelled {
			self.error = AsynchronousOperationError.cancelled(error: error)
		} else {
			workflowContext.addError(error)
			self.error = error
		}
		finishProgress()
		super.finish()
	}
	
	// MARK: - Private methods -
	
	func finishProgress() {
		if progress.totalUnitCount <= 0 {
			progress.totalUnitCount = 1
		}
		progress.completedUnitCount = progress.totalUnitCount
	}
}
