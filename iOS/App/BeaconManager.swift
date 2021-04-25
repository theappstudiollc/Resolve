//
//  BeaconManager.swift
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

import CoreBluetooth
import CoreLocation
import ResolveKit
/*
protocol BeaconManagerDelegate: AnyObject {
	func beaconManager(_ beaconManager: BeaconManager, didIdentifyBeaconRegion beaconRegion: CoreBeaconIdentityConstraint)
	func beaconManager(_ beaconManager: BeaconManager, didLoseBeaconRegion beaconRegion: CoreBeaconIdentityConstraint)
	func beaconManager(_ beaconManager: BeaconManager, didRangeBeacons beacons: [CLBeacon], inBeaconRegion beaconRegion: CoreBeaconIdentityConstraint)
}
*/
class BeaconManager: BeaconAdvertiser {

	private var authorizationStatus = CLAuthorizationStatus.notDetermined
	private var identifiedBeacon: CoreBeaconIdentityConstraint? = nil {
		didSet {
			guard identifiedBeacon == oldValue else { return }
			updateIdentifiedBeacon(withPreviousIdentifiedBeacon: oldValue)
		}
	}
	private let locationProvider: CoreBeaconRanging & CoreLocationCoordinateProviding & CoreLocationRegionMonitoring
	private let loggingService: CoreLoggingService
	private let notificationCenter: NotificationCenter
	private let notificationService: NotificationService

	var isBeaconIdentified: Bool {
		return identifiedBeacon != nil
	}

	@objc enum ListeningState: Int {
		case notListening
		case inTransition
		case listening
	}
	private var _listeningState: ListeningState = .inTransition
	@objc public var listeningState: ListeningState {
		get { return _listeningState }
		set {
			willChangeValue(for: \.listeningState)
			_listeningState = newValue
			didChangeValue(for: \.listeningState)
		}
	}
	/*
	weak var delegate: BeaconManagerDelegate?
	*/
	required init(withCoreLocationProviding coreLocationProviding: CoreLocationProviding = CLLocationManager(), notificationCenter: NotificationCenter = .default, loggingService: CoreLoggingService, notificationService: NotificationService) {
		self.locationProvider = coreLocationProviding
		self.loggingService = loggingService
		self.notificationCenter = notificationCenter
		self.notificationService = notificationService
		super.init()
		locationProvider.allowsBackgroundLocationUpdates = true
		locationProvider.locationDelegate = self
		locationProvider.requestAlwaysAuthorization()

		#if !targetEnvironment(macCatalyst)
		let region = self.beaconRegionForNotificationTrigger()
		listeningState = locationProvider.monitoredRegions
			.compactMap({ $0 as? CLBeaconRegion })
			.contains(where: { $0.identifier == region.identifier })
			? .listening : .notListening
		#endif
	}
	
	func beaconRegionForNotificationTrigger() -> CLBeaconRegion {
		return CLBeaconRegion(proximityUUID: beacon.uuid, identifier: "\(beacon.uuid).nil.nil")
	}
	
	func startListening() {
		guard type(of: locationProvider).isMonitoringAvailable(for: CLBeaconRegion.self) else {
			return // TODO: Log and or report some error to the delegate
		}
		let region = beaconRegionForNotificationTrigger()
		// If any monitored beacon regions already have the same identifier and proximityUUID, then don't re-monitor
		guard !locationProvider.monitoredRegions
			.compactMap({ $0 as? CLBeaconRegion })
			.contains(where: { $0.identifier == region.identifier }) else {
				return // No need to startListening
		}
		listeningState = .inTransition
		// Need to stop any monitored regions based on the kBeaconIdentifier, otherwise startMonitoringForRegion won't work
//		let stopRegion = CLBeaconRegion(proximityUUID: UUID(), identifier: kBeaconIdentifier)
//		locationManager.stopMonitoring(for: stopRegion)
		// Now start monitoring a region using the desired uuid
		region.notifyEntryStateOnDisplay = true
		locationProvider.startMonitoring(for: region)
	}

	func stopListening() {
		let region = beaconRegionForNotificationTrigger()
		// if region monitoring is enabled, update the region being monitored
		var stoppedRegion = false
		for region in locationProvider.monitoredRegions
			.compactMap({ $0 as? CLBeaconRegion })
			.filter({ $0.identifier == region.identifier }) {
				loggingService.debug("Unmonitoring region: %{public}@", "\(region.identifier)")
				listeningState = .inTransition
				locationProvider.stopMonitoring(for: region)
				stoppedRegion = true
		}
		if !stoppedRegion {
			loggingService.debug("Unmonitoring region: %{public}@", "\(region.identifier)")
			listeningState = .inTransition
			locationProvider.stopMonitoring(for: region)
		}
		identifiedBeacon = nil
		listeningState = .notListening
	}
	
	// MARK: - Private methods
	
	private func updateIdentifiedBeacon(withPreviousIdentifiedBeacon previousIdentifiedBeacon: CoreBeaconIdentityConstraint?) {
		if let beacon = self.identifiedBeacon {
			notificationService.notifyBeaconEntry()
			locationProvider.startRangingBeacons(with: beacon)
		} else if let beacon = previousIdentifiedBeacon {
			notificationService.notifyBeaconExit()
			locationProvider.stopRangingBeacons(with: beacon)
		}
	}
}

extension BeaconManager: CoreLocationBeaconProvidingDelegate {
	
	// MARK: - Required delegate methods
	
	func locationProvider(_ provider: CoreLocationProviding, didChangeAuthorization status: CLAuthorizationStatus) {
		self.authorizationStatus = status
	}

	@available(macCatalyst, deprecated: 13.0)
	func locationProvider(_ provider: CoreLocationProviding, didDetermineState state: CLRegionState, for region: CLRegion) {
		guard let beaconRegion = region as? CLBeaconRegion, beaconRegion.proximityUUID == beacon.uuid else { return }
		self.identifiedBeacon = state == .inside ? CoreBeaconIdentityConstraint(region: beaconRegion) : nil
	}

	@available(macCatalyst, deprecated: 13.0)
	func locationProvider(_ provider: CoreLocationProviding, didEnterRegion region: CLRegion) {
		guard let beaconRegion = region as? CLBeaconRegion, beaconRegion.proximityUUID == beacon.uuid else { return }
		self.identifiedBeacon = CoreBeaconIdentityConstraint(region: beaconRegion)
	}

	@available(macCatalyst, deprecated: 13.0)
	func locationProvider(_ provider: CoreLocationProviding, didExitRegion region: CLRegion) {
		guard let beaconRegion = region as? CLBeaconRegion, beaconRegion.proximityUUID == beacon.uuid else { return }
		self.identifiedBeacon = nil
	}
	
	func locationProvider(_ provider: CoreLocationProviding, didFailWithError error: CLError) {
		loggingService.log(.error, "Loction provider failed: %{public}@", "\(error.localizedDescription)")
	}
	
	func locationProvider(_ provider: CoreLocationProviding, didRangeBeacons beacons: [CLBeacon], with constraint: CoreBeaconIdentityConstraint) {
		loggingService.debug("Location provider ranging beacons: %{public}@", "\(beacons.customPrinted)")
		let userInfo: [BeaconNotificationOptionsKey : Any] = [
			.beacons : beacons
		]
		notificationCenter.post(name: .beaconsRanged, object: provider, userInfo: userInfo)
	}
	
	func locationProvider(_ provider: CoreLocationProviding, didStartMonitoringFor region: CLRegion) {
		loggingService.debug("Location provider monitoring region %{public}@", region.identifier)
		listeningState = .listening
	}
	
	func locationProvider(_ provider: CoreLocationProviding, monitoringDidFailFor region: CLRegion?, withError error: CLError) {
		loggingService.log(.error, "Loction provider monitoring failed: %{public}@", "\(error.localizedDescription)")
		listeningState = .notListening
	}
	
	func locationProvider(_ provider: CoreLocationProviding, rangingBeaconsDidFailFor constraint: CoreBeaconIdentityConstraint, withError error: CLError) {
		loggingService.log(.error, "Loction provider ranging beacons failed: %{public}@", "\(error.localizedDescription)")
	}
}

public struct BeaconNotificationOptionsKey: Hashable, Equatable, RawRepresentable {

	public var rawValue: String

	public init(_ rawValue: String) {
		self.init(rawValue: rawValue)
	}

	public init(rawValue: String) {
		self.rawValue = rawValue
	}
}

extension BeaconNotificationOptionsKey {

	public static let beacons = BeaconNotificationOptionsKey("kBeaconManagerBeacons")
}

extension Notification.Name {

	static let beaconsRanged = Notification.Name("BeaconManagerBeaconsRanged")
}

extension Array where Element: CustomDebugStringConvertible {

	var customPrinted: String {
		return "\(Element.Type.self)[\(map { $0.debugDescription } .joined(separator: ", "))]"
	}
}
