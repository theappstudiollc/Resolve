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

import Cocoa
import CloudKit
import ResolveKit

@NSApplicationMain final class AppDelegate: ResolveDelegate, NSApplicationDelegate {

	// MARK: - NSApplicationDelegate properties and methods

	func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
		guard let userActivityService = try? Services.access(UserActivityService.self) else {
			return false
		}
		switch userActivityService.userActivityType(with: userActivity.activityType) {
		case .appSpecific:
			guard let mainWindowController = mainWindowController(for: application) else { return false }
			loggingService.debug("Continuing user activity: %{public}@", userActivity.activityType)
			restorationHandler([mainWindowController])
			return true
		case .browsingWeb, .queryContinuation, .searchableItem:
			return false
		case .unknown:
			fatalError("Unknown activity type: \(userActivity.activityType)")
		}
	}

	func application(_ application: NSApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
		let loggingService = try! Services.access(CoreLoggingService.self)
		loggingService.log(.error, "Failed to continue user activity `%{public}@`: %{public}@", userActivityType, error.localizedDescription)
	}

	func applicationDidBecomeActive(_ notification: Notification) {
		let userService = try! Services.access(AppUserService.self)
		userService.establishUser { [loggingService] success in
			loggingService.log(.info, "Establish User: %{public}@", success ? "success" : "failed")
			guard success else { return }
			let cloudKitService = try! Services.access(CloudKitService.self)
			// If it has been at least 14 days since the last .fullSync, perform one. Otherwise perform .default
			let diff = Calendar.current.dateComponents([.day], from: cloudKitService.lastFullSync, to: Date())
			let syncOptions: CloudKitServiceSyncOptions = diff.day == nil || diff.day! > 14 ? .fullSync : .default
			cloudKitService.synchronize(syncOptions: syncOptions, qualityOfService: .userInitiated, nil)
		}
	}
	
	func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		notificationProvider.remoteTokenRegistrationFailed(error)
	}

	func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		notificationProvider.remoteTokenRegistrationSucceeded(deviceToken)
	}

	func application(_ application: NSApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {

		// Return false if we want macOS to do the work of notifying the user
		guard let userActivityService = try? Services.access(UserActivityService.self) else {
			return false
		}
		switch userActivityService.userActivityType(with: userActivityType) {
		case .appSpecific:
			loggingService.debug("Will continue user activity with type: %{public}@", userActivityType)
			return false
		case .browsingWeb, .queryContinuation, .searchableItem:
			return false
		case .unknown:
			fatalError("Unknown activity type: \(userActivityType)")
		}
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		guard let application = notification.object as? NSApplication else { return }
		let notificationService = try! Services.access(NotificationService.self)
		notificationService.registerUserNotifications()
		if
			let userInfo = notification.userInfo as? [String : Any],
			handlePossibleRemoteNotification(application, userInfo: userInfo),
			let window = application.mainWindow {
			window.close()
		}
	}

	func applicationWillFinishLaunching(_ notification: Notification) {
		guard #available(macOS 10.14, *) else { return }
		let notificationService = try! Services.access(NotificationService.self)
		notificationService.registerRemoteNotifications()
	}
	
	func applicationWillTerminate(_ notification: Notification) {
		let conversationManager = try! Services.access(ConversationService.self) as! MultipeerConversationManager
		conversationManager.peerID = nil // This is better than resetSession, since the app is definitely going away
	}
	
	func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
		// Subclasses must handle any other kind of remote notifications
		handlePossibleRemoteNotification(application, userInfo: userInfo)
	}

	@discardableResult private func handlePossibleRemoteNotification(_ application: NSApplication, userInfo: [String : Any]) -> Bool {
		if let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo), let cloudService = try? Services.access(CloudKitService.self), cloudService.canProcess(notification: cloudKitNotification) {
			let qualityOfService: QualityOfService = application.isActive ? .default : .background
			cloudService.fetchChanges(notification: cloudKitNotification, qualityOfService: qualityOfService) { [loggingService] result in
				switch result {
				case .success:
					loggingService.log(.info, "Remote notification sync success")
				case .failure(let error):
					loggingService.log(.info, "Remote notification sync failure: %{public}@", error.localizedDescription)
				}
			}
			return true
		} else if let legacyNotificationProvider = notificationProvider as? LegacyUserNotificationManager {
			legacyNotificationProvider.handleRemoteNotification(userInfo)
		}
		return false
	}
}

extension ResolveDelegate {

	func mainWindowController(for responder: NSResponder) -> MainWindowController? {
		if let window = responder.findResponder(as: NSWindow.self) {
			return window.windowController as? MainWindowController
		}
		if let application = responder.findResponder(as: NSApplication.self) {
			if let window = application.keyWindow {
				return window.windowController as? MainWindowController
			}
			return application.windows.compactMap({ $0.windowController as? MainWindowController }).first
		}
		return nil
	}
}
