//
//  MultipeerConversationManager-MCNearbyServiceAdvertiserDelegate.swift
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

extension MultipeerConversationManager: MCNearbyServiceAdvertiserDelegate {
	
	public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
		print("\(self) did not start advertising: \(error)")
	}
	
	public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
		let accept = true // hostPeerID == nil //![self.session.connectedPeers containsObject:peerID];
//		print("\(accept ? "Accepting" : "Not accepting") \(peerID.displayName)")
		invitationHandler(accept, messageManager.sessionProvider as? MCSession)
	}
}
