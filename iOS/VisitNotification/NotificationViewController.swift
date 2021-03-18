//
//  NotificationViewController.swift
//  VisitNotification
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

import CoreLocation
import MapKit
import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController {
	
	// MARK: - Interface Builder properties and methods
	
    @IBOutlet fileprivate var bodyLabel: UILabel!
	@IBOutlet fileprivate var imageView: UIImageView!
	@IBOutlet fileprivate var map: MKMapView!
	
	// MARK: - UIViewController overrides
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	// MARK: - Private methods
	
	func applyVisit(horizontalAccuracy: CLLocationAccuracy, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
		let origin = MKMapPoint(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
		let points = MKMapPointsPerMeterAtLatitude(latitude) * horizontalAccuracy
		let size = MKMapSize(width: points, height: points)
		let mapRect = MKMapRect(origin: origin, size: size)
		map.addOverlay(MKCircle(mapRect: mapRect))
		let padding = UIEdgeInsets(top: 24, left: 0, bottom: 104, right: 0)
		map.setVisibleMapRect(mapRect, edgePadding: padding, animated: false)
	}
}

extension NotificationViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		guard let circle = overlay as? MKCircle else {
			fatalError("Unexpected overlay type: \(type(of: overlay))")
		}
		let renderer = MKCircleRenderer(circle: circle)
		renderer.fillColor = UIColor.magenta.withAlphaComponent(0.3)
		renderer.lineWidth = 1
		renderer.strokeColor = UIColor.purple.withAlphaComponent(0.3)
		return renderer
	}
}

extension NotificationViewController: UNNotificationContentExtension {
	
	func didReceive(_ notification: UNNotification) {
		bodyLabel.text = notification.request.content.body
		if map.overlays.count > 0 {
			map.removeOverlays(map.overlays)
		}
		if let horizontalAccuracy = notification.request.content.userInfo["horizontalAccuracy"] as? CLLocationAccuracy,
			let latitude = notification.request.content.userInfo["latitude"] as? CLLocationDegrees,
			let longitude = notification.request.content.userInfo["longitude"] as? CLLocationDegrees {
			applyVisit(horizontalAccuracy: horizontalAccuracy, latitude: latitude, longitude: longitude)
		}
	}
}
