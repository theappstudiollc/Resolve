//
//  FrameworkContext.swift
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

/// UIApplicationDelegate updates that support UIKit-based app targets (iOS, iPadOS, macCatalyst, tvOS)
class UIKitAppDelegate: ResolveDelegate, UIApplicationDelegate {

	let savesApplicationState = true

	// MARK: - UIApplicationDelegate properties and methods
	
	var window: UIWindow?

	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

		guard let userActivityService = try? Services.access(UserActivityService.self) else {
			return false
		}
		switch userActivityService.userActivityType(with: userActivity.activityType) {
		case .appSpecific:
			guard let rootViewController = Application.rootViewController(for: application) else { return false }
			loggingService.debug("Continuing user activity: %{public}@", userActivity.activityType)
			if let activeChild = rootViewController.activeChild {
				restorationHandler([rootViewController, activeChild])
			} else {
				restorationHandler([rootViewController])
			}
			return true
		case .browsingWeb, .queryContinuation, .searchableItem:
			return false
		case .unknown:
			fatalError("Unknown activity type: \(userActivity.activityType)")
		}
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

		let notificationService = try! Services.access(NotificationService.self)
		notificationService.registerRemoteNotifications()

		if let userActivity = launchOptions?.userActivity {
			loggingService.debug("application launched with user activity: %{public}@", userActivity.activityType)
			if let rootViewController = Application.rootViewController(for: application) {
				rootViewController.userActivity = userActivity
			}
		} else if let userActivityType = launchOptions?.userActivityType {
			loggingService.debug("application launched with user activity type: %{public}@", userActivityType)
			if let rootViewController = Application.rootViewController(for: application) {
				rootViewController.isRestoringState = true
			}
		} else if let launchOptions = launchOptions {
			loggingService.debug("application launched with option keys: %{public}@", launchOptions.keys.map({ $0.rawValue }).joined(separator: ", "))
		} else {
			loggingService.debug("application launched with no options")
		}
		return true
	}
	
	func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		guard
			let restoreBundleVersion = coder.decodeObject(of: NSString.self, forKey: UIApplication.stateRestorationBundleVersionKey) as String?,
			let restoreUserInterfaceIdiomValue = coder.decodeObject(of: NSNumber.self, forKey: UIApplication.stateRestorationUserInterfaceIdiomKey),
			let restoreUserInterfaceIdiom = UIUserInterfaceIdiom(rawValue: restoreUserInterfaceIdiomValue.intValue),
			restoreUserInterfaceIdiom == UIDevice.current.userInterfaceIdiom
		else {
			fatalError("Please study code to ensure we're handling this situation correctly")
		}
		guard let settingsService = try? Services.access(AppInfoService.self), restoreBundleVersion == settingsService.appBuild else {
			return false
		}
		let shouldRestore = savesApplicationState
		if shouldRestore {
			print("Restoring build \(restoreBundleVersion) with idiom \(restoreUserInterfaceIdiom.rawValue)")
			if let rootViewController = Application.rootViewController(for: application) {
				// Getting here means we're in a legacy state restoration flow
				if let restorableActivityType = coder.decodeObject(of: NSString.self, forKey: "restorableActivityType") as String? {
					print(" - from \(restorableActivityType)")
				}
//					let userActivity = NSUserActivity(activityType: restorableActivityType)
//					if let restorableActivityUserInfo = coder.decodeObject(forKey: "restorableActivityUserInfo") as? [AnyHashable : Any] {
//						userActivity.userInfo = restorableActivityUserInfo
//					}
//					rootViewController.restorationActivity = userActivity
//				} else {
					rootViewController.isRestoringState = shouldRestore
//				}
			}
		}
		return shouldRestore
	}
	
	func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
		return self.application(application, shouldRestoreApplicationState: coder)
	}
	
	func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		// TODO: See if we can somehow get the rootViewController in scene-based applications and if (savesApplicationState is the right default)
		guard let rootViewController = Application.rootViewController(for: application) else { return savesApplicationState }
		// Getting here means we're in a legacy state restoration flow
		guard let restorableActivity = rootViewController.getRestorableActivity() else { return false }
		coder.encode(restorableActivity.activityType, forKey: "restorableActivityType")
		// TODO: This is not "current" -- should we require that the ViewControllers handle this?
//		if let userInfo = restorableActivity.userInfo {
//			coder.encode(userInfo, forKey: "restorableActivityUserInfo")
//		}
		return savesApplicationState
	}
	
	func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
		return self.application(application, shouldSaveApplicationState: coder)
	}
	
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		if let launchOptions = launchOptions {
			loggingService.debug("application will launch with option keys: %{public}@", launchOptions.keys.map({ $0.rawValue }).joined(separator: ", "))
		} else {
			loggingService.debug("application will launch with no options")
		}
		return true
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		defer {
			lastApplicationState = application.applicationState
		}
		if let notificationService = try? Services.access(NotificationService.self) {
			notificationService.registerUserNotifications()
		}
		guard lastApplicationState == .background, let userService = try? Services.access(AppUserService.self) else { return }
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
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		lastApplicationState = application.applicationState
		let conversationManager = Services.accessIfLoaded(ConversationService.self) as? MultipeerConversationManager
		conversationManager?.resetSession()
		// Be a good citizen and release memory
		Services.releaseUnusedServices()
	}
	
	func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
		Services.releaseUnusedServices()
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		lastApplicationState = .inactive
		let conversationManager = Services.accessIfLoaded(ConversationService.self) as? MultipeerConversationManager
		conversationManager?.stopListeningForPeers()
	}
	
	#if os(iOS)

	@available(macCatalyst, deprecated: 13.0)
	func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
		// Declared so that future Xcode versions will correctly update Swift UIApplicationDelegate interfaces
	}
	
	#endif

	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
		// Declared so that future Xcode versions will correctly update Swift UIApplicationDelegate interfaces
		let loggingService = try! Services.access(CoreLoggingService.self)
		loggingService.log(.debug, "Surprise call to didReceiveRemoteNotification")
	}

	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		
		// Subclasses must handle any other kind of remote notifications (and call the completionHandler)
		guard let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo), let cloudService = try? Services.access(CloudKitService.self), cloudService.canProcess(notification: cloudKitNotification) else { return }

		application.continueTaskIfBackgrounded(withName: "\(CloudKitService.self).fetchChanges", task: { timeRemaining, notifyCompletion in
			let qualityOfService: QualityOfService = lastApplicationState == .active ? .default : .background
			cloudService.fetchChanges(notification: cloudKitNotification, qualityOfService: qualityOfService) { result in
				switch result {
				case .success:
					completionHandler(.newData)
				case .failure:
					completionHandler(.failed)
				}
				notifyCompletion()
			}
		}) { taskExpired in
			print(taskExpired ? "Fetch Changes expired" : "Fetch Changes completed in time")
		}
	}

	/// This method lets the platform know whether the app will notify the user about activity continuation
	func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {

		// Return false if we want iOS to do the work of notifying the user
		guard let userActivityService = try? Services.access(UserActivityService.self) else {
			return false
		}
		switch userActivityService.userActivityType(with: userActivityType) {
		case .appSpecific:
			print("Will continue with activity: \(userActivityType)")
			return false
		case .browsingWeb, .queryContinuation, .searchableItem:
			return false
		case .unknown:
			fatalError("Unknown activity type: \(userActivityType)")
		}
	}

	public private(set) var lastApplicationState: UIApplication.State = .background
}

extension UIApplication {

	class func rootViewController(for responder: UIResponder) -> RootViewController? {
		if let window = responder.findResponder(as: UIWindow.self) {
			return window.rootViewController as? RootViewController
		}
		if #available(iOS 13.0, tvOS 13.0, *), let windowScene = responder.findResponder(as: UIWindowScene.self), let sceneDelegate = windowScene.delegate as? SceneDelegate, let window = sceneDelegate.window {
			return window.rootViewController as? RootViewController
		}
		// NOTE: the line below may not ever work
		if #available(iOS 13.0, tvOS 13.0, *), let sceneDelegate = responder.findResponder(as: SceneDelegate.self), let window = sceneDelegate.window {
			return window.rootViewController as? RootViewController
		}
		if let appDelegate = responder.findResponder(as: UIKitAppDelegate.self), let window = appDelegate.window {
			return window.rootViewController as? RootViewController
		}
		return nil
	}

	#if os(iOS)

	class func interfaceOrientation(for responder: UIResponder) -> UIInterfaceOrientation {
		guard #available(iOS 13.0, *) else {
			return UIApplication.shared.statusBarOrientation
		}
		guard let window = responder.findResponder(as: UIWindow.self), let scene = window.windowScene else {
			return .unknown
		}
		return scene.interfaceOrientation
	}

	#endif
}
