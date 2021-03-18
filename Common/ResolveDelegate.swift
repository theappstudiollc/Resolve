//
//  ResolveDelegate.swift
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

import ResolveKit

#if os(iOS) || os(tvOS)
	typealias DelegateBase = UIResponder
#elseif os(macOS) || os(watchOS)
	typealias DelegateBase = NSObject
#endif

/// Base class for Resolve application delegates, which subclasses `DelegateBase`, a type which depends on the platform
class ResolveDelegate: DelegateBase, ServiceContext {

	@Service var loggingService: CoreLoggingService

	// MARK: - ContextBase overrides

	override init() {
		super.init()
		services = ApplicationServices(context: self)
	}

	// MARK: - Private properties and methods

	private var services: ApplicationServices!

	// Managers and Providers that we want to keep around once loaded, as well as access directly elsewhere

	#if canImport(MultipeerConnectivity)

	internal lazy var conversationManager: Result<MultipeerConversationManager, Error> = {
		do {
			let fileStoreService = try Services.access(CoreFileStoreService.self)
			let settingsService = try Services.access(MultipeerSettingsService.self)
			let result = MultipeerConversationManager(fileStoreService: fileStoreService, settingsService: settingsService)
			result.delegate = self
			return .success(result)
		} catch {
			return .failure(error)
		}
	}()

	#endif

	internal lazy var notificationProvider: NotificationService.Provider = {
		#if os(watchOS)
			return UserNotificationManager(application: Application.shared())
		#elseif os(tvOS)
			return UserNotificationManager(application: Application.shared)
		#else
			guard #available(iOS 10.0, macOS 10.14, *) else {
				return LegacyUserNotificationManager(application: Application.shared)
			}
			return UserNotificationManager(application: Application.shared)
		#endif
	}()

	#if os(iOS) || os(watchOS)

	internal lazy var watchSessionManager: Result<WatchSessionManager, Error> = {
		do {
			let dataService = try Services.access(CoreDataService.self)
			let settingsService = try Services.access(WatchSessionSettingsService.self)
			return .success(WatchSessionManager(dataService: dataService, loggingService: loggingService, settingsService: settingsService))
		} catch {
			return .failure(error)
		}
	}()

	#endif
}
