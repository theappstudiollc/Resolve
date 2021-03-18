//
//  MultipeerSettingsManager.swift
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

#if canImport(MultipeerConnectivity)

import Foundation
import ResolveKit
import MultipeerConnectivity

final class MultipeerSettingsManager: UserDefaultsSettingsManager, MultipeerSettingsService {

	// MARK: - UserDefaultsSettingsManager overrides

	required init(appBundle: Bundle = .main, userDefaults: UserDefaults = .standard) {
		self.appBundle = appBundle
		super.init(userDefaults: userDefaults)
	}

	// MARK: - MultipeerSettingsService properties

	var bonjourServiceType: String {
		let appName = appBundle.object(forInfoDictionaryKey: "CFBundleName") as! String
		return appName.lowercased()
	}

	var discoveryIdentifier: UUID {
		#if os(iOS) || os(tvOS)
			return UIDevice.current.identifierForVendor!
		#elseif os(macOS)
			return UUID()
		#endif
	}

	var peerID: MCPeerID? {
		get {
			guard let data = userDefaults.data(forKey: settingsKeyPeerID) else { return nil }
			return try? data.secureDecode(MCPeerID.self)
		}
		set {
			if let peerID = newValue {
				try! userDefaults.secureEncode(peerID, forKey: settingsKeyPeerID)
			} else {
				userDefaults.removeObject(forKey: settingsKeyPeerID)
			}
		}
	}

	// MARK: - Private properties and methods

	let appBundle: Bundle
	let settingsKeyPeerID = "MultipeerSettingsKey.PeerID"
}

#endif
