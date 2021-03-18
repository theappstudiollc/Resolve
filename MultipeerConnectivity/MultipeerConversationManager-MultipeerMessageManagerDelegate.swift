//
//  MultipeerConversationManager-MultipeerMessageManagerDelegate.swift
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

import ResolveKit

extension MultipeerConversationManager: MultipeerMessageManagerDelegate {
	
	public func messageManager(_ messageManager: MultipeerMessageManager, changed sessionState: MCSessionState, with peer: MCPeerID) {
		
		print("\(self): \(peer.displayName) changed session state: \(sessionState.rawValue)")
		if sessionState == .connected {
			DispatchQueue.main.sync {
				if peer.isEqual(hostPeerID) {
					print(" - connected to \(peer.displayName)")
					/* TODO: Send a special verification ping. If it doesn't come back we need to restart
					self.send("Verification message") { error in
						if let error = error {
							print("error sending verification to \(peer): \(error)")
						} else { // TODO: Consider a special verification exchange message
//							DispatchQueue.main.sync {
//								self.nearbyServiceBrowser = nil // This is still too soon
//							}
						}
					}
//					self.nearbyServiceBrowser = nil // No need to browse anymore (this happens too soon -- we need to have some sort of delay)
					*/
				}
				if let session = messageManager.sessionProvider, session.connectedPeers.count == kMCSessionMaximumNumberOfPeers {
					// This could happen too soon, stopping the current connection (let's have a delay)
					self.nearbyServiceAdvertiser = nil
					self.nearbyServiceBrowser = nil
				}
			}
		}
		if sessionState == .notConnected {
			DispatchQueue.main.sync {
				self.peersInPlay[peer] = nil
				if peer.isEqual(self.hostPeerID) {
					print(" - host \(String(describing: hostPeerID?.displayName)) is gone")
					self.hostPeerID = nil
				}
				if self.shouldStartListening {
					self.nearbyServiceAdvertiser = nil
					self.nearbyServiceAdvertiser = nil
					if messageManager.sessionProvider == nil || messageManager.sessionProvider!.connectedPeers.count == 0 {
						self.resetSession()
					}
					self.perform(#selector(startBrowsing), with: nil, afterDelay: 2.0)
				}
			}
		}
		delegate?.conversationManager(self, changed: sessionState, with: peer)
	}
	
	public func messageManager(_ messageManager: MultipeerMessageManager, encountered error: Error, decodingMessageFrom peer: MCPeerID) {
		// TODO: Consider logging this
	}
	
	public func messageManager(_ messageManager: MultipeerMessageManager, encountered error: Error, receivingResource identifier: UUID, from peer: MCPeerID) {
		// TODO: Consider logging this
	}
	
	public func messageManager(_ messageManager: MultipeerMessageManager, received payload: MultipeerMessagePayload, from peer: MCPeerID) {
		if let message = String(data: payload.data, encoding: .utf8) {
			delegate?.conversationManager(self, received: message, from: peer)
		} else {
			// TODO: We may want to log this
		}
	}
}
