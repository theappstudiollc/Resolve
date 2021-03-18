//
//  WatchSessionManager.swift
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
import WatchConnectivity

public class WatchSessionManager: NSObject {

	fileprivate var lastKnownState = WatchSessionState.unavailable {
		didSet {
			guard lastKnownState != oldValue else { return }
			loggingService.log(.info, "WatchSessionManager state changed: %{public}@", lastKnownState.debugDescription)
			notificationCenter.post(name: .watchSessionStateChangedNotification, object: self)
		}
	}

	let dataService: CoreDataService
	let loggingService: CoreLoggingService
	let notificationCenter: NotificationCenter
	let settingsService: WatchSessionSettingsService
	fileprivate let watchSession: WCSession

	public init(dataService: CoreDataService, loggingService: CoreLoggingService, settingsService: WatchSessionSettingsService, notificationCenter: NotificationCenter = .default, watchSession: WCSession = .default) {
		self.dataService = dataService
		self.loggingService = loggingService
		self.notificationCenter = notificationCenter
		self.settingsService = settingsService
		self.watchSession = watchSession
		super.init()
		guard WCSession.isSupported() else { return }
		watchSession.delegate = self
	}

	public func activate() {
		guard watchSession.activationState != .activated else { return }
		watchSession.activate()
	}

	fileprivate func checkAvailability() -> Bool {
		guard WCSession.isSupported(), watchSession.activationState == .activated else { return false }
		#if os(iOS)
		guard watchSession.isPaired, watchSession.isWatchAppInstalled else { return false }
		#elseif os(watchOS)
		if #available(watchOS 6.0, *), !watchSession.isCompanionAppInstalled, !watchSession.iOSDeviceNeedsUnlockAfterRebootForReachability { return false }
		#endif
		return true
	}
}

extension WatchSessionManager: WCSessionDelegate {

	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		if let error = error {
			loggingService.log(.error, "WatchSessionManager activation did complete with error: %{public}@", error.localizedDescription)
		} else {
			loggingService.debug("WatchSessionManager activation did complete with `activationState` %{public}@", activationState.debugDescription)
		}
		lastKnownState = state
	}

	#if os(iOS)
	
	public func sessionDidBecomeInactive(_ session: WCSession) {
		loggingService.debug("WatchSessionManager session did become inactive with `activationState` %{public}@", session.activationState.debugDescription)
		lastKnownState = state
	}

	public func sessionDidDeactivate(_ session: WCSession) {
		loggingService.debug("WatchSessionManager session did deactivate with `activationState` %{public}@", session.activationState.debugDescription)
		lastKnownState = state
	}

	public func sessionWatchStateDidChange(_ session: WCSession) {
		loggingService.debug("WatchSessionManager session watch state changed")
		lastKnownState = state
	}

	public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		loggingService.debug("WatchSessionManager session did receive message with keys: %{public}@", message.keys.joined(separator: ", "))
		switch message["command"] as? String {
		case .some("GetSharedEventCount"):
			let count: Int? = try? dataService.performAndReturn { context in
				let request: NSFetchRequest<SharedEvent> = SharedEvent.fetchRequest()
				request.predicate = SharedEvent.predicateForNotSyncedAs([.synchronizingRelationships, .markedForDeletion])
				return try context.count(for: request)
			}
			replyHandler(["result" : count ?? -1])
		case .some("UpdateMessageCount"):
			guard let count = message["value"] as? Int else {
				replyHandler(["error" : "`value` not provided"])
				return
			}
			/*
			let currentCount = settingsService.messageCount
			guard count > currentCount else {
				replyHandler(["error" : "`value` not incremented"])
				return
			}
			*/
			settingsService.messageCount = count
			replyHandler(["result" : count])
		default:
			replyHandler(["error" : "unexpected command"])
		}
	}

	#endif

	#if os(watchOS)

	public func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
		let installState: String
		if #available(watchOS 6.0, *), !session.isCompanionAppInstalled {
			installState = "not installed"
		} else {
			installState = "installed"
		}
		loggingService.debug("WatchSessionManager companion app installed changed: %{public}@", installState)
		lastKnownState = state
	}

	#endif

	public func sessionReachabilityDidChange(_ session: WCSession) {
		loggingService.debug("WatchSessionManager session reachability changed: %{public}@", session.isReachable ? "reachable" : "not reachable")
		lastKnownState = state
	}

	public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
		loggingService.debug("WatchSessionManager received application context with keys: %{public}@", applicationContext.keys.joined(separator: ", "))
		lastKnownState = state
		notificationCenter.post(name: .watchSessionContextUpdatedNotification, object: self, userInfo: applicationContext)
	}
}

extension WatchSessionManager: WatchSessionService {

	public var applicationContext: [String : Any]? {
		guard checkAvailability() else { return nil }
		return watchSession.applicationContext
	}

	public var receivedApplicationContext: [String : Any]? {
		guard checkAvailability() else { return nil }
		return watchSession.receivedApplicationContext
	}

	public var state: WatchSessionState {
		guard checkAvailability() else { return .unavailable }
		return watchSession.isReachable ? .active : .available
	}

	#if os(watchOS)

	public func fetchSharedEventCount(_ handler: @escaping (Result<Int, WatchSessionError>) -> Void) {
		guard watchSession.activationState == .activated else {
			handler(.failure(.sessionNotAvailable))
			return
		}
		watchSession.sendMessage(["command" : "GetSharedEventCount"], replyHandler: { result in
			if let sharedEventCount = result["result"] as? Int {
				handler(.success(sharedEventCount))
			} else {
				handler(.failure(.valueNotRetrieved))
			}
		}) { error in
			handler(.failure(.unexpected(error)))
		}
	}

	public func sendMessageCount(_ count: Int, handler: @escaping (Result<Bool, WatchSessionError>) -> Void) {
		guard watchSession.activationState == .activated else {
			handler(.failure(.sessionNotAvailable))
			return
		}
		watchSession.sendMessage(["command" : "UpdateMessageCount", "value" : count], replyHandler: { result in
			if let messageCount = result["result"] as? Int, messageCount == count {
				handler(.success(true))
			} else {
				handler(.failure(.countNotAccepted))
			}
		}) { error in
			handler(.failure(.unexpected(error)))
		}
	}

	#endif

	public func updateApplicationContext(_ applicationContext: [String : Any]) throws {
		try watchSession.updateApplicationContext(applicationContext)
	}
}
