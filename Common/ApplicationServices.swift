//
//  ApplicationServices.swift
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

import ResolveKit

/// Represents an error with the `ApplicationServices`
public enum ApplicationServicesError: Error {
	case cannotMapContext
}

/// Extends and configures the base Resolve services available to the app (not to the extensions, which must be subclassed separately)
final class ApplicationServices: ResolveServices {

	override func configureResources<Configurator>(with configurator: Configurator) where Configurator: ServiceContextConfiguring {
		super.configureResources(with: configurator)
		// Add Application-specific mappings
		configurator.registerService(NotificationService.self) {
			let loggingService = try Self.access(CoreLoggingService.self)
			let appDelegate = try $0.asResolveDelegate()
			return NotificationManager(notificationProvider: appDelegate.notificationProvider, loggingService: loggingService)
		}
		configurator.registerService(UserInputService.self) { _ in
			#if os(iOS) || os(tvOS)
			let multipeerSettings = try Self.access(MultipeerSettingsService.self)
			return UserInputManager(multipeerSettings: multipeerSettings)
			#else
			return UserInputManager()
			#endif
		}
		// Now add platform-specific mappings
		#if os(iOS) || os(tvOS)
		configurator.registerService(AppIconService.self) { _ in
			return AppIconManager(with: .shared)
		}
		#endif
		#if os(iOS) || os(watchOS)
		configurator.registerService(WatchSessionService.self) {
			return try $0.asResolveDelegate().watchSessionManager.get()
		}
		configurator.registerService(WatchSessionSettingsService.self) { _ in
			return WatchSessionSettingsManager()
		}
		#endif
		#if os(iOS)
		configurator.registerService(LocationManager.self) { _ in
			let notificationService = try Self.access(NotificationService.self)
			return LocationManager(with: notificationService)
		}
		#endif
		#if os(iOS)
		configurator.registerService(BeaconManager.self) { _ in
			let loggingService = try Self.access(CoreLoggingService.self)
			let notificationService = try Self.access(NotificationService.self)
			return BeaconManager(loggingService: loggingService, notificationService: notificationService)
		}
		#elseif os(macOS) || os(tvOS)
		configurator.registerService(BeaconAdvertiser.self) { _ in
			return BeaconAdvertiser()
		}
		#endif
		// Add services related to watchOS
		#if os(watchOS)
		configurator.registerService(ComplicationService.self) { _ in
			let settingsService = try Self.access(WatchSessionSettingsService.self)
			return ComplicationManager(settingsService: settingsService)
		}
		#endif
		// Add services related to MultipeerConnectivity
		#if canImport(MultipeerConnectivity)
		configurator.registerService(MultipeerSettingsService.self) { _ in
			return MultipeerSettingsManager()
		}
		configurator.registerService(ConversationService.self) {
			return try $0.asResolveDelegate().conversationManager.get()
		}
		#endif
		// Add UserActivity handling for iOS, macOS, and watchOS
		#if os(iOS) || os(macOS)
		configurator.registerService(UserActivityService.self) { _ in
			return UserActivityService(implementation: UserActivityManager())
		}
		#elseif os(watchOS) // watchOS needs to provide its app bundle, not the `.main` bundle
		configurator.registerService(UserActivityService.self) { _ in
			let watchAppBundle = try Bundle.watchAppBundle.get()
			return UserActivityService(implementation: UserActivityManager(with: watchAppBundle))
		}
		#endif
	}
}

fileprivate extension ServiceContext {

	func asResolveDelegate() throws -> ResolveDelegate {
		guard let result = self as? ResolveDelegate else {
			throw ApplicationServicesError.cannotMapContext
		}
		return result
	}
}
