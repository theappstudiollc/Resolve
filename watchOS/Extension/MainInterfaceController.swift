//
//  ResolveInterfaceController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2021 The App Studio LLC.
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

final class MainInterfaceController: ResolveViewController {

	@IBOutlet var table: WKInterfaceTable!

	func restoreControllerFor(userActivity: CustomActivityType, with userInfo: [AnyHashable : Any]?) {
		// TODO: Determine if we're already on the correct controller, and in that case provide the userInfo (devise a mechanism to do so)
		popToRootController()
		switch userActivity {
		case .coreData: pushController(withName: "CoreData", context: userInfo)
		case .watchConnectivity: pushController(withName: "WatchConnectivity", context: userInfo)
		}
	}

	// MARK: - ResolveViewController overrides

	override init() {
		super.init()
		table.setRowTypes(["complicationCell", "coreDataCell", "nowPlayingCell", "watchConnectivityCell"])
	}
}
