//
//  HomeKitLightbulbTableViewCell.swift
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

import HomeKit

@available(macCatalyst 14.0, *)
final class HomeKitLightbulbTableViewCell: UITableViewCell {
	
	// MARK: - Interface Builder properties and methods

	@IBOutlet private weak var accessoryNameLabel: UILabel!
	@IBOutlet private weak var accessoryColorView: UIView!

	// MARK: - Public properties
	
	var accessory: HMAccessory! {
		willSet { accessory?.delegate = nil }
		didSet {
			accessory?.delegate = self
			updateAccessory()
		}
	}
	
	var errors: [Error]? {
		didSet { updateAccessory() }
	}
	
	// MARK: - Public methods
	
	func updateBackground() {
		guard let accessory = accessory else { return }
		accessoryColorView.backgroundColor = accessory.lightBulbColor(withAlpha: 1)
	}

	// MARK: - UITableViewCell overrides
	
	override func awakeFromNib() {
		super.awakeFromNib()
		accessoryColorView.layer.borderColor = UIColor.black.cgColor
		accessoryColorView.layer.borderWidth = 1
		accessoryColorView.layer.cornerRadius = 8
	}
	
	deinit {
		accessory?.delegate = nil
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		accessory = nil
		errors = nil
	}
	
	override var textLabel: UILabel? {
		return accessoryNameLabel
	}
	
	// MARK: - Private properties and methods
	
	private func updateAccessory() {
		updateBackground()
		updateName()
	}
	
	fileprivate func updateName() {
		guard let accessory = accessory, let textLabel = textLabel else { return }
		if let room = accessory.room {
			textLabel.text = "\(accessory.lightBulbName()) - \(room.name)"
		} else {
			textLabel.text = accessory.lightBulbName()
		}
		if let errors = errors, errors.count > 0 {
			let descriptions = errors.map({ $0.localizedDescription })
			textLabel.text = "\(textLabel.text!) (errors: \(descriptions.joined(separator: ", ")))"
			print("Errors: \(textLabel.text!)")
		}
	}
}

@available(macCatalyst 14.0, *)
extension HomeKitLightbulbTableViewCell: HMAccessoryDelegate {
	
	func accessoryDidUpdateName(_ accessory: HMAccessory) {
		updateName()
	}

	func accessory(_ accessory: HMAccessory, didUpdateNameFor service: HMService) {
		updateName()
	}
	
	func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
		guard accessory == self.accessory, service.serviceType == HMServiceTypeLightbulb else {
			return
		}
		let colorBulbServiceCharacteristicTypes = [HMCharacteristicTypeHue, HMCharacteristicTypeBrightness, HMCharacteristicTypeSaturation]
		guard colorBulbServiceCharacteristicTypes.contains(characteristic.characteristicType) else {
			return
		}
		updateBackground()
	}
}

#endif
