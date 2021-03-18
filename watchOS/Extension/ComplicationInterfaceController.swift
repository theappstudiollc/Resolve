//
//  ComplicationInterfaceController.swift
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

import ClockKit
import ResolveKit

final class ComplicationInterfaceController: ResolveViewController {

	@Service var complicationService: ComplicationService
	@Service var dataService: DataService
	@Service var inputService: UserInputService

	// MARK: - Interface Builder items

	@IBOutlet var reloadComplicationsButton: WKInterfaceButton!
	@IBOutlet var reloadDesciptorsButton: WKInterfaceButton!
	@IBOutlet var statusLabel: WKInterfaceLabel!

	@IBAction func reloadComplicationsButtonTapped() {
		do {
			let tapCount = try dataService.getTapCount()
			complicationService.updateTapCount(tapCount, forceReload: true)
		} catch {
			inputService.presentError(error, withTitle: "Error", from: self)
		}
	}

	@available(watchOS 7.0, *)
	@IBAction func reloadDescriptorsButtonTapped() {
		complicationService.reloadDescriptors()
	}

	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		if #available(watchOS 7.0, *) {
			reloadDesciptorsButton.setEnabled(true)
		} else {
			reloadDesciptorsButton.setHidden(true)
		}
		updateStatusLabel()
	}

	func updateStatusLabel() {
		guard let activeComplications = CLKComplicationServer.sharedInstance().activeComplications else {
			statusLabel.setText("No active complications")
			return
		}
		if #available(watchOS 7.0, *) {
			#if swift(>=5.3) // Xcode 12.x
			var count = 0
			let allComplications = activeComplications.reduce(into: [String:[CLKComplicationFamily]](), { result, complication in
				result[complication.identifier] = (result[complication.identifier] ?? []) + [complication.family]
				count = result.count
			}).map { pair -> String in
				let identifiers = "\(pair.value.map({ $0.debugDescription }).joined(separator: ", "))"
				guard count > 1 else { return identifiers }
				return "\(pair.key): " + identifiers
			}
			statusLabel.setText("Active complications: \(allComplications.joined(separator: " & "))")
			#endif
		} else {
			let allComplications = activeComplications.map({ $0.family.debugDescription }).joined(separator: ", ")
			statusLabel.setText("Active complications: \(allComplications)")
		}
	}
}

extension CLKComplicationFamily: CustomDebugStringConvertible {

	public var debugDescription: String {
		switch self {
		case .circularSmall: return "Circular Small"
		case .extraLarge: return "Extra Large"
		case .graphicBezel: return "Graphic Bezel"
		case .graphicCircular: return "Graphic Circular"
		case .graphicCorner: return "Graphic Corner"
		#if swift(>=5.3) // Xcode 12.x
		case .graphicExtraLarge: return "Graphic Extra Large"
		#endif
		case .graphicRectangular: return "Graphic Rectangular"
		case .modularLarge: return "Modular Large"
		case .modularSmall: return "Modular Small"
		case .utilitarianLarge: return "Utilitarian Large"
		case .utilitarianSmall: return "Utilitarian Small"
		case .utilitarianSmallFlat: return "Utilitarian Small Flat"
		@unknown default: return "Unknown"
		}
	}
}
