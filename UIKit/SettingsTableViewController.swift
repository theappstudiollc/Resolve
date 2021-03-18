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

protocol SettingsTableCell {

	associatedtype CellType: CaseIterable

	static func shouldDisableCell(at indexPath: IndexPath) -> Bool
}

class SettingsTableViewController: CoreTableViewController {

	@Service var userActivityService: UserActivityService

	let hideDisabledRows = true

	// MARK: - CoreTableViewController overrides

	required init?(coder: NSCoder) {
		rowMappings = CellType.allCases.compactMap { cellType in
			return Self.shouldDisableCell(at: IndexPath(row: cellType.rawValue, section: 0)) ? nil : cellType.rawValue
		}
		super.init(coder: coder)
	}

	override func performSegue(withIdentifier identifier: String, sender: Any?) {
		lastSegueIdentifier = identifier
		super.performSegue(withIdentifier: identifier, sender: sender)
	}

	override func restoreUserActivityState(_ activity: NSUserActivity) {
		super.restoreUserActivityState(activity)
		guard let activityType = userActivityService.activityType(with: activity.activityType) else { return }
		let segueIdentifier = settingsSequeIdentifier(for: activityType)
		guard lastSegueIdentifier != segueIdentifier.rawValue else { return }
		performSegue(withIdentifier: segueIdentifier, sender: self)
	}

	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		// TODO: Test this against scenarios where the SplitViewController might collapse the detail view controller
		let retVal = identifier != lastSegueIdentifier
		lastSegueIdentifier = identifier
		/* This does not appear to be necessary anymore
		if !retVal, let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: true)
		}
		*/
		return retVal
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard !hideDisabledRows else {
			let mappedIndexPath = IndexPath(row: rowMappings[indexPath.row], section: indexPath.section)
			return super.tableView(tableView, cellForRowAt: mappedIndexPath)
		}
		let cell = super.tableView(tableView, cellForRowAt: indexPath) as! SettingsTableViewCell
		if Self.shouldDisableCell(at: indexPath) {
			cell.accessibilityHint = NSLocalizedString("accessibility.feature.disabled", comment: "This feature is currently disabled")
			cell.isUserInteractionEnabled = false
			cell.textLabel?.textColor = UIColor.lightGray
		}
		return cell
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard !hideDisabledRows else { return rowMappings.count }
		return super.tableView(tableView, numberOfRowsInSection: section)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		lastSegueIdentifier = nil
	}

	// MARK: - Private properties and methods

	private(set) var lastSegueIdentifier: String?

	let rowMappings: [Int]
}
