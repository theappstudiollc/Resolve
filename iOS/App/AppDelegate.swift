//
//  AppDelegate.swift
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

import CoreLocation
import Intents
import ResolveKit

#if targetEnvironment(macCatalyst)

internal typealias EnvironmentAppDelegate = UIKitAppDelegate

#else

internal class EnvironmentAppDelegate: UIKitAppDelegate {
	
	private var beaconManager: BeaconManager!
	private var locationProvider: LocationManager!

	// MARK: - Context overrides
	
	@available(iOS, deprecated: 10.0)
	override func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
		super.application(application, didReceive: notification)
		guard let legacyProvider = notificationProvider as? LegacyUserNotificationManager else { return }
		legacyProvider.handleLocalNotification(notification)
	}
	
	@available(iOS, deprecated: 10.0)
	func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
		guard let legacyProvider = notificationProvider as? LegacyUserNotificationManager else { return }
		legacyProvider.handleRegistrationSuccess(notificationSettings)
	}

	override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
		try! watchSessionManager.get().activate()
		return result
	}
	
	override func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		// We want these two to load as soon as the app starts -- and we want them to persist throughout its lifetime
		beaconManager = try! Services.access(BeaconManager.self)
		locationProvider = try! Services.access(LocationManager.self)
		return super.application(application, willFinishLaunchingWithOptions: launchOptions)
	}
}

#endif

@UIApplicationMain final class AppDelegate: EnvironmentAppDelegate {

	override func applicationDidBecomeActive(_ application: UIApplication) {
		super.applicationDidBecomeActive(application)
		let notificationService = try! Services.access(NotificationService.self)
		notificationService.clearBeaconNotifications()
		if #available(iOS 10.0, *), INPreferences.siriAuthorizationStatus() == .notDetermined {
			INPreferences.requestSiriAuthorization { [loggingService] status in
				loggingService.debug("Siri authorization status = %{public}@", "\(status.rawValue)")
			}
		}
	}

	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		notificationProvider.remoteTokenRegistrationFailed(error)
	}
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		notificationProvider.remoteTokenRegistrationSucceeded(deviceToken)
	}
}
