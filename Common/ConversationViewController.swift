//
//  ConversationViewController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2016 The App Studio LLC.
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

class ConversationViewController: ResolveViewController {

	@Service internal var conversationService: ConversationService
	@Service internal var settingsService: MultipeerSettingsService
	@Service internal var userInputService: UserInputService

	// MARK: - Interface Builder properties and methods
	
	@IBOutlet internal var sendButton: Button!
	
	@IBOutlet internal var textField: TextField!
	
	@IBAction internal func sendButtonClicked(_ sender: Button) {
		let message = textField.trimmedText
		if message.count > 0 {
			sendMessageToAllPeers(message)
			textField.trimmedText = ""
		}
	}

	// MARK: - ResolveViewController overrides

	override func prepare(for segue: StoryboardSegue, sender: Any?) {
		switch segue.destination {
		case let conversationTableViewController as ConversationTableViewController:
			self.conversationTableViewController = conversationTableViewController
#if os(macOS)
		case let destinationViewController as InputSheetViewController:
			destinationViewController.delegate = self
#endif
		default: break
		}
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		stopConversationConnection()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(connectionStateChanged(_:)), name: .conversationConnectionStateChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(receivedMessage(_:)), name: .conversationReceivedMessage, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(connectionStateRefreshed(_:)), name: .conversationStatusRefresh, object: nil)
		#if os(macOS)
			NotificationCenter.default.addObserver(self, selector: #selector(inputTextDidChange(_:)), name: NSControl.textDidChangeNotification, object: nil)
		#endif
		updateConnectedPeersTable()
    }
	
	// MARK: - Private properties and methods
	
	@objc private func connectionStateChanged(_ notification: Notification) {
		updateConnectedPeersTable()
	}
	
	@objc private func connectionStateRefreshed(_ notification: Notification) {
		updateConnectedPeersTable()
	}

	private var conversationTableViewController: ConversationTableViewController! {
		didSet { updateConnectedPeersTable() }
	}

	@IBAction private func inputTextDidChange(_ notification: Notification) {
		guard notification.object as AnyObject === textField else { return }
		sendButton.isEnabled = textField.trimmedText.count > 0
	}
	
	@objc private func receivedMessage(_ notification: Notification) {
		let message = notification.userInfo?[ConversationNotificationOptionsKey.receivedMessage] as! String
		let peerID = notification.userInfo?[ConversationNotificationOptionsKey.connectionPeer] as! MCPeerID
		userInputService.presentAlert(message, withTitle: peerID.displayName, from: self, forDuration: 1)
	}
	
	internal func sendMessageToAllPeers(_ message: String!) {
		conversationService.send(message) { (error: Error?) in
			if let error = error {
				self.userInputService.presentAlert(error.localizedDescription, withTitle: "Error sending message", from: self, forDuration: 2)
			}
		}
	}
	
	internal func startConversationConnection() {
		if !Services.startConversationConnection() {
			#if os(macOS)
				performSegue(withIdentifier: "showInputSheet", sender: self)
			#else
				userInputService.presentTextInputAlert(withTitle: "Name Required", message: "Enter a name for this device so that other people may recognize you", from: self, completionHandler: { [settingsService] text in
					guard let text = text, text.count > 0 else { return }
					settingsService.peerID = MCPeerID(displayName: text)
					self.startConversationConnection()
				})
			#endif
		}
	}
	
	internal func stopConversationConnection() {
		Services.stopConversationConnection()
	}
	
	internal func updateConnectedPeersTable() {
		guard let conversationTableViewController = conversationTableViewController else { return }
		let connectedPeerNames = conversationService.connectedPeerNames
		if connectedPeerNames.count > 0 {
			conversationTableViewController.apply(connectedPeerNames)
		} else {
			let noPeers = NSLocalizedString("peers.count.zero", comment: "Currently, no peers are connected")
			conversationTableViewController.apply([noPeers])
		}
	}
}
