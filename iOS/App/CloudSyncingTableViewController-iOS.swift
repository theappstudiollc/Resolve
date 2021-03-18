//
//  CloudSyncingTableViewController-iOS.swift
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

extension CloudSyncingTableViewController {

	@available(macCatalyst, deprecated: 13.0)
	func editActions(forRowAt indexPath: IndexPath, in tableView: TableViewType) -> [UITableViewRowAction] {
		let syncableEntity = source.fetchedResultsController.object(at: indexPath)
		guard let objectID = deletableObjectID(for: syncableEntity) else { return [] }
		let action = UITableViewRowAction(style: .destructive, title: "Delete") { action, indexPath in
			self.deleteSyncableEntity(with: objectID)
		}
		return [action]
	}

	@available(iOS 11.0, *)
	func swipeActions(forRowAt indexPath: IndexPath, in tableView: TableViewType) -> UISwipeActionsConfiguration {
		let syncableEntity = source.fetchedResultsController.object(at: indexPath)
		guard let objectID = deletableObjectID(for: syncableEntity) else { return UISwipeActionsConfiguration(actions: []) }
		// If there are deletes or adds while this action is open we can attempt to remove something that is no longer valid
		// We should therefore obtain the object ID and using that as the parameter to deleteObject(at:)
		let action = UIContextualAction(style: .destructive, title: "Delete") { [userInputService] action, view, resultHandler in
			self.deleteSyncableEntity(with: objectID) { result in
				switch result {
				case .success(let deleted):
					resultHandler(deleted)
				case .failure(let error):
					resultHandler(false)
					userInputService.presentAlert(error.localizedDescription, withTitle: "Error Deleting Row", from: tableView, forDuration: 2.0)
				}
			}
		}
		return UISwipeActionsConfiguration(actions: [action])
	}

 	@discardableResult func prepareSearchController() -> Bool {
		guard supportsSearching, searchController == nil, let searchResultsUpdater = self as? UISearchResultsUpdating else { return false }

		let searchController = UISearchController(searchResultsController: nil)
		if #available(iOS 9.1, tvOS 9.1, *) {
			searchController.obscuresBackgroundDuringPresentation = false
		} else {
			searchController.dimsBackgroundDuringPresentation = false
		}
		searchController.searchBar.autocapitalizationType = .none
		searchController.searchResultsUpdater = searchResultsUpdater
		self.searchController = searchController
		return true
	}

	func setupSearchController(useNavigationItem: Bool) {
		guard let searchController = self.searchController else { return }
		if #available(iOS 11.0, *), useNavigationItem {
			navigationItem.searchController = searchController
		} else {
			tableView.tableHeaderView = searchController.searchBar
		}
	}
}
