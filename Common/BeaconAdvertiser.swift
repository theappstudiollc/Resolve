//
//  BeaconAdvertiser.swift
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

import CoreBluetooth
import CoreLocation
import ResolveKit

internal struct ResolveBeacon: CoreBeaconIdentity {

	let uuid: UUID
	let major: CLBeaconMajorValue
	let minor: CLBeaconMajorValue
}

internal class BeaconAdvertiser: NSObject {

	internal let beacon: CoreBeaconIdentity

	private var peripheralManager: CBPeripheralManager?
	private var wantsToAdvertise = false

	@objc enum AdvertisingState: Int {
		case notAdvertising
		case inTransition
		case advertising
	}
	private var _advertisingState: AdvertisingState = .notAdvertising
	@objc public var advertisingState: AdvertisingState {
		get { return _advertisingState }
		set {
			DispatchQueue.runInMain {
				willChangeValue(for: \.advertisingState)
				_advertisingState = newValue
				didChangeValue(for: \.advertisingState)
			}
		}
	}

	override init() {
		let uuid = UUID(uuidString: "44F9B4A5-2539-4A5E-B90A-34BC94A195F4")!
		#if os(iOS)
		let deviceName = UIDevice.current.name
		#else
		let deviceName = ProcessInfo.processInfo.hostName
		#endif
		let hash = deviceName.hashValue
		let major = CLBeaconMajorValue((hash >> 16) & 0xFFFF)
		let minor = CLBeaconMinorValue((hash >> 0) & 0xFFFF)
		beacon = ResolveBeacon(uuid: uuid, major: major, minor: minor)
		super.init()
//		advertisingState = peripheralManager?.isAdvertising ?? false ? .advertising : .notAdvertising
	}

	func startAdvertising(with measuredPower: Int8? = nil) {
		guard self.peripheralManager == nil else { return }
		advertisingState = .inTransition
		wantsToAdvertise = true
		#if os(tvOS)
		peripheralManager = CBPeripheralManager()
		peripheralManager!.delegate = self
		updatePeripheralManager(peripheralManager!)
		#else
		let queue = DispatchQueue(label: "Bluetooth Peripheral Manager")
		peripheralManager = CBPeripheralManager(delegate: self, queue: queue)
		#endif
	}

	func stopAdvertising() {
		advertisingState = .inTransition
		wantsToAdvertise = false
		if let peripheralManager = self.peripheralManager, peripheralManager.isAdvertising {
			peripheralManager.stopAdvertising()
		}
		peripheralManager = nil
		advertisingState = .notAdvertising
	}

	// MARK: - Private methods

	private func updatePeripheralManager(_ peripheralManager: CBPeripheralManager) {
//		print("\(self) updatePeripheralManager \(peripheralManager.state.rawValue)")
		guard peripheralManager.state == .poweredOn else {
			advertisingState = .notAdvertising
			return
		}
		if peripheralManager.isAdvertising {
			peripheralManager.stopAdvertising()
		}
		guard wantsToAdvertise == true else {
			self.peripheralManager = nil
			return
		}
		advertisingState = .inTransition
//		peripheralData[CBAdvertisementDataLocalNameKey] = deviceName
		peripheralManager.startAdvertising(beacon.peripheralData())
	}
}

extension BeaconAdvertiser: CBPeripheralManagerDelegate {

	func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
		print("\(self) peripheralManagerDidStartAdvertising \(String(describing: error))")
		advertisingState = peripheral.isAdvertising ? .advertising : .notAdvertising
	}

	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		print("\(self) peripheralManagerDidUpdateState")
		updatePeripheralManager(peripheral)
	}
}
