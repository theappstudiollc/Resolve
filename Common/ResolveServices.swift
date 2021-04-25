//
//  ResolveServices.swift
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

import CoreResolve

/// Tags a class as able to serve as a Resolve Service Context
public protocol ServiceContext: AnyObject { }

/// Represents a `ResourceConfiguring` entity that configures services with a `ServiceContext`
public protocol ServiceContextConfiguring: ResourceConfiguring where Context == ServiceContext { }

/// Marks `ResourceManager` as implementing `ServiceContextConfiguring`
extension ResourceManager: ServiceContextConfiguring where Context == ServiceContext { }

/// Manages all the services needed by a `Resolve` application and its extensions
open class ResolveServices: Services {

	// MARK: - Public properties and methods

	public let resourceManager: ResourceManager<ServiceContext>

	public required init(context: ServiceContext) {
		resourceManager = ResourceManager(context: context)
		super.init()
		Self.resourceManager = resourceManager
		configureResources(with: resourceManager)
	}

	open func configureResources<Configurator>(with configurator: Configurator) where Configurator: ServiceContextConfiguring {
		// Now add common service mappings
		configurator.registerService(AppInfoService.self) {
			let bundle = Bundle(for: type(of: $0))
			return AppInfoManager(applicationBundle: bundle)
		}
		configurator.registerService(CoreDataService.self) { _ in
			return try Self.access(DataService.self)
		}
		configurator.registerService(DataService.self) { _ in
			let fileStoreService = try Self.access(CoreFileStoreService.self)
			let configurationProvider = try ResolveKitCoreDataConfigurationProvider(fileStoreService: fileStoreService)
			let stack: CoreDataStack
			if #available(iOS 10.3, macOS 10.12.6, tvOS 10.3, *) {
				stack = try ResolveKitCoreDataStack(configurationProvider: configurationProvider)
			} else {
				// Work around an NSFetchedResultsController bug that is present in iOS & tvOS 9.x by using multiple coordinators
				// (also assuming the equivalent macOS had the same problem)
				stack = try MultiCoordinatorSynchronouslyMergingCoreDataStack(configurationProvider: configurationProvider)
			}
			return DataManager(stack: stack)
		}
		configurator.registerService(CoreFileStoreService.self) {
			let bundle = Bundle(for: type(of: $0))
			let urlProvider: CoreFileStoreManagerUrlProviding
			#if os(iOS) || os(watchOS)
				urlProvider = AppGroupFileStoreManagerUrlProvider(applicationBundle: bundle, appGroupProvider: self)
			#else
				urlProvider = FileStoreManagerUrlProvider(applicationBundle: bundle)
			#endif
			return FileStoreManager(urlProvider: urlProvider)
		}
		configurator.registerService(CoreLoggingService.self) {
			let bundle = Bundle(for: type(of: $0))
			let configurationProvider = LogManagerConfigurationProvider(bundle: bundle)
			return LogManager(configurationProvider: configurationProvider)
		}
		// Add services related to CloudKitService
		configurator.registerService(CloudKitService.self) {
			let bundle = Bundle(for: type(of: $0))
			let configurationProvider = LogManagerConfigurationProvider(bundle: bundle, category: "CloudKitService")
			let loggingService = LogManager(configurationProvider: configurationProvider)
			let configuration = CloudKitManagerConfigurationProvider(with: "iCloud.\(Self.resolveAppBundleIdentifier)", resourceManager: Self.resourceManager, loggingService: loggingService)
			return CloudKitManager(configuration: configuration)
		}
		configurator.registerService(CloudKitSettingsService.self) { _ in
			#if os(iOS) || os(watchOS)
			return CloudKitSettingsManager(userDefaults: self.appGroupDefaults)
			#else
			return CloudKitSettingsManager()
			#endif
		}
		configurator.registerService(CoreDataSettingsService.self) { _ in
			#if os(iOS) || os(watchOS)
			return CoreDataSettingsManager(userDefaults: self.appGroupDefaults)
			#else
			return CoreDataSettingsManager()
			#endif
		}
		configurator.registerService(AppUserService.self) { _ in
			let dataService = try Self.access(CoreDataService.self)
			let loggingService = try Self.access(CoreLoggingService.self)
			let settings = try Self.access(CoreDataSettingsService.self)
			return AppUserManager(dataService: dataService, loggingService: loggingService, settings: settings)
		}
	}
}

#if os(iOS) || os(watchOS) // TODO: This capability may extend to other platforms as needed

/// iOS & watchOS apps and extensions utilize App Groups to share resources
extension Services: AppGroupProviding {

	// Use the standard "shared" app group (we can have more than one)
	private static var sharedAppGroupIdentifier = "group.\(resolveAppBundleIdentifier).shared"

	public var appGroupContainer: URL {
		return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.sharedAppGroupIdentifier)!
	}

	public var appGroupDefaults: UserDefaults {
		return UserDefaults(suiteName: Self.sharedAppGroupIdentifier)!
	}

	public var appGroupCookies: HTTPCookieStorage {
		return HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: Self.sharedAppGroupIdentifier)
	}
}

#endif

fileprivate extension Services {

	class var resolveAppBundleIdentifier: String {
		// We're expecting the following key in the 'ResolveKit' bundle
		let bundle = Bundle(for: Services.self)
		let key = "ResolveAppBundleIdentifier"
		return bundle.object(forInfoDictionaryKey: key) as! String
	}
}
