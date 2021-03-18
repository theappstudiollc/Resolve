//
//  WatchConnectivityViewController.swift
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

class WatchConnectivityViewController: CoreViewController {

	var notificationCenter: NotificationCenter = .default
	
	@Service var loggingService: CoreLoggingService
	@Service var settingsService: WatchSessionSettingsService
	@Service var watchSessionService: WatchSessionService

	@IBOutlet var messageCountLabel: UILabel!
	@IBOutlet var receivedApplicationContextLabel: UILabel!
	@IBOutlet var showButtonSwitch: UISwitch!
	@IBOutlet var stateLabel: UILabel!

	@IBAction func showButtonSwitchToggled(_ sender: UISwitch) {
		guard var applicationContext = watchSessionService.applicationContext else { return }
		let oldValue = (applicationContext["ShowButton"] as? Bool) ?? false
		applicationContext["ShowButton"] = sender.isOn
		do {
			try watchSessionService.updateApplicationContext(applicationContext)
		} catch {
			loggingService.log(.error, "WatchSession error updating application context: %{public}@", error.localizedDescription)
			applicationContext["ShowButton"] = oldValue
			updateApplicationContext(applicationContext)
		}
	}

	private var contextObserver: NSObjectProtocol? {
		willSet {
			guard let contextObserver = contextObserver else { return }
			notificationCenter.removeObserver(contextObserver)
		}
	}
	private var messageObserver: NSObjectProtocol? {
		willSet {
			guard let messageObserver = messageObserver else { return }
			notificationCenter.removeObserver(messageObserver)
		}
	}
	private var stateObserver: NSObjectProtocol? {
		willSet {
			guard let stateObserver = stateObserver else { return }
			notificationCenter.removeObserver(stateObserver)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		contextObserver = notificationCenter.addObserver(forName: .watchSessionContextUpdatedNotification, object: watchSessionService, queue: .main) { [weak self] notification in
			guard let self = self, let applicationContext = notification.userInfo as? [String : Any] else { return }
			self.updateReceivedApplicationContext(applicationContext)
		}
		messageObserver = notificationCenter.addObserver(forName: .messageCountChanged, object: settingsService, queue: .main) { [weak self] notification in
			guard let self = self else { return }
			self.updateMessageCount()
		}
		stateObserver = notificationCenter.addObserver(forName: .watchSessionStateChangedNotification, object: watchSessionService, queue: .main) { [weak self] _ in
			guard let self = self else { return }
			self.refreshState()
		}
		refreshState()
		updateMessageCount()
	}

	private func refreshState() {
		updateApplicationContext(watchSessionService.applicationContext)
		updateReceivedApplicationContext(watchSessionService.receivedApplicationContext)
		updateState()
	}

	fileprivate func updateApplicationContext(_ applicationContext: [String : Any]?) {
		if let showButton = applicationContext?["ShowButton"] as? Bool {
			showButtonSwitch.isOn = showButton
		} else {
			showButtonSwitch.isOn = false
		}
	}

	fileprivate func updateMessageCount() {
		messageCountLabel.text = "\(settingsService.messageCount)"
	}

	fileprivate func updateReceivedApplicationContext(_ applicationContext: [String : Any]?) {
		if let tapCount = applicationContext?["TapCount"] as? Int {
			receivedApplicationContextLabel.text = "\(tapCount)"
		} else {
			receivedApplicationContextLabel.text = "none"
		}
	}

	fileprivate func updateState(_ error: Error? = nil) {
		if let error = error {
			stateLabel.text = error.localizedDescription
			return
		}
		stateLabel.text = watchSessionService.state.debugDescription
	}
}
