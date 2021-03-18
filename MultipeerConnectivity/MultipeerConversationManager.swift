//
//  MultipeerConversationManager.swift
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

import Foundation
import MultipeerConnectivity
import ResolveKit

public final class MultipeerConversationManager: NSObject {

	// MARK: - Public properties

	public weak var delegate: MultipeerConversationManagerDelegate?
	
	public var peerID: MCPeerID? {
		didSet {
			guard peerID != oldValue else { return }
			resetSession()
		}
	}
	
	public required init(fileStoreService: CoreFileStoreService, settingsService: MultipeerSettingsService) {

		bonjourServiceType = settingsService.bonjourServiceType
		discoveryIdentifier = settingsService.discoveryIdentifier
		
		try! fileStoreService.ensureDirectoryExists(for: .cache, withSubpath: "resources")
		let resourceContainerURL = try! fileStoreService.directoryUrl(for: .cache).appendingPathComponent("resources", isDirectory: true)
		
		messageManager = MultipeerMessageManager(with: nil, resourceContainer: resourceContainerURL)
		
		super.init()
		
		messageManager.callbackQueue = DispatchQueue(label: "\(self).callbackQueue")
		messageManager.delegate = self
		peerID = settingsService.peerID
		resetSession() // Because didSet is not called in initializers
	}
	
	// MARK: - Public methods
	
	public func resetSession() {
		peersInPlay.removeAll()
		hostPeerID = nil
		if let peerID = peerID {
			messageManager.sessionProvider = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
		} else {
			messageManager.sessionProvider = nil
		}
		delegate?.conversationManagerRefreshedStatus(self)
	}
	
	public func startListeningForPeers() -> Bool {
		#if os(iOS)
			guard UIApplication.shared.applicationState == .active else {
				return false
			}
		#endif
		shouldStartListening = true
		startBrowsing()
		return true
	}
	
	public func stopListeningForPeers() {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startAdvertising), object: nil)
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startBrowsing), object: nil)
		nearbyServiceAdvertiser = nil
		nearbyServiceBrowser = nil
		shouldStartListening = false
	}
	
	// MARK: - Private properties

	let bonjourServiceType: String
	let discoveryIdentifier: UUID
	var hostPeerID: MCPeerID?
	let messageManager: MultipeerMessageManager
	var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser? {
		willSet {
			nearbyServiceAdvertiser?.delegate = nil
			nearbyServiceAdvertiser?.stopAdvertisingPeer()
		}
		didSet {
			nearbyServiceAdvertiser?.delegate = self
		}
	}
	var nearbyServiceBrowser: MCNearbyServiceBrowser? {
		willSet {
			nearbyServiceBrowser?.delegate = nil
			nearbyServiceBrowser?.stopBrowsingForPeers()
		}
		didSet {
			nearbyServiceBrowser?.delegate = self
		}
	}
	var peersInPlay = [MCPeerID : UUID](minimumCapacity: kMCSessionMaximumNumberOfPeers)
	var shouldStartListening = false
	
	@objc func startAdvertising() {
		guard nearbyServiceAdvertiser == nil, messageManager.sessionProvider != nil, let peerID = peerID else {
			return
		}
		print("\(self) beginning to advertise...")
		nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: [
			"IDENTIFIER" : discoveryIdentifier.uuidString
		], serviceType: bonjourServiceType)
		nearbyServiceAdvertiser!.startAdvertisingPeer()
	}
	
	@objc func startBrowsing() {
		guard nearbyServiceBrowser == nil, messageManager.sessionProvider != nil, let peerID = peerID else {
			return
		}
		print("\(self) beginning to browse...")
		nearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: bonjourServiceType)
		nearbyServiceBrowser!.startBrowsingForPeers()
		perform(#selector(startAdvertising), with: nil, afterDelay: 10.0)
	}
}

extension MultipeerConversationManager: ConversationService {
	
	public var connectedPeerNames: [String] {
		guard let session = messageManager.sessionProvider else {
			return []
		}
		return session.connectedPeers.map { $0.displayName }
	}
	
	@discardableResult public func send(_ message: String, completion: ((Error?) -> Void)?) -> Progress? {
		if let messageData = message.data(using: .utf8) {
			let payload = MultipeerMessagePayload(with: messageData, resource: nil)
			return messageManager.send(payload, to: nil) { error in
				completion?(error)
			}
		}
		return nil
	}
}
