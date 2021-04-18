//
//  SettingsTableViewController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2016 The App Studio LLC.
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
import WatchConnectivity

extension SettingsTableViewController {

	public func settingsSequeIdentifier(for customActivityType: CustomActivityType) -> SegueIdentifier {
		switch customActivityType {
		case .alternateIcons: return .showAlternateIcons
		case .beacon: return .showBeacon
		case .camera: return .showCamera
		case .cloudKit: return .showCloudKit
		case .conversation: return .showConversation
		case .coreData, .createSharedEventIntent: return .showCoreData
		case .homeKit: return .showHomeKit
		case .layout: return .showLayout
		case .map: return .showMap
		case .photos: return .showPhotos
		case .watchConnectivity: return .showWatchConnectivity
		}
	}

	class func shouldDisableCell(at indexPath: IndexPath) -> Bool {
		// Disable any cells that we cannot identify as a CellType
		guard let cellType = CellType(rawValue: indexPath.row) else { return true }

		#if targetEnvironment(macCatalyst)
		let isCatalyst = true
		#else
		let isCatalyst = false
		#endif

		switch cellType {
		case .alternateIcons:
			guard #available(iOS 10.3, tvOS 10.2, *) else { return true }
			return isCatalyst
		case .beacon:
			guard #available(macCatalyst 14.0, *) else { return true }
		case .camera:
			if #available(iOS 11.0, *) { return true }
		case .cameraML:
			guard #available(iOS 11.0, *) else { return true }
			return isCatalyst
		case .homeKit:
			guard #available(macCatalyst 14.0, *) else { return true }
		case .watchConnectivity:
			return isCatalyst
		default:
			return false
		}
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
		case alternateIcons
		case beacon
		case camera
		case cameraML
		case cloudKit
		case conversation
		case coreData
		case homeKit
		case layout
		case map
		case photos
		case watchConnectivity
	}
}

extension SettingsTableViewController: CoreSegueHandling {

	internal enum SegueIdentifier: String, CaseIterable {
		case showAlternateIcons
		case showBeacon
		case showCamera
		case showCameraML
		case showCloudKit
		case showConversation
		case showCoreData
		case showHomeKit
		case showLayout
		case showMap
		case showPhotos
		case showWatchConnectivity
	}
}
