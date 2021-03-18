//
//  ResourceManagerTests.swift
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

class ResourceManagerTests: XCTestCase {
	
	public var currentResourceManager: ResourceManager<ResourceManagerTests>!
	
	override func tearDown() {
		super.tearDown()
		currentResourceManager = nil
	}
    
	func testFactoryConstructor() {
		let resourceManager = standardInitialization()
		var built: Any?
		XCTAssertNoThrow(built = try resourceManager.make(FactoryA.self))
		XCTAssertNotNil(built)
		XCTAssert(built is FactoryA)
	}

	func testFactoryRecursion() {
		let resourceManager = recursiveInitialization()
		var built: FactoryB?
		XCTAssertNoThrow(built = try resourceManager.make(FactoryB.self))
		XCTAssertNotNil(built)
		XCTAssertNotNil(built!.factoryA)
	}
	
	func testFactoryDuplication() {
		let resourceManager = standardInitialization()
		var built1: FactoryA?
		XCTAssertNoThrow(built1 = try resourceManager.make(FactoryA.self))
		XCTAssertNotNil(built1)
		var built2: FactoryA?
		XCTAssertNoThrow(built2 = try resourceManager.make(FactoryA.self))
		XCTAssertNotNil(built2)
		XCTAssert(built1!.instanceCount != built2!.instanceCount)
	}
	
	// TODO: Figure out how to test ResolveKit.ResourceManagerError.managerNotPresent (threading?)
	
	func testFactoryInitException() {
		let resourceManager = standardInitialization()
		XCTAssertThrowsError(try resourceManager.make(FactoryB.self)) { (error) -> Void in
			guard case CoreResolve.CoreFactoryServiceError.initializationFailure(let underlyingError) = error else {
				XCTFail("Unexpected error: \(error)")
				return
			}
			guard case FactoryB.FactoryBError.initializationError = underlyingError else {
				XCTFail("Unexpected underlying error: \(underlyingError)")
				return
			}
		}
	}
	
	func testFactoryRegistrationException() {
		let resourceManager = standardInitialization()
		XCTAssertThrowsError(try resourceManager.make(FactoryC.self)) { (error) -> Void in
			guard case CoreResolve.CoreFactoryServiceError.unregisteredFactory = error else {
				XCTFail("Unexpected error: \(error)")
				return
			}
		}
	}
	
	// TODO: Find out how to test locking (e.g. Thread B can't initialize Factory B until Thead A's initialization of Factory A is done)
	
	func testServiceConstructor() {
		let resourceManager = standardInitialization()
		var service: Any?
		XCTAssertNoThrow(service = try resourceManager.access(ServiceA.self))
		XCTAssertNotNil(service)
		XCTAssert(service is ServiceA)
	}
	
	func testServiceNotLoaded() {
		let resourceManager = standardInitialization()
		var service: Any?
		XCTAssertNoThrow(service = resourceManager.accessIfLoaded(ServiceA.self))
		XCTAssertNil(service)
	}
	
	func testServiceRecursion() {
		let resourceManager = recursiveInitialization()
		var serviceB: ServiceB?
		XCTAssertNoThrow(serviceB = try resourceManager.access(ServiceB.self))
		XCTAssertNotNil(serviceB)
		XCTAssertNotNil(serviceB!.serviceA)
	}
	
	func testServiceNonDuplication() {
		let resourceManager = standardInitialization()
		var service1: ServiceA?
		XCTAssertNoThrow(service1 = try resourceManager.access(ServiceA.self))
		XCTAssertNotNil(service1)
		resourceManager.releaseUnusedServices()
		var service2: ServiceA?
		XCTAssertNoThrow(service2 = try resourceManager.access(ServiceA.self))
		XCTAssertNotNil(service2)
		XCTAssert(service1!.instanceCount == service2!.instanceCount)
	}
	
	// TODO: Figure out how to test ResolveKit.ResourceManagerError.managerNotPresent (threading?)
	
	func testServiceInitException() {
		let resourceManager = standardInitialization()
		XCTAssertThrowsError(try resourceManager.access(ServiceB.self)) { (error) -> Void in
			guard case CoreResolve.CoreServiceProvidingError.initializationFailure(let underlyingError) = error else {
				XCTFail("Unexpected error: \(error)")
				return
			}
			guard case ServiceB.ServiceBError.initializationError = underlyingError else {
				XCTFail("Unexpected underlying error: \(underlyingError)")
				return
			}
		}
	}
	
	func testServiceRegistrationException() {
		let resourceManager = standardInitialization()
		XCTAssertThrowsError(try resourceManager.access(ServiceC.self)) { (error) -> Void in
			guard case CoreResolve.CoreServiceProvidingError.unregisteredService = error else {
				XCTFail("Unexpected error: \(error)")
				return
			}
		}
	}
	
	// TODO: Find out how to test locking (e.g. Thread B can't initialize Service B until Thead A's initialization of Service A is done)
	
	func recursiveInitialization() -> ResourceManager<ResourceManagerTests> {
		let resourceManager = ResourceManager<ResourceManagerTests>(context: self)
		resourceManager.registerFactory(FactoryA.self) {
			XCTAssert($0 === self)
			return FactoryA()
		}
		resourceManager.registerFactory(FactoryB.self) {
			return try FactoryB(context: $0)
		}
		resourceManager.registerService(ServiceA.self) {
			XCTAssert($0 === self)
			return ServiceA()
		}
		resourceManager.registerService(ServiceB.self) {
			return try ServiceB(context: $0)
		}
		currentResourceManager = resourceManager
		return resourceManager
	}
	
	func standardInitialization() -> ResourceManager<ResourceManagerTests> {
		let resourceManager = ResourceManager<ResourceManagerTests>(context: self)
		resourceManager.registerFactory(FactoryA.self) {
			XCTAssert($0 === self)
			return FactoryA()
		}
		resourceManager.registerFactory(FactoryB.self) {
			XCTAssert($0 === self)
			return try FactoryB()
		}
		resourceManager.registerService(ServiceA.self) {
			XCTAssert($0 === self)
			return ServiceA()
		}
		resourceManager.registerService(ServiceB.self) {
			XCTAssert($0 === self)
			return try ServiceB()
		}
		currentResourceManager = resourceManager
		return resourceManager
	}
}

// MARK: - Subject classes

fileprivate class FactoryA {
	
	private static var internalInstanceCount: Int = 0
	let instanceCount: Int
	
	init() {
		FactoryA.internalInstanceCount += 1
		instanceCount = FactoryA.internalInstanceCount
	}
}

fileprivate class FactoryB {
	
	public enum FactoryBError: Error {
		case initializationError
	}
	
	init() throws {
		throw FactoryBError.initializationError
	}
	
	public var factoryA: FactoryA?
	
	public init(context: ResourceManagerTests) throws {
		factoryA = try context.currentResourceManager.make(FactoryA.self)
	}
}

fileprivate class FactoryC {
	
}

fileprivate protocol ServiceAProtocol {
	
	var instanceCount: Int { get }
}

fileprivate class ServiceA: ServiceAProtocol {
	
	private static var internalInstanceCount: Int = 0
	let instanceCount: Int
	
	init() {
		ServiceA.internalInstanceCount += 1
		instanceCount = ServiceA.internalInstanceCount
	}
}

fileprivate class ServiceB {
	
	public enum ServiceBError: Error {
		case initializationError
	}
	
	init() throws {
		throw ServiceBError.initializationError
	}
	
	public var serviceA: ServiceA?
	
	public init(context: ResourceManagerTests) throws {
		serviceA = try context.currentResourceManager.access(ServiceA.self)
	}
}

fileprivate class ServiceC {
	
}
