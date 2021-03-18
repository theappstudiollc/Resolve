//
//  HomeKitHomeTableViewController.swift
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
final class HomeKitHomeTableViewController: CoreTableViewController {
	
	// MARK: - Interface Builder properties and methods
	
	@IBOutlet private weak var twerkBulbsButton: UIBarButtonItem!
	@IBAction private func twerkBulbsButtonTapped(_ sender: UIBarButtonItem) {
		switch twerkStatus {
		case .off:
			startTwerking(cycleMilliseconds: desiredCycleMilliseconds())
		case .on(let token):
			stopTwerking(forToken: token)
		}
	}
	
	// MARK: - Public properties
	
	var home: HMHome? {
		willSet { home?.delegate = nil }
		didSet {
			home?.delegate = self
			updateHome()
		}
	}
	
	// MARK: - CoreTableViewController overrides
	
	deinit {
		bulbs.forEach { $0.enableColorNotifications(false) }
	}
	
	override var preferredFocusEnvironments: [UIFocusEnvironment] {
		guard let navigationController = navigationController else { return super.preferredFocusEnvironments }
		return [navigationController.navigationBar]
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let identifier = "HomeKitLightbulbTableViewCell"
		let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
		if let accessoryCell = cell as? HomeKitLightbulbTableViewCell {
			accessoryCell.accessory = bulbs[indexPath.row]
		}
		return cell
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return bulbs.count
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let cell = tableView.cellForRow(at: indexPath) as? HomeKitLightbulbTableViewCell else { return }
		let accessory = bulbs[indexPath.row]
		if twerkStatus != TwerkStatus.off, let errors = cell.errors, errors.count > 0 {
			cell.errors = nil
			twerk(bulb: accessory, forcePower: true, cycleMilliseconds: desiredCycleMilliseconds())
		} else {
			accessory.identify { error in
				cell.errors = error == nil ? nil : [error!]
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		updateHome()
		updateTwerkBulbsButton()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		switch twerkStatus {
		case .off: break
		case .on(let token):
			if isBeingDismissed || isMovingFromParent {
				stopTwerking(forToken: token)
			}
		}
	}
	
	// MARK: - Private properties
	
	private enum TwerkStatus: Equatable {
		case off
		case on(token: Int)
		
		static func ==(lhs: TwerkStatus, rhs: TwerkStatus) -> Bool {
			switch (lhs, rhs) {
			case (.off, .off):
				return true
			case (.on(let leftToken), .on(let rightToken)):
				return leftToken == rightToken
			default:
				return false
			}
		}
	}
	
	private var bulbs = [HMAccessory]()
	private var currentTwerkToken: Int = 0
	private var savedColors = [UUID : UIColor]()
	private var savedPowerStates = [UUID : Bool]()
	private var twerkStatus = TwerkStatus.off {
		didSet { updateTwerkBulbsButton() }
	}
	
	// MARK: - Private methods
	
	fileprivate func addAccessory(_ accessory: HMAccessory) {
		guard accessory.isColorLightBulb(), !bulbs.contains(accessory) else { return }
		let insertAt = bulbs.firstIndex(where: { $0.lightBulbName() > accessory.lightBulbName() }) ?? 0
		bulbs.insert(accessory, at: insertAt)
		tableView.insertRows(at: [IndexPath(row: insertAt, section: 0)], with: .automatic)
		accessory.enableColorNotifications(true)
	}
	
	private func cell(forBulb bulb: HMAccessory) -> HomeKitLightbulbTableViewCell? {
		return tableView.visibleCells.filter({ $0 is HomeKitLightbulbTableViewCell })
			.map({ $0 as! HomeKitLightbulbTableViewCell })
			.first(where: { $0.accessory == bulb })
	}
	
	private func desiredCycleMilliseconds() -> Int {
		return bulbs.count * 660 // 2000
	}

	fileprivate func removeAccessory(_ accessory: HMAccessory) {
		guard let removeAt = bulbs.firstIndex(of: accessory) else { return }
		accessory.enableColorNotifications(false)
		bulbs.remove(at: removeAt)
		tableView.deleteRows(at: [IndexPath(row: removeAt, section: 0)], with: .automatic)
	}
	
	fileprivate func replaceAccessories(_ accessories: [HMAccessory]) {
		bulbs.forEach { $0.enableColorNotifications(false) }
		bulbs = accessories.filter({ $0.isColorLightBulb() }).sorted(by: { $0.lightBulbName() < $1.lightBulbName() })
		bulbs.forEach { $0.enableColorNotifications(true) }
		tableView.reloadData()
	}
	
	private func startTwerking(cycleMilliseconds: Int) {
		srand48(Int(Date.timeIntervalSinceReferenceDate))
		let delay: Int = cycleMilliseconds / bulbs.count
		savedColors.removeAll(keepingCapacity: true)
		savedPowerStates.removeAll(keepingCapacity: true)
		twerkStatus = .on(token: currentTwerkToken)
		for (index, bulb) in bulbs.enumerated() {
			guard let lightBulbService = bulb.service(ofType: HMServiceTypeLightbulb),
				let powerStateCharacteristic = lightBulbService.characteristic(ofType: HMCharacteristicTypePowerState),
				let powerState = powerStateCharacteristic.value as? Bool else {
					continue
			}
			if let savedColor = bulb.lightBulbColor() {
				savedColors[bulb.uniqueIdentifier] = savedColor
			}
			savedPowerStates[bulb.uniqueIdentifier] = powerState
			/*
			for service in bulb.services {
				print("service \(service.serviceDescription())")
				for characteristic in service.characteristics {
					if let value = characteristic.value {
						print(" - \(characteristic.charactersticDescription()) = \(value)")
					} else {
						print(" - \(characteristic.charactersticDescription())")
					}
				}
			}
			*/
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(index * delay)) {
				self.twerk(bulb: bulb, forcePower: true, cycleMilliseconds: cycleMilliseconds)
			}
		}
	}
	
	private func stopTwerking(forToken token: Int) {
		twerkStatus = .off
		currentTwerkToken = token + 1
		for bulb in bulbs {
			let group = DispatchGroup()
			var errors = [Error]()
			if let savedColor = savedColors[bulb.uniqueIdentifier] {
				group.enter()
				bulb.assignColor(savedColor, forcePower: false) { colorErrors in
					defer { group.leave() }
					errors.append(contentsOf: colorErrors)
				}
			}
			if let savedPowerState = savedPowerStates[bulb.uniqueIdentifier],
				let lightBulbService = bulb.service(ofType: HMServiceTypeLightbulb),
				let powerStateCharacteristic = lightBulbService.characteristic(ofType: HMCharacteristicTypePowerState),
				let powerState = powerStateCharacteristic.value as? Bool,
				powerState != savedPowerState {
				group.enter()
				powerStateCharacteristic.writeValue(savedPowerState) { error in
					defer { group.leave() }
					guard let error = error else { return }
					errors.append(error)
				}
			}
			DispatchQueue.global().async {
				group.wait()
				DispatchQueue.main.async {
					if errors.count > 0, let cell = self.cell(forBulb: bulb) {
						cell.errors = errors
					}
				}
			}
		}
	}
	
	private func twerk(bulb: HMAccessory, forcePower: Bool, cycleMilliseconds: Int) {
		guard twerkStatus == .on(token: currentTwerkToken) else {
			print("twerkStatus doesn't match (\(currentTwerkToken)): skipping assignment")
			return
		}
		bulb.assignRandomColor(forcePower: forcePower) { errors in
			guard errors.count == 0 else {
				if let cell = self.cell(forBulb: bulb) {
					cell.errors = errors
				} else {
					print("Done assigning random color to \(bulb.lightBulbName()). Errors: \(errors)")
				}
				return
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(cycleMilliseconds)) {
				self.twerk(bulb: bulb, forcePower: false, cycleMilliseconds: cycleMilliseconds)
			}
		}
	}

	private func updateHome() {
		guard isViewLoaded, let home = home else { return }
		replaceAccessories(home.accessories)
		title = home.name
	}
	
	private func updateTwerkBulbsButton() {
		guard isViewLoaded else { return }
		switch twerkStatus {
		case .off:
			twerkBulbsButton.title = "Twerk"
		case .on(_):
			twerkBulbsButton.title = "Stop"
		}
	}
}

@available(macCatalyst 14.0, *)
extension HMAccessory {
	
	func lightBulbName() -> String {
		#if targetEnvironment(macCatalyst)
		if let primaryService = services.first(where: { $0.isPrimaryService }) {
			return primaryService.name
		}
		#else
		if #available(iOS 10, *), let primaryService = services.first(where: { $0.isPrimaryService }) {
			return primaryService.name
		}
		#endif
		if let lightbulbService = service(ofType: HMServiceTypeLightbulb) {
			return lightbulbService.name
		}
		return name
	}
}

@available(macCatalyst 14.0, *)
extension HomeKitHomeTableViewController: HMHomeDelegate {
	
	func homeDidUpdateName(_ home: HMHome) {
		title = home.name
	}
	
	func home(_ home: HMHome, didAdd accessory: HMAccessory) {
		addAccessory(accessory)
	}
	
	func home(_ home: HMHome, didRemove accessory: HMAccessory) {
		removeAccessory(accessory)
	}
}

#endif
