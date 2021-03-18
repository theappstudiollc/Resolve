//
//  Extensions-HomeKit.swift
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
extension HMAccessory {
	
	func assignColor(_ color: UIColor, forcePower: Bool, _ completion: (([Error]) -> Void)? = nil) {
//		precondition(isColorLightBulb(), "Cannot assign random colors to a non-color lightbulb")
		guard let lightBulbService = service(ofType: HMServiceTypeLightbulb) else {
			let error = NSError(domain: "HomeKitViewControllerErrorDomain", code: -1, userInfo: [
				NSLocalizedDescriptionKey : "No bulb service found"
				])
			completion?([error])
			return
		}
		
		var hue: CGFloat = 0
		var saturation: CGFloat = 0
		var brightness: CGFloat = 0
		guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil) else {
			let error = NSError(domain: "HomeKitViewControllerErrorDomain", code: -2, userInfo: [
				NSLocalizedDescriptionKey : "Unable to decode color"
				])
			completion?([error])
			return
		}
		
		let group = DispatchGroup()
		var errors = [Error]()
		if forcePower, let powerStateCharacteristic = lightBulbService.characteristic(ofType: HMCharacteristicTypePowerState), let _ = powerStateCharacteristic.value as? Bool {
			group.enter()
			powerStateCharacteristic.writeValue(true) { error in
				defer { group.leave() }
				guard let error = error else { return }
				assert(Thread.isMainThread, "We expect to be in the main thread for appending errors")
				errors.append(error)
			}
		}
		if let brightnessCharacteristic = lightBulbService.characteristic(ofType: HMCharacteristicTypeBrightness) {
			group.enter()
			brightnessCharacteristic.writeValue(Int(100.0 * brightness)) { error in
				defer { group.leave() }
				guard let error = error else { return }
				assert(Thread.isMainThread, "We expect to be in the main thread for appending errors")
				errors.append(error)
			}
		}
		if let hueCharacteristic = lightBulbService.characteristic(ofType: HMCharacteristicTypeHue) {
			group.enter()
			hueCharacteristic.writeValue(360.0 * hue) { error in
				defer { group.leave() }
				guard let error = error else { return }
				assert(Thread.isMainThread, "We expect to be in the main thread for appending errors")
				errors.append(error)
			}
		}
		if let saturationCharacteristic = lightBulbService.characteristic(ofType: HMCharacteristicTypeSaturation) {
			group.enter()
			saturationCharacteristic.writeValue(100.0 * saturation) { error in
				defer { group.leave() }
				guard let error = error else { return }
				assert(Thread.isMainThread, "We expect to be in the main thread for appending errors")
				errors.append(error)
			}
		}
		DispatchQueue.global().async {
			group.wait()
			DispatchQueue.main.async {
				completion?(errors)
			}
		}
	}
	
	func assignRandomColor(forcePower: Bool, _ completion: (([Error]) -> Void)? = nil) {
		let color = UIColor(red: (CGFloat)(drand48()), green: (CGFloat)(drand48()), blue: (CGFloat)(drand48()), alpha: 1)
		assignColor(color, forcePower: forcePower, completion)
	}
	
	func enableColorNotifications(_ enabled: Bool) {
		guard let lightBulbService = service(ofType: HMServiceTypeLightbulb) else { return }
		let characteristicTypes = [HMCharacteristicTypeBrightness, HMCharacteristicTypeHue, HMCharacteristicTypeSaturation]
		lightBulbService.enableNotifications(enabled, forCharacteristicTypes: characteristicTypes)
	}
	
	func isColorLightBulb() -> Bool {
		let colorBulbServiceCharacteristicTypes = Set<String>([HMCharacteristicTypeHue, HMCharacteristicTypeBrightness, HMCharacteristicTypeSaturation])
		return services.contains(where: { service -> Bool in
			guard service.serviceType == HMServiceTypeLightbulb else {
//				print("    skipping \(service.serviceDescription())")
				return false
			}
			let serviceCharacteristicTypes = service.characteristics.map { $0.characteristicType }
			guard colorBulbServiceCharacteristicTypes.isSubset(of: serviceCharacteristicTypes) else {
				return false
			}
//			print("    found \(service.serviceDescription())")
			return true
		})
	}
	
	func lightBulbColor(withAlpha alpha: CGFloat = 1) -> UIColor? {
		guard let lightBulbService = service(ofType: HMServiceTypeLightbulb) else {
			return nil
		}
		guard let brightnessCharacteristic = lightBulbService.characteristic(ofType: HMCharacteristicTypeBrightness), let brightnessCharacteristicValue = brightnessCharacteristic.value as? Int else {
			return nil
		}
		let brightness = CGFloat(Double(brightnessCharacteristicValue) / 100.0)
		guard let hueCharacteristic = lightBulbService.characteristic(ofType: HMCharacteristicTypeHue), let hueCharacteristicValue = hueCharacteristic.value as? Double else {
			return nil
		}
		let hue = CGFloat(hueCharacteristicValue / 360.0)
		guard let saturationCharacteristic = lightBulbService.characteristic(ofType: HMCharacteristicTypeSaturation), let saturationCharacteristicValue = saturationCharacteristic.value as? Double else {
			return nil
		}
		let saturation = CGFloat(saturationCharacteristicValue / 100.0)
		return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
	}

	func service(ofType type: String) -> HMService? {
		return services.first(where: { $0.serviceType == type })
	}
}

@available(macCatalyst 14.0, *)
extension HMCharacteristic {
	
	func charactersticDescription() -> String {
		switch characteristicType {
		#if !targetEnvironment(macCatalyst)
		case HMCharacteristicTypeFirmwareVersion:
			return "Firmware Version"
		case HMCharacteristicTypeManufacturer:
			return "Manufacturer"
		case HMCharacteristicTypeModel:
			return "Model"
		case HMCharacteristicTypeSerialNumber:
			return "Serial Number"
		#endif
		case HMCharacteristicTypeBrightness:
			return "Brightness"
		case HMCharacteristicTypeHue:
			return "Hue"
		case HMCharacteristicTypeIdentify:
			return "Identify"
		case HMCharacteristicTypeName:
			return "Name"
		case HMCharacteristicTypePowerState:
			return "Power State"
		case HMCharacteristicTypeSaturation:
			return "Saturation"
		case "D8B76298-42E7-5FFD-B1D6-1782D9A1F936":
			return "Philips Hue Identifier"
		default:
			return "Unknown characteristic: \(characteristicType)"
		}
	}
	
	func setEnableDelegateNotifications(_ enabled: Bool, _ completion: ((Error?) -> Void)? = nil) {
		guard isNotificationEnabled != enabled else {
			completion?(nil)
			return
		}
		enableNotification(true) { error in
			completion?(error)
			guard let error = error else { return }
			print("Error \(enabled ? "enabling" : "disabling") notifications for \(self.localizedDescription): \(error.localizedDescription)")
		}
	}
}

@available(macCatalyst 14.0, *)
extension HMService {
	
	func characteristic(ofType type: String) -> HMCharacteristic? {
		return characteristics.first(where: { $0.characteristicType == type })
	}
	
	func enableNotifications(_ enabled: Bool, forCharacteristicTypes characteristicTypes: [String], _ completion: (([Error]) -> Void)? = nil) {
		let group = DispatchGroup()
		var errors = [Error]()
		for characteristicType in characteristicTypes {
			guard let characteristic = characteristic(ofType: characteristicType) else { continue }
			group.enter()
			characteristic.setEnableDelegateNotifications(enabled) { error in
				defer { group.leave() }
				guard let error = error else { return }
				assert(Thread.isMainThread, "We expect to be in the main thread for appending errors")
				errors.append(error)
			}
		}
		DispatchQueue.global().async {
			group.wait()
			DispatchQueue.main.async {
				completion?(errors)
			}
		}
	}

	func serviceDescription() -> String {
		#if !targetEnvironment(macCatalyst)
		if #available(iOS 10.3, tvOS 10.2, *) {
			switch serviceType {
			case HMServiceTypeLabel:
				return "\(name) label service"
			default:
				break
			}
		}
		#endif
		switch serviceType {
		#if targetEnvironment(macCatalyst)
		case HMServiceTypeLabel:
			return "\(name) label service"
		#endif
		case HMServiceTypeAccessoryInformation:
			return "\(name) information service"
		case HMServiceTypeLightbulb:
			return "\(name) lightbulb service"
		case HMServiceTypeMotionSensor:
			return "\(name) motion sensor service"
		case HMServiceTypeOccupancySensor:
			return "\(name) occupancy sensor service"
		case HMServiceTypeStatefulProgrammableSwitch:
			return "\(name) stateful programmable switch service"
		case HMServiceTypeStatelessProgrammableSwitch:
			return "\(name) stateless programmable switch service"
		case HMServiceTypeSwitch:
			return "\(name) switch service"
		case HMServiceTypeTemperatureSensor:
			return "\(name) temperature service"
		case HMServiceTypeThermostat:
			return "\(name) thermostat service"
		default:
			return "\(name) unknown service: \(serviceType)"
		}
	}
}

#endif
