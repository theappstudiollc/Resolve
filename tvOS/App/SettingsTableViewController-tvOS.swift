//
//  SettingsTableViewController-tvOS.swift
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

import ResolveKit

extension SettingsTableViewController {

	public func settingsSequeIdentifier(for customActivityType: CustomActivityType) -> SegueIdentifier {
		switch customActivityType {
		case .conversation: return .showConversation
		case .coreData: return .showCoreData
		case .homeKit: return .showHomeKit
		case .iBeacon: return .showIBeacon
		case .photos: return .showPhotos
		}
	}

	class func shouldDisableCell(at indexPath: IndexPath) -> Bool {
		return false
	}

	func showDefaultDetailViewController(_ sender: Any?) {
		let defaultCellIndex = CellType.coreData.rawValue
		let row = hideDisabledRows ? rowMappings.firstIndex(of: defaultCellIndex)! : defaultCellIndex
		let indexPath = IndexPath(row: row, section: 0)
		tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
		performSegue(withIdentifier: .showCoreData, sender: sender)
	}
}


extension SettingsTableViewController: SettingsTableCell {

	enum CellType: Int, CaseIterable {
		case conversation
		case coreData
		case homeKit
		case iBeacon
		case photos
	}
}

extension SettingsTableViewController: CoreSegueHandling {

	internal enum SegueIdentifier: String, CaseIterable {
		case showConversation
		case showCoreData
		case showHomeKit
		case showIBeacon
		case showPhotos
	}
}
