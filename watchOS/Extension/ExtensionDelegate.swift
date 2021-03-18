//
//  ExtensionDelegate.swift
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

import ClockKit
import CloudKit
import Intents
import ResolveKit
import WatchKit

class ExtensionDelegate: ResolveDelegate, WKExtensionDelegate {

	var isActive = false

    func applicationDidFinishLaunching() {
		if #available(watchOS 6.0, *) {
			let notificationService = try! Services.access(NotificationService.self)
			notificationService.registerRemoteNotifications()
		}

		try! watchSessionManager.get().activate()

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
		if #available(watchOS 6.0, *), INPreferences.siriAuthorizationStatus() == .notDetermined {
			INPreferences.requestSiriAuthorization { [loggingService] status in
				loggingService.debug("Siri authorization status = %{public}@", "\(status.rawValue)")
			}
		}
    }

    func applicationDidBecomeActive() {
		isActive = true
    }
	
    func applicationWillResignActive() {
		isActive = false
		// Be a good citizen and release memory
		Services.releaseUnusedServices()
    }

	func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
		notificationProvider.remoteTokenRegistrationFailed(error)
	}

	func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
		notificationProvider.remoteTokenRegistrationSucceeded(deviceToken)
	}

	@available(watchOS 6.0, *)
	func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void) {

		loggingService.log(.info, "Received Remote Notifications: %{public}@", userInfo)

		if let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo), let cloudService = try? Services.access(CloudKitService.self), cloudService.canProcess(notification: cloudKitNotification) {
			loggingService.log(.info, "Fetching CloudKit changes from Notification")
			let qualityOfService: QualityOfService = isActive ? .userInitiated : .background // If the app is active this should be immediate
			cloudService.fetchChanges(notification: cloudKitNotification, qualityOfService: qualityOfService) { [loggingService] result in
				switch result {
				case .success:
					loggingService.log(.info, "Success fetching CloudKit changes from Notification")
					let complicationService = try? Services.access(ComplicationService.self)
					let dataService = try! Services.access(DataService.self)
					let tapCount = try? dataService.getTapCount()
					complicationService?.updateTapCount(tapCount ?? 0, forceReload: false)
					completionHandler(.newData)
				case .failure(let error):
					loggingService.log(.error, "Error fetching CloudKit changes from Notification: %{public}@", error.localizedDescription)
					completionHandler(.failed)
				}
			}
		} else {
			loggingService.log(.error, "No handler for notification: %{public}@", userInfo)
			completionHandler(.noData)
		}
	}

	@available(watchOS 3.0, *)
	func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
				if #available(watchOS 4.0, *) {
					backgroundTask.setTaskCompletedWithSnapshot(false)
				} else {
					// Fallback on earlier versions
				}
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
				if #available(watchOS 4.0, *) {
					connectivityTask.setTaskCompletedWithSnapshot(false)
				} else {
					// Fallback on earlier versions
				}
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
				if #available(watchOS 4.0, *) {
					urlSessionTask.setTaskCompletedWithSnapshot(false)
				} else {
					// Fallback on earlier versions
				}
            default:
                // make sure to complete unhandled task types
				if #available(watchOS 4.0, *) {
					task.setTaskCompletedWithSnapshot(false)
				} else {
					// Fallback on earlier versions
				}
            }
        }
    }

	func handle(_ userActivity: NSUserActivity) {
		loggingService.log(.info, "ExtensionDelegate handle userActivity: %{public}@", userActivity.activityType)

		guard let userActivityService = try? Services.access(UserActivityService.self), let activity = userActivityService.activityType(with: userActivity.activityType) else { return }

		let names = ["CoreData", "Connectivity", "Complication", "NowPlaying"]
		switch activity {
		case .coreData:
			if CoreDataInterfaceController.isVisibleInterfaceController == true { return }
			WKInterfaceController.reloadRootControllers(withNames: names, contexts: [true, false, false, false])
		case .watchConnectivity:
			if WatchConnectivityInterfaceController.isVisibleInterfaceController == true { return }
			WKInterfaceController.reloadRootControllers(withNames: names, contexts: [false, true, false, false])
		default:
			break
		}
	}

	func handleUserActivity(_ userInfo: [AnyHashable : Any]?) {
		if let userInfo = userInfo {
			let keys = userInfo.keys.map({ "\($0)" }).joined(separator: ", ")
			loggingService.log(.info, "ExtensionDelegate handle userInfo(keys): %{public}@", keys)
		} else {
			loggingService.log(.info, "ExtensionDelegate handle userInfo: nil")
		}

		if let rootController = WKExtension.shared().rootInterfaceController {
			loggingService.log(.info, "Extension root interface controller: %{public}@", "\(rootController.self)")
		}
	}
}

fileprivate extension WKInterfaceController {

	class var isVisibleInterfaceController: Bool? {
		guard #available(watchOS 4.0, *) else { return nil }
		return WKExtension.shared().visibleInterfaceController is Self
	}
}
