//
//  AsynchronousDataOperationTests.swift
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

class AsynchronousDataOperationTests: XCTestCase {
	
	func testFinishHasContext() throws {
		let finishExpectation = expectation(description: "Calls finish")
		
		let context = TestDataWorkflowContext()
		let finishOperation = FinishDataOperation(with: context, dataService: self)
		finishOperation.addFinishClosure { operation in
			XCTAssertNil(operation.error)
			XCTAssertNotNil(operation.dataContext)
			finishExpectation.fulfill()
		}
		
		let operationQueue = OperationQueue()
		operationQueue.addOperation(finishOperation)
		
		waitForExpectations(timeout: 5.0, handler: nil)
		XCTAssertNil(finishOperation.error)
		XCTAssertNil(finishOperation.dataContext)
	}
	
	func testCancelHasNoContext() throws {
		let finishExpectation = expectation(description: "Calls finish")
		
		let context = TestDataWorkflowContext()
		let finishOperation = FinishDataWithCancelOperation(with: context, dataService: self)
		finishOperation.addFinishClosure { operation in
			XCTAssertNotNil(operation.error)
			XCTAssertNil(operation.dataContext)
			finishExpectation.fulfill()
		}
		finishOperation.cancel()
		
		let operationQueue = OperationQueue()
		operationQueue.addOperation(finishOperation)
		
		waitForExpectations(timeout: 5.0, handler: nil)
		XCTAssertNotNil(finishOperation.error)
		XCTAssertNil(finishOperation.dataContext)
	}
}

extension AsynchronousDataOperationTests: CoreDataService {
	
	var viewContext: NSManagedObjectContext {
		fatalError()
	}
	
	func perform(_ closure: @escaping (NSManagedObjectContext) -> Void) {
		// Do nothing
	}
	
	func performAndWait(_ closure: (NSManagedObjectContext) -> Void) {
		// Do nothing
	}
}

extension AsynchronousDataOperationTests: CoreServiceProviding {
	
	func access<T>(_ serviceType: T.Type) throws -> T {
		return self as! T
	}
	
	func accessIfLoaded<T>(_ serviceType: T.Type) -> T? {
		return self as? T
	}
	
	func releaseUnusedServices() {
		// Do nothing
	}
}

// MARK: - Subject classes

fileprivate class FinishDataOperation: AsynchronousDataOperation<TestDataWorkflowContext> {
	
	override func main() {
		finish(withContext: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType))
	}
}

fileprivate class FinishDataWithCancelOperation: AsynchronousDataOperation<TestDataWorkflowContext> {
	
	override func main() {
		cancel()
		finish(withContext: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType))
	}
}

// MARK: - Supporting classes

private class TestDataWorkflowContext: CoreWorkflowContext {
	
	var error: Error?
	
	func addError(_ error: Error) {
		self.error = error
	}
}
