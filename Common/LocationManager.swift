//
//  LocationManager.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2018 The App Studio LLC.
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

import CoreLocation
import CoreResolve

final class LocationManager: NSObject {

	private var authorizationStatus = CLAuthorizationStatus.notDetermined {
		didSet {
			if authorizationStatus == .authorizedAlways {
				locationProvider.startMonitoringVisits()
			}
		}
	}
	private var currentVisit: CLVisit? {
		didSet { updateCurrentVisit(oldValue) }
	}
	public let locationProvider: CoreLocationProviding
	public let notificationService: NotificationService
	
	public required init(with notificationService: NotificationService, locationProvider: CoreLocationProviding = CLLocationManager()) {
		self.locationProvider = locationProvider
		self.notificationService = notificationService
		super.init()
		locationProvider.locationDelegate = self
		locationProvider.requestAlwaysAuthorization()
	}
	
	func updateCurrentVisit(_ oldValue: CLVisit?) {
		// TODO: Remove this check when notificationService can work with iOS 9
		guard #available(iOS 10.0, *) else { return }
		
		if let visit = currentVisit, visit.arrivalDate > Date.distantPast {
			notificationService.notifyVisit(visit)
		}
	}
}

extension LocationManager: CoreLocationProvidingDelegate {
	
	// MARK: - Required delegate methods
	
	func locationProvider(_ provider: CoreLocationProviding, didChangeAuthorization status: CLAuthorizationStatus) {
		authorizationStatus = status
	}
	
	func locationProvider(_ provider: CoreLocationProviding, didFailWithError error: CLError) {
		switch error.code {
		case .locationUnknown:
			currentVisit = nil
		case .denied:
			currentVisit = nil
		default:
			// TODO: Report the error
			break
		}
	}
}

@available(macCatalyst, unavailable)
extension LocationManager: CoreLocationVisitProvidingDelegate {
	
	// MARK: - Required delegate methods
	
	func locationProvider(_ provider: CoreLocationProviding, didVisit visit: CLVisit) {
		currentVisit = visit
	}
}
