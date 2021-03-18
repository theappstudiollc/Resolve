//
//  BeaconsTableViewController.swift
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

import CoreLocation
import ResolveKit

final class BeaconTableViewCell: TableViewCell {

	fileprivate var beacon: RangedBeacon? {
		didSet { updateBeacon() }
	}

	fileprivate func updateBeacon() {
		guard let beacon = beacon else {
			self.textLabel?.text = nil
			self.detailTextLabel?.text = nil
			return
		}
		self.textLabel?.text = "Beacon: \(beacon.major).\(beacon.minor)"
		if beacon.proximity == .unknown {
			self.detailTextLabel?.text = "Distance: unknown"
		} else {
			self.detailTextLabel?.text = "Distance: \(proximityDescription(beacon.proximity)) +/- \(beacon.accuracy)m"
		}
	}

	func proximityDescription(_ proximity: CLProximity) -> String {
		switch proximity {
		case .far: return "far"
		case .immediate: return "immediate"
		case .near: return "near"
		case .unknown: return "unknown"
		@unknown default:
			fatalError()
		}
	}
}

final class BeaconsTableView: ResolveTableView { }

extension BeaconsTableView: CoreCellDequeuing {

	public enum CellIdentifier: String {
		case beacon
	}
}

final class BeaconsTableViewController: TypedTableViewController<RangedBeacon, BeaconsTableView> {

	public func apply(_ beacons: [CLBeacon]) {
		apply(beacons.map { RangedBeacon($0) }, reloadRemaining: true)
	}

	override func tableView(_ tableView: BeaconsTableView, cellFor result: RangedBeacon, at indexPath: IndexPath) -> TableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: .beacon, for: indexPath)
		if let beaconTableViewCell = cell as? BeaconTableViewCell {
			beaconTableViewCell.beacon = result
		}
		return cell
	}
}
