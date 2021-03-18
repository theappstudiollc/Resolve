//
//  AlternateIconTableViewController.swift
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

final class AlternateIconTableViewCell: UITableViewCell {

	@IBOutlet var iconImageNameLabel: UILabel!
	@IBOutlet var iconImageView: UIImageView!

	func setImage(_ image: UIImage?, with name: String) {
		iconImageNameLabel.text = name
		iconImageView.image = image
	}
}

final class AlternateIconTableView: ResolveTableView { }

extension AlternateIconTableView: CoreCellDequeuing {

	public enum CellIdentifier: String {
		case icon
	}
}

final class AlternateIconTableViewController: ResolveTableViewController {

	@Service var appIconService: AppIconService
	@Service var loggingService: CoreLoggingService

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1 + appIconService.alternateIconNames.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let tableView = tableView as? AlternateIconTableView, let cell = tableView.dequeueReusableCell(withIdentifier: .icon, for: indexPath) as? AlternateIconTableViewCell else { fatalError() }
		let appIcon: AppIcon = indexPath.row == 0 ? .default : .alternate(appIconService.alternateIconNames[indexPath.row - 1])
		let image = try? appIconService.image(for: appIcon)
		cell.setImage(image, with: appIcon.cellImageName)
		cell.accessoryType = appIconService.currentAppIcon == appIcon ? .checkmark : .none
		cell.selectionStyle = appIconService.currentAppIcon == appIcon ? .none : .default
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath), cell.selectionStyle != .none else { return }
		let appIcon: AppIcon = indexPath.row == 0 ? .default : .alternate(appIconService.alternateIconNames[indexPath.row - 1])
		appIconService.setAppIcon(appIcon) { [loggingService] result in
			tableView.deselectRow(at: indexPath, animated: true)
			switch result {
			case .success:
				loggingService.debug("Successfully applied app icon: %{public}@", appIcon.cellImageName)
				cell.accessoryType = .checkmark
				cell.selectionStyle = .none
				tableView.visibleCells.forEach { otherCell in
					guard cell !== otherCell else { return }
					otherCell.accessoryType = .none
					otherCell.selectionStyle = .default
				}
			case .failure(let error):
				loggingService.log(.error, "Failed to apply icon %{public}@: %{public}@", appIcon.cellImageName, error.localizedDescription)
			}
		}
	}
}

fileprivate extension AppIcon {

	var cellImageName: String {
		switch self {
		case .default: return "default"
		case .alternate(let name): return name
		}
	}
}
