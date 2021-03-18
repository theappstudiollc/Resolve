//
//  VisitNotificationController.swift
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
import MapKit
import ResolveKit
import UserNotifications

class VisitNotificationController: CoreUserNotificationInterfaceController {

	@IBOutlet var alertLabel: WKInterfaceLabel!
	@IBOutlet var mapView: WKInterfaceMap!
	@IBOutlet var titleLabel: WKInterfaceLabel!

	// MARK: - CoreUserNotificationInterfaceController overrides

	@available(watchOS 5.0, *)
	override func didReceive(_ notification: UNNotification) {
		super.didReceive(notification)
		applyNotification(notification)
		if !appliedLocation(from: notification) {
			mapView.setHidden(true)
		}
	}

	override func didReceive(_ notification: UNNotification, withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void) {
		super.didReceive(notification, withCompletion: completionHandler)
		applyNotification(notification)
		if appliedLocation(from: notification) {
			completionHandler(.custom)
		} else {
			completionHandler(.default)
		}
    }

	// MARK: - Private methods

	func applyVisit(horizontalAccuracy: CLLocationAccuracy, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
		let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
		let origin = MKMapPoint(coordinate)
		let points = MKMapPointsPerMeterAtLatitude(latitude) * horizontalAccuracy
		let size = MKMapSize(width: points, height: points)
		let mapRect = MKMapRect(origin: origin, size: size)
		mapView.addAnnotation(coordinate, with: .purple)
		mapView.setVisibleMapRect(mapRect)
	}

	func appliedLocation(from notification: UNNotification) -> Bool {
		guard
			let horizontalAccuracy = notification.request.content.userInfo["horizontalAccuracy"] as? CLLocationAccuracy,
			let latitude = notification.request.content.userInfo["latitude"] as? CLLocationDegrees,
			let longitude = notification.request.content.userInfo["longitude"] as? CLLocationDegrees else {
			return false
		}
		applyVisit(horizontalAccuracy: horizontalAccuracy, latitude: latitude, longitude: longitude)
		return true
	}

	func applyNotification(_ notification: UNNotification) {
		titleLabel.setText(notification.request.content.title)
		alertLabel.setText(notification.request.content.body)
	}
}
