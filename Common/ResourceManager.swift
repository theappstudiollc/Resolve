//
//  ResourceManager.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2017 The App Studio LLC.
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

/// Merges the Swift variants of service resolving and factory service
public protocol ResourceManaging: CoreFactoryService, CoreServiceProviding { }

/// Merges the Swift variants of service and factory configuring
public protocol ResourceConfiguring: CoreFactoryConfiguring, CoreServiceConfiguring { }

/// Manages resources such as Services and Factories needing a TContext. All methods are thread-safe and re-entrancy is supported
public final class ResourceManager<Context>: ResourceManaging, ResourceConfiguring {
	
	/// `Context` object that is passed into the closures during resource initialization
	public let context: Context
	
	/// Initializes a new ResourceManager with the `Context` used during resource creation/initialization
	public init(context: Context) {
		self.context = context
	}
	
	/// Accesses a service that implements the requested protocol
	///
	/// - Parameter serviceType: Type of the service desired. e.g. SoundEffectsService.self
	/// - Returns: Returns the concrete implementation of the requested service
	/// - Throws: Throws a ResourceManagerError, CoreServiceResolvingError, or implementation-specific error
	public func access<T>(_ serviceType: T.Type) throws -> T {
		serviceLock.lock()
		defer { serviceLock.unlock() }
		let serviceIdentifier = identifier(forType: serviceType)
		return try serviceManager.resolveService(withIdentifier: serviceIdentifier) as! T
	}
	
	/// Accesses a service that implements the requested protocol, if and only if it is still loaded in memory
	///
	/// - Parameter serviceType: Type of the service desired. e.g. SoundEffectsService.self
	/// - Returns: Returns the concrete implementation of the requested service, if it is still loaded in memory
	public func accessIfLoaded<T>(_ serviceType: T.Type) -> T? {
		serviceLock.lock()
		defer { serviceLock.unlock() }
		let serviceIdentifier = identifier(forType: serviceType)
		return serviceManager.resolveServiceIfLoaded(withIdentifier: serviceIdentifier) as? T
	}
	
	/// Makes the requested object type
	///
	/// - Parameter objectType: Type of the object desired. e.g. MainViewModel.self
	/// - Returns: Returns the requested object type
	/// - Throws: Throws a ResourceManagerError, CoreFactoryServiceError, or implementation-specific error
	public func make<T: Any>(_ objectType: T.Type) throws -> T {
		serviceLock.lock()
		defer { serviceLock.unlock() }
		let factoryIdentifier = identifier(forType: objectType)
		return try factoryRegistry.invokeFactory(withIdentifier: factoryIdentifier) as! T
	}
	
	/// Registers a factory for a given object type
	///
	/// - Parameters:
	///   - objectType: The type of object for which to register the factory
	///   - builder: The closure that will manufacture objects when invoked
	public func registerFactory<T: Any>(_ objectType: T.Type, withBuilder builder: @escaping (_ context: Context) throws -> T) {
		serviceLock.lock()
		defer { serviceLock.unlock() }
		factoryRegistry.registerFactory(withIdentifier: identifier(forType: objectType)) { [context] in
			return try builder(context)
		}
	}
	
	/// Registers an initializer for a given service type
	///
	/// - Parameters:
	///   - serviceType: The type of service for which to register the initializer
	///   - initializer: The closure that will initialize the service when requested
	public func registerService<T>(_ serviceType: T.Type, withInitializer initializer: @escaping (_ context: Context) throws -> T) {
		serviceLock.lock()
		defer { serviceLock.unlock() }
		serviceManager.registerService(withIdentifier: identifier(forType: serviceType)) { [context] in
			return try initializer(context)
		}
	}
	
	/// Releases any services that are not referenced by other code
	public func releaseUnusedServices() {
		serviceLock.lock()
		defer { serviceLock.unlock() }
		serviceManager.releaseUnusedServices()
	}
	
	/// Internal function exposed to class extensions (so that if ObjC support is not desired this capability is not unnecessarily exposed)
	internal func identifier(forType type: Any.Type) -> AnyHashable {
		return "\(type)".components(separatedBy: ".").last!
	}
	
	/// Provides CoreFactoryService capability
	internal let factoryRegistry = FactoryRegistry()
	/// Makes methods thread-safe and supports re-entrancy for services that depend on other services
	internal let serviceLock = NSRecursiveLock()
	/// Provides CoreServiceProviding capability
	internal let serviceManager = ServiceManager()
}
