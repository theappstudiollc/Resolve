//
//  HomeKitHomeTableViewCell.swift
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

#if canImport(HomeKit)

import HomeKit

@available(macCatalyst 14.0, *)
final class HomeKitHomeTableViewCell: UITableViewCell {
	
	// MARK: - Public properties
	
	var home: HMHome! {
		didSet { updateHome() }
	}
	
	// MARK: - Private properties and methods
	
	func updateHome() {
		guard let textLabel = textLabel else { return }
		var states = [String]()
		if home.isPrimary {
			states.append("primary")
		}
		#if targetEnvironment(macCatalyst)
		if home.homeHubState == .connected {
			states.append("connected")
		}
		#else
		if #available(iOS 11.0, tvOS 11.0, *) {
			if home.homeHubState == .connected {
				states.append("connected")
			}
		}
		#endif
		if states.count > 0 {
			textLabel.text = "\(home.name) (\(states.joined(separator: ", ")))"
		} else {
			textLabel.text = home.name
		}
	}
}

#endif
