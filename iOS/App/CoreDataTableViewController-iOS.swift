//
//  CoreDataViewController-iOS.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2019 The App Studio LLC.
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

extension CoreDataTableViewController {
	
	@IBAction func columnSliderChanged(_ sender: UISlider?) {
		guard let slider = sender else { return }
		sourceTableView.beginUpdates()
		sourceTableView.currentRatio = slider.value
		sourceTableView.endUpdates()
	}
}

extension CoreDataTableViewController: UISearchResultsUpdating {

	private func predicate(for searchController: UISearchController) -> NSPredicate {
		guard let searchText = searchController.searchBar.text, searchText.count > 0 else {
			return CoreDataTableViewController.defaultPredicate
		}
		let searchPredicate = NSPredicate(format: "%K CONTAINS[c] %@", #keyPath(SharedEvent.createdByDevice), searchText)
		return NSCompoundPredicate(andPredicateWithSubpredicates: [CoreDataTableViewController.defaultPredicate, searchPredicate])
	}

	func updateSearchResults(for searchController: UISearchController) {
		try! updatePredicate(predicate(for: searchController))
	}
}
