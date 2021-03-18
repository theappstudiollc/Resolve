//
//  PlatformServices.swift
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

import Foundation

/// Base class that provides all Services in the project
open class Services {

	internal static var resourceManager: ResourceManaging!

	public class func releaseUnusedServices() {
		resourceManager.releaseUnusedServices()
	}

	public class func access<T: Any>(_ serviceType: T.Type) throws -> T {
		return try resourceManager.access(serviceType)
	}

	public class func accessIfLoaded<T: Any>(_ serviceType: T.Type) -> T? {
		return resourceManager.accessIfLoaded(serviceType)
	}

	public class func make<T: Any>(_ objectType: T.Type) throws -> T {
		return try resourceManager.make(objectType)
	}
}

@propertyWrapper
/// Provides a getter for a service configured by the Context. Will bring down the app if not configured.
public struct Service<T> where T: Any {

	public init() { }

	public var wrappedValue: T {
		do {
			return try Services.access(T.self)
		} catch {
			fatalError("`Services.swift` access error for \(T.self): \(error)")
		}
	}
}

@propertyWrapper
public struct OptionalService<T> where T: Any {

	public init() { }

	public var wrappedValue: T? {
		return try? Services.access(T.self)
	}
}
