//
//  MultipeerConversationManager-MCNearbyServiceBrowserDelegate.swift
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

extension MultipeerConversationManager: MCNearbyServiceBrowserDelegate {
	
	public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
		print("\(self) did not start browsing: \(error)")
		if shouldStartListening {
			nearbyServiceAdvertiser = nil
			nearbyServiceBrowser = nil
			resetSession()
			perform(#selector(startBrowsing), with: nil, afterDelay: 2.0)
		}
	}
	
	public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
		guard let info = info, let peerSessionIdentifier = info["IDENTIFIER"] else {
			return // We don't know who this is
		}
		guard let session = messageManager.sessionProvider as? MCSession else {
			return // We're not in a good state. // TODO: Consider logging this
		}
		print("Comparing:\n\(peerSessionIdentifier): \(peerID.displayName)\n\(discoveryIdentifier.uuidString): \(browser.myPeerID.displayName)")
		peersInPlay[peerID] = UUID(uuidString: peerSessionIdentifier)
		if peerSessionIdentifier > discoveryIdentifier.uuidString {
			// The remote peer is "greater than" the local peer (this one won't be advertising)
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startAdvertising), object: nil)
			if nearbyServiceAdvertiser != nil {
				print("No longer advertising...")
			}
			nearbyServiceAdvertiser = nil
			let maxUUIDString = peersInPlay.values.map({ $0.uuidString }).max()
			if peerSessionIdentifier.isEqual(maxUUIDString) {
				if session.connectedPeers.contains(peerID), !peerID.isEqual(hostPeerID) {
					// TODO: We need to use verifications to know this is in fact true
					print("Not sending invite: \(peerID.displayName) is already connected")
					hostPeerID = peerID
//					nearbyServiceBrowser = nil // This causes problems
				} else if hostPeerID == nil {
					print("Sending invite to new host: \(peerID.displayName)")
					browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15)
					hostPeerID = peerID
				} else {
					print("Waiting for host (\(hostPeerID!.displayName)) to invite \(peerID.displayName)")
//					nearbyServiceAdvertiser = nil // This causes problems
				}
			} else {
				print("\(self) not sending invite: \(peerID.displayName) is not a host")
			}
		} else {
			print("\(self) not sending invite: \(peerID.displayName) is not a host")
			// This device _may_ be the host -- let's try advertising sooner
			perform(#selector(startAdvertising), with: nil, afterDelay: 2.0)
		}
	}
	
	public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
		// Thank you for letting me know
		print("\(self) lost \(peerID.displayName)")
		peersInPlay[peerID] = nil
		delegate?.conversationManagerRefreshedStatus(self)
	}
}
