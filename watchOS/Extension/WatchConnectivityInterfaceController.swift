//
//  WatchConnectivityInterfaceController.swift
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

final class WatchConnectivityInterfaceController: ResolveViewController {

	var notificationCenter: NotificationCenter = .default

	@Service var inputService: UserInputService
	@Service var settingsService: WatchSessionSettingsService
	@Service var watchSessionService: WatchSessionService

	@IBOutlet var applicationContextButton: WKInterfaceButton!
	@IBOutlet var applicationContextLabel: WKInterfaceLabel!
	@IBOutlet var messageButton: WKInterfaceButton!
	@IBOutlet var messageLabel: WKInterfaceLabel!
	@IBOutlet var stateLabel: WKInterfaceLabel!

	@IBAction func applicationContextButtonTapped() {
		guard var applicationContext = watchSessionService.applicationContext else { return }
		let oldValue = (applicationContext["TapCount"] as? Int) ?? 0
		applicationContext["TapCount"] = oldValue + 1
		do {
			try watchSessionService.updateApplicationContext(applicationContext)
		} catch {
			loggingService.log(.error, "WatchSession error updating application context: %{public}@", error.localizedDescription)
			applicationContext["TapCount"] = oldValue
			inputService.presentError(error, withTitle: "Error", from: self)
		}
		updateApplicationContext(applicationContext)
	}

	@IBAction func messageButtonTapped() {
		let newCount = settingsService.messageCount + 1
		watchSessionService.sendMessageCount(newCount) { [settingsService, loggingService] result in
			switch result {
			case .success:
				settingsService.messageCount = newCount
				self.updateMessageCount(newCount)
			case .failure(let error):
				loggingService.log(.error, "WatchConnectivityInterfaceController unable to update message count: %{public}@", error.localizedDescription)
			}
		}
	}

	private var contextObserver: NSObjectProtocol? {
		willSet {
			guard let contextObserver = contextObserver else { return }
			notificationCenter.removeObserver(contextObserver)
		}
	}
	private var stateObserver: NSObjectProtocol? {
		willSet {
			guard let stateObserver = stateObserver else { return }
			notificationCenter.removeObserver(stateObserver)
		}
	}

	override init() {
		super.init()
		contextObserver = notificationCenter.addObserver(forName: .watchSessionContextUpdatedNotification, object: watchSessionService, queue: nil) { [weak self] notification in
			guard let self = self, let applicationContext = notification.userInfo as? [String : Any] else { return }
			self.updateReceivedApplicationContext(applicationContext)
		}
		stateObserver = notificationCenter.addObserver(forName: .watchSessionStateChangedNotification, object: watchSessionService, queue: nil) { [weak self] _ in
			guard let self = self else { return }
			self.refreshState()
		}
	}

	override func willActivate() {
		super.willActivate()
		refreshState()
		updateMessageCount(settingsService.messageCount)
	}

	private func refreshState() {
		updateApplicationContext(watchSessionService.applicationContext)
		updateReceivedApplicationContext(watchSessionService.receivedApplicationContext)
		updateState()
	}

	fileprivate func updateApplicationContext(_ applicationContext: [String : Any]?) {
		if let tapCount = applicationContext?["TapCount"] as? Int {
			applicationContextLabel.setText("\(tapCount)")
		} else {
			applicationContextLabel.setText("none")
		}
	}

	fileprivate func updateMessageCount(_ messageCount: Int) {
		messageLabel.setText("\(messageCount)")
	}

	fileprivate func updateReceivedApplicationContext(_ applicationContext: [String : Any]?) {
		if let showButton = applicationContext?["ShowButton"] as? Bool, watchSessionService.state != .unavailable {
			applicationContextButton.setHidden(!showButton)
		} else {
			applicationContextButton.setHidden(true)
		}
	}

	fileprivate func updateState(_ error: Error? = nil) {
		if let error = error {
			stateLabel.setText(error.localizedDescription)
			return
		}
		stateLabel.setText(watchSessionService.state.debugDescription)
		messageButton.setHidden(watchSessionService.state == .unavailable)
	}
}
