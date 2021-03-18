//
//  SharedEventInterfaceController.swift
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

import ClockKit
import Intents
import ResolveKit

final class SharedEventInterfaceController: CoreViewController {

	@Service var cloudService: CloudKitService
	@Service var dataService: CoreDataService

	// MARK: - Interface Builder items

	@IBOutlet var createdAtLabel: WKInterfaceLabel!
	@IBOutlet var createdByLabel: WKInterfaceLabel!
	@IBOutlet var uniqueIDLabel: WKInterfaceLabel!

	@IBOutlet var deleteButton: WKInterfaceButton!

	@IBAction func deleteButtonTapped() {
		// TODO: When the delete button is tapped, delete the sharedEvent
	}

	// MARK: - CoreViewController overrides

	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		if let sharedEvent = context as? SharedEvent {
			applySharedEvent(sharedEvent)
		} else { // What else? (this should never happen)
			deleteButton.setEnabled(false)
		}
	}

	// MARK: - Private properties and methods

	var sharedEventObjectID: NSManagedObjectID?

	func applySharedEvent(_ sharedEvent: SharedEvent) {
		sharedEventObjectID = sharedEvent.objectID
		if let createdLocallyAt = sharedEvent.createdLocallyAt {
			let createdAtText = DateFormatter.localizedString(from: createdLocallyAt, dateStyle: .short, timeStyle: .medium)
			createdAtLabel.setText(createdAtText)
		} else {
			createdAtLabel.setHidden(true)
		}
		createdByLabel.setText(sharedEvent.createdByDevice)
		uniqueIDLabel.setText(sharedEvent.uniqueIdentifier ?? "<none>")
	}
}
