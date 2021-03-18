//
//  SceneDelegate.swift
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

#if canImport(Intents)
import Intents
#endif
import ResolveKit

@available(iOS 13.0, tvOS 13.0, *)
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	// MARK: - UIWindowSceneDelegate properties and methods

	var window: UIWindow?

	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {

		guard let userActivityService = try? Services.access(UserActivityService.self) else {
			return
		}
		switch userActivityService.userActivityType(with: userActivity.activityType) {
		case .appSpecific:
			guard let rootViewController = Application.rootViewController(for: scene) else { return }
			print("Continue User Activity: \(userActivity.activityType)")
			rootViewController.restoreUserActivityState(userActivity)
		case .browsingWeb, .queryContinuation, .searchableItem:
			return
		case .unknown:
			fatalError("Unknown activity type: \(userActivity.activityType)")
		}
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		defer {
			lastActivationState = scene.activationState
		}
		if let notificationService = try? Services.access(NotificationService.self) {
			notificationService.registerUserNotifications()
		}
		guard [.background, .unattached].contains(lastActivationState), let userService = try? Services.access(AppUserService.self) else { return }
		userService.establishUser { success in
			let loggingService = try! Services.access(CoreLoggingService.self)
			loggingService.log(.info, "Establish User: %{public}@", success ? "success" : "failed")
			guard success else { return }
			let cloudKitService = try! Services.access(CloudKitService.self)
			// If it has been at least 14 days since the last .fullSync, perform one. Otherwise perform .default
			let diff = Calendar.current.dateComponents([.day], from: cloudKitService.lastFullSync, to: Date())
			let syncOptions: CloudKitServiceSyncOptions = diff.day == nil || diff.day! > 14 ? .fullSync : .default
			cloudKitService.synchronize(syncOptions: syncOptions, qualityOfService: .userInitiated, nil)
		}
		#if os(iOS)
		if INPreferences.siriAuthorizationStatus() == .notDetermined {
			INPreferences.requestSiriAuthorization { status in
				print("Siri authorization status = \(status.rawValue)")
			}
		}
		#endif
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		lastActivationState = scene.activationState
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		lastActivationState = scene.activationState
	}

	func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
		print("Failure: \(error)")
	}

	func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
		print("scene(\(scene), didUpdate: \(userActivity))")
	}

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		#if targetEnvironment(macCatalyst)
		guard let windowScene = scene as? UIWindowScene, let titlebar = windowScene.titlebar else { return }
		titlebar.titleVisibility = .hidden
		titlebar.toolbar = nil
		#endif
		// The configured UIStoryboard will take over from here
		if let restorationActivity = session.stateRestorationActivity, let delegate = scene.delegate as? SceneDelegate, let window = delegate.window, let rootViewController = window.rootViewController {
			rootViewController.restoreUserActivityState(restorationActivity)
		} else if connectionOptions.userActivities.count > 0 {
			print("We have user activities: \(connectionOptions.userActivities)")
		} else {
			print("not restoring _any_ user activities")
		}
	}

	func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {

		// Prepare to handle the incoming activity
		guard let userActivityService = try? Services.access(UserActivityService.self) else {
			return
		}
		switch userActivityService.userActivityType(with: userActivityType) {
		case .appSpecific:
			print("Will continue with activity: \(userActivityType)")
			return
		case .browsingWeb, .queryContinuation, .searchableItem:
			return
		case .unknown:
			fatalError("Unknown activity type: \(userActivityType)")
		}
	}

	func sceneWillResignActive(_ scene: UIScene) {
		lastActivationState = scene.activationState
	}

	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		guard let delegate = scene.delegate as? SceneDelegate, let window = delegate.window, let rootViewController = window.rootViewController as? RootViewController else {
			return nil
		}
		return rootViewController.getRestorableActivity()
	}

	public private(set) var lastActivationState: UIScene.ActivationState = .unattached
}
