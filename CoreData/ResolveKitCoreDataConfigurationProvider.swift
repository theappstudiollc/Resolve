//
//  ResolveKitCoreDataConfigurationProvider.swift
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

/// Extends the CoreDataConfigurationProvider protocol, which configures the CoreData stack for the app and its extensions that share an App Group
public final class ResolveKitCoreDataConfigurationProvider: BasicSQLiteCoreDataStackConfigurationProvider {
	
	// MARK: - BasicSQLiteCoreDataStackConfigurationProvider overrides
	
	public init(fileStoreService: CoreFileStoreService) throws {
		#if os(tvOS)
		let dataStoreDirectoryType = CoreFileStoreDirectoryType.cache
		#else
		let dataStoreDirectoryType = CoreFileStoreDirectoryType.applicationData
		#endif
		try super.init(fileStoreService: fileStoreService, resourceName: "ResolveKit", resourceBundle: Bundle(for: Self.self), configurationName: "App", dataStoreDirectoryType: dataStoreDirectoryType, dataStoreFileName: "ResolveApp")
		#if os(iOS) || os(watchOS)
		try fileStoreService.ensureDirectoryExists(for: .appGroupApplicationData)
		#endif
	}
	
	/// The array of configurations by name in our CoreData model, including the extension configuration
	public override var configurations: [String]? {
		let retVal = [sharedConfiguration]
		guard let baseConfigurations = super.configurations, baseConfigurations.count > 0 else {
			return retVal
		}
		return baseConfigurations + retVal
	}
	
	/// Returns a dictionary of NSPersistentStore options, including the extension configuration
	///
	/// - Parameter configuration: The configuration as named in the `configurations` array
	/// - Returns: A dictionary of NSPersistentStore options
	public override func persistentStoreOptions(forConfiguration configuration: String?) -> [AnyHashable : Any]? {
		guard configuration == sharedConfiguration else {
			return super.persistentStoreOptions(forConfiguration: configuration)
		}
		return [NSMigratePersistentStoresAutomaticallyOption: true,
				NSInferMappingModelAutomaticallyOption: true]
	}
	
	/// Returns the CoreData persistent store type
	///
	/// - Parameter configuration: The configuration as named in the `configurations` array
	/// - Returns: The CoreDataManagerPersistentStoreType representing the persistent store type
	public override func persistentStoreType(forConfiguration configuration: String?) throws -> CoreDataStackPersistentStoreType {
		if let configuration = configuration, configuration == sharedConfiguration {
			#if os(iOS) || os(watchOS)
			let sharedDataStoreUrl = try fileStoreService.directoryUrl(for: .appGroupApplicationData)
			#else
			let sharedDataStoreUrl = try fileStoreService.directoryUrl(for: dataStoreDirectoryType)
			#endif
			let dataStoreUrl = URL(fileURLWithPath: "\(sharedFileName).sqlite", relativeTo: sharedDataStoreUrl)
			return .sqlite(fileStoreUrl: dataStoreUrl)
		}
		return try super.persistentStoreType(forConfiguration: configuration)
	}
	
	// MARK: - Private properties and methods
	
	/// The name of the configuration as defined in the xcdatamodeld
	private let sharedConfiguration = "Shared"
	
	/// The name of the .sqlite file that will represent the shared configuration
	private let sharedFileName = "ResolveShared"
}
