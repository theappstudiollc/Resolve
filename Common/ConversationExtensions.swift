//
//  ConversationExtensions.swift
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

import MultipeerConnectivity
import ResolveKit

extension Services {
	
	class func startConversationConnection() -> Bool {
		let settingsService = try! access(MultipeerSettingsService.self)
		if let peerID = settingsService.peerID {
			let conversationManager = try! access(ConversationService.self) as! MultipeerConversationManager
			conversationManager.peerID = peerID
			if conversationManager.connectedPeerNames.count == 0 {
				return conversationManager.startListeningForPeers()
			}
			return true
		}
		return false
	}
	
	class func stopConversationConnection() {
		let conversationManager = accessIfLoaded(ConversationService.self) as? MultipeerConversationManager
		conversationManager?.stopListeningForPeers()
		conversationManager?.resetSession()
	}
}

public struct ConversationNotificationOptionsKey: Hashable, Equatable, RawRepresentable {
	
	public var rawValue: String
	
	public init(_ rawValue: String) {
		self.init(rawValue: rawValue)
	}
	
	public init(rawValue: String) {
		self.rawValue = rawValue
	}
}

extension ConversationNotificationOptionsKey {
	
	public static let connectionPeer = ConversationNotificationOptionsKey("kConversationConnectionPeer")
	
	public static let connectionState = ConversationNotificationOptionsKey("kConversationConnectionState")
	
	public static let receivedMessage = ConversationNotificationOptionsKey("kConversationReceivedMessage")
}

extension ResolveDelegate: MultipeerConversationManagerDelegate {
	
	private func notify(_ notificationName: NSNotification.Name, userInfo: [ConversationNotificationOptionsKey : Any]? = nil) {
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: notificationName, object: self, userInfo: userInfo);
		}
	}
	
	func conversationManager(_ manager: MultipeerConversationManager, changed connectionState: MCSessionState, with peerID: MCPeerID) {
		notify(.conversationConnectionStateChanged, userInfo: [
			.connectionPeer : peerID,
			.connectionState : connectionState])
	}
	
	func conversationManager(_ manager: MultipeerConversationManager, received message: String, from peerID: MCPeerID) {
		notify(.conversationReceivedMessage, userInfo: [
			.receivedMessage : message,
			.connectionPeer : peerID])
	}
	
	func conversationManagerRefreshedStatus(_ manager: MultipeerConversationManager) {
		notify(.conversationStatusRefresh)
	}
}

extension Notification.Name {
	
	static let conversationConnectionStateChanged = Notification.Name("kConversationConnectionStateChanged")
	static let conversationReceivedMessage = Notification.Name("kConversationReceivedMessage")
	static let conversationStatusRefresh = Notification.Name("kConversationStatusRefresh")
}
