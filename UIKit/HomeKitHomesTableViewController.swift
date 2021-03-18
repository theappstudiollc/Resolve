//
//  HomeKitHomesTableViewController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2017 The App Studio LLC.
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

#if canImport(HomeKit)

import CoreResolve
import HomeKit

@available(macCatalyst 14.0, *)
final class HomeKitHomesTableViewController: CoreTableViewController {
	
	// MARK: - CoreTableViewController overrides
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if let homeKitHomeTableViewController = segue.destination as? HomeKitHomeTableViewController, let homeTableViewCell = sender as? HomeKitHomeTableViewCell {
			homeKitHomeTableViewController.home = homeTableViewCell.home
		}
	}
	
	override func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
		return homes.count > 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard homes.count > 0 else {
			return tableView.dequeueReusableCell(withIdentifier: "HomeKitNoHomesTableViewCell", for: indexPath)
		}
		let cell = tableView.dequeueReusableCell(withIdentifier: "\(HomeKitHomeTableViewCell.self)", for: indexPath)
		if let homeCell = cell as? HomeKitHomeTableViewCell {
			homeCell.home = homes[indexPath.row]
		}
		return cell
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return max(1, homes.count)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		homeManager = HMHomeManager()
	}
	
	// MARK: - Private properties
	
	fileprivate var homeManager: HMHomeManager! {
		willSet { homeManager?.delegate = nil }
		didSet { homeManager?.delegate = self }
	}
	private var homes = [HMHome]()

	// MARK: - Private methods
	
	fileprivate func addHome(_ home: HMHome) {
		guard !homes.contains(home) else { return }
		let insertAt = homes.firstIndex(where: { $0.name > home.name }) ?? 0
		homes.insert(home, at: insertAt)
		tableView.insertRows(at: [IndexPath(row: insertAt, section: 0)], with: .automatic)
	}
	
	fileprivate func removeHome(_ home: HMHome) {
		guard let removeAt = homes.firstIndex(of: home) else { return }
		homes.remove(at: removeAt)
		tableView.deleteRows(at: [IndexPath(row: removeAt, section: 0)], with: .automatic)
	}
	
	fileprivate func replaceHomes(_ homes: [HMHome]) {
		self.homes = homes.sorted(by: { $0.name < $1.name })
		tableView.reloadData()
	}
}

@available(macCatalyst 14.0, *)
extension HomeKitHomesTableViewController: HMHomeManagerDelegate {
	
	func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
		guard manager == homeManager else { return }
		addHome(home)
	}
	
	func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
		guard manager == homeManager else { return }
		removeHome(home)
	}
	
	func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
		guard manager == homeManager else { return }
		replaceHomes(manager.homes)
	}
	
	func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
		guard manager == homeManager else { return }
		print("homeManagerDidUpdatePrimaryHome: \(manager)")
		tableView.reloadData()
	}
}

#endif
