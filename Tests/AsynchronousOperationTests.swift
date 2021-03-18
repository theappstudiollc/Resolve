//
//  AsynchronousOperationTests.swift
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

import XCTest
@testable import ResolveKit

class AsynchronousOperationTests: XCTestCase {
	
    func testFinishNoError() {
		let finishExpectation = expectation(description: "Calls finish")
		
		let context = TestWorkflowContext()
		let finishOperation = FinishOperation(with: context)
		finishOperation.addFinishClosure { operation in
			XCTAssertNil(operation.error)
			finishExpectation.fulfill()
		}
		
		let operationQueue = OperationQueue()
		operationQueue.addOperation(finishOperation)
		
		waitForExpectations(timeout: 5.0, handler: nil)
		XCTAssertNil(finishOperation.error)
    }
	
	func testFinishError() {
		let finishExpectation = expectation(description: "Calls finish")
		
		let context = TestWorkflowContext()
		let finishWithErrorOperation = FinishWithErrorOperation(with: context, reportingError: TestAsynchronousOperationError.testError)
		finishWithErrorOperation.addFinishClosure { operation in
			XCTAssertNotNil(operation.error)
			guard case TestAsynchronousOperationError.testError = operation.error! else {
				XCTFail("Unexpected error: \(operation.error!)")
				return
			}
			finishExpectation.fulfill()
		}
		
		let operationQueue = OperationQueue()
		operationQueue.addOperation(finishWithErrorOperation)
		
		waitForExpectations(timeout: 5.0, handler: nil)
		XCTAssertNotNil(finishWithErrorOperation.error)
	}
	
	func testCancelError() {
		let finishExpectation = expectation(description: "Calls finish")
		
		let context = TestWorkflowContext()
		let finishOperation = FinishOperation(with: context)
		finishOperation.addFinishClosure { operation in
			XCTAssertNotNil(operation.error)
			guard case AsynchronousOperationError.cancelled(let error) = operation.error! else {
				XCTFail("Unexpected error: \(operation.error!)")
				return
			}
			XCTAssertNil(error)
			finishExpectation.fulfill()
		}
		finishOperation.cancel()
		
		let operationQueue = OperationQueue()
		operationQueue.addOperation(finishOperation)
		
		waitForExpectations(timeout: 5.0, handler: nil)
		XCTAssertNotNil(finishOperation.error)
	}
	
	func testCancelWrapsError() {
		let finishExpectation = expectation(description: "Calls finish")
		
		let context = TestWorkflowContext()
		let finishWithCancelOperation = FinishWithCancelOperation(with: context, reportingError: TestAsynchronousOperationError.testError)
		finishWithCancelOperation.addFinishClosure { operation in
			XCTAssertNotNil(operation.error)
			guard case AsynchronousOperationError.cancelled(let error) = operation.error! else {
				XCTFail("Unexpected error: \(operation.error!)")
				return
			}
			XCTAssertNotNil(error)
			guard case TestAsynchronousOperationError.testError = error! else {
				XCTFail("Unexpected error: \(error!)")
				return
			}
			finishExpectation.fulfill()
		}
		
		let operationQueue = OperationQueue()
		operationQueue.addOperation(finishWithCancelOperation)
		
		waitForExpectations(timeout: 5.0, handler: nil)
		XCTAssertNotNil(finishWithCancelOperation.error)
	}
}

// MARK: - Subject classes

fileprivate enum TestAsynchronousOperationError: Error {
	case testError
}

fileprivate class FinishOperation: AsynchronousWorkflowOperation<TestWorkflowContext> {
	
	override func main() {
		finish()
	}
}

fileprivate class FinishWithErrorOperation: AsynchronousWorkflowOperation<TestWorkflowContext> {
	
	private var internalError: Error!
	
	required init(with context: TestWorkflowContext, reportingError error: Error) {
		internalError = error
		super.init(with: context)
	}
	
	override func main() {
		finish(withError: internalError)
	}
}

fileprivate class FinishWithCancelOperation: AsynchronousWorkflowOperation<TestWorkflowContext> {
	
	private var internalError: Error!
	
	required init(with context: TestWorkflowContext, reportingError error: Error) {
		internalError = error
		super.init(with: context)
	}
	
	override func main() {
		cancel()
		finish(withError: internalError)
	}
}

// MARK: - Supporting classes

private class TestWorkflowContext: CoreWorkflowContext {
	
	var error: Error?
	
	func addError(_ error: Error) {
		self.error = error
	}
}
