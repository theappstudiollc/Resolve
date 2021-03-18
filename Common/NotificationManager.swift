//
//  NotificationManager.swift
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

import CoreLocation
import CoreResolve
import MapKit
import UserNotifications

final class NotificationManager: NSObject, NotificationService {

	private let kBeaconNotificationIdentifier = "resolveBeaconRequest"
	private let kVisitNotificationCategory = "resolveVisitCategory"

	private let loggingService: CoreLoggingService
	private var notificationProvider: Provider

	deinit {
		print("\(self) deinit")
	}

	required init(notificationProvider: Provider, loggingService: CoreLoggingService) {
		self.loggingService = loggingService
		self.notificationProvider = notificationProvider
		super.init()
		self.notificationProvider.notificationDelegate = self
	}

	@available(macOS 10.14, watchOS 6.0, *)
	func registerRemoteNotifications() {
		notificationProvider.registerForRemoteNotifications()
	}

	#if os(tvOS) // TODO: tvOS supports badges -- let's register for that

	func registerUserNotifications() {
		notificationProvider.requestAuthorization(options: [.badge]) { result in
			switch result {
			case .success():
				print("Notification authorization success")
			case .failure(let error):
				print("Notification authorization failed: \(error.localizedDescription)")
			}
		}
	}
	
	#else

	func registerUserNotifications() {
		if #available(iOS 10.0, macOS 10.14, *) {
			notificationProvider.setNotificationCategories(getNotificationCategories())
		}
		notificationProvider.requestAuthorization(options: [.alert, .sound]) { result in
			switch result {
			case .success():
				print("Notification authorization success")
			case .failure(let error):
				print("Notification authorization failed: \(error.localizedDescription)")
			}
		}
	}
	
	// MARK: Private methods
	
	func getNotificationCategories() -> Set<CoreNotification.Category> {
		let visitCategory = CoreNotification.Category(identifier: kVisitNotificationCategory, actions: [], intentIdentifiers: [])
		return Set<CoreNotification.Category>(arrayLiteral: visitCategory)
	}
	
	// MARK: NotificationService methods
	
	func notify(withMessage message: String, _ completion: ((_ error: Error?) -> ())? = nil) {
		if #available(iOS 10.0, macOS 10.14, *) {
			UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [kBeaconNotificationIdentifier])
			let content = UNMutableNotificationContent()
			content.body = message
			content.title = "Message"
			content.sound = UNNotificationSound.default
			let request = UNNotificationRequest(identifier: kBeaconNotificationIdentifier, content: content, trigger: nil)
			UNUserNotificationCenter.current().add(request) { error in
				if let completion = completion {
					completion(error)
				} else {
					if let error = error {
						print("Error adding notification request: \(error.localizedDescription)")
					} else {
						print("Notification request submitted: \(request)")
					}
				}
			}
		} else {
			#if os(iOS)
			let notification = UILocalNotification()
			notification.alertBody = message
			notification.alertTitle = "Message"
			// TODO: notification.category = "something"
			notification.fireDate = Date()
			notification.soundName = UILocalNotificationDefaultSoundName
			UIApplication.shared.scheduleLocalNotification(notification)
			#elseif os(macOS)
			let notification = NSUserNotification()
			notification.identifier = kBeaconNotificationIdentifier
			notification.deliveryDate = Date()
			notification.title = "Message"
//			notification.subtitle = "Hands on the keyboard please"
			notification.informativeText = message
			notification.soundName = NSUserNotificationDefaultSoundName
			NSUserNotificationCenter.default.deliver(notification)
			#endif
			if let completion = completion {
				completion(nil)
			}
		}
	}

	#endif
	
	#if os(iOS)
	
	func clearBeaconNotifications() {
		if #available(iOS 10.0, *) {
			UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [kBeaconNotificationIdentifier])
		} else { // TODO: Use scheduledNotifications to look for a category
			UIApplication.shared.cancelAllLocalNotifications()
		}
	}

	func notifyBeaconEntry() {
		if #available(iOS 10.0, *) {
			UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [kBeaconNotificationIdentifier])
			let content = UNMutableNotificationContent()
			content.body = NSLocalizedString("notification.beacon.body", comment: "Do you want to play?")
			content.title = NSLocalizedString("notification.beacon.title", comment: "Nearby opponent discovered")
			content.sound = UNNotificationSound.default
			let request = UNNotificationRequest(identifier: kBeaconNotificationIdentifier, content: content, trigger: nil)
			UNUserNotificationCenter.current().add(request) { error in
				if let error = error {
					print("Error adding notification request: \(error.localizedDescription)")
				} else {
					print("Notification request submitted: \(request)")
				}
			}
		} else {
			let notification = UILocalNotification()
			notification.alertBody = NSLocalizedString("notification.beacon.body", comment: "Do you want to play?")
			notification.alertTitle = NSLocalizedString("notification.beacon.title", comment: "Nearby opponent discovered")
			notification.fireDate = Date()
			notification.soundName = UILocalNotificationDefaultSoundName
			UIApplication.shared.scheduleLocalNotification(notification)
		}
	}
	
	func notifyBeaconExit() {
		clearBeaconNotifications()
	}
	
	@available(iOS 10.0, *)
	func notifyVisit(_ visit: CLVisit) {
		
		let arrival = DateFormatter.localizedString(from: visit.arrivalDate, dateStyle: .short, timeStyle: .medium)
		let now = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
		
		let content = UNMutableNotificationContent()
		if visit.departureDate == Date.distantFuture {
			content.body = "at \(arrival) <- \(now)"
			content.title = "You've arrived"
		} else {
			let departure = DateFormatter.localizedString(from: visit.departureDate, dateStyle: .short, timeStyle: .medium)
			content.body = "from \(arrival)\nto \(departure) <- \(now)"
			content.title = "You've left"
		}
		content.categoryIdentifier = kVisitNotificationCategory
		content.sound = UNNotificationSound.default
		content.threadIdentifier = arrival // Pair arrivals with departures by using the arrival date as a string
		content.userInfo = [
			"horizontalAccuracy" : visit.horizontalAccuracy,
			"latitude" : visit.coordinate.latitude,
			"longitude" : visit.coordinate.longitude
		]

		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				print("Error adding notification request: \(error.localizedDescription)")
			} else {
				print("Notification request submitted: \(request)")
			}
		}
	}
	
	#endif
}

extension NotificationManager: CoreRemoteNotificationAdaptingDelegate {

	func deviceTokenDidUpdate(_ token: Data) {
		loggingService.log(.debug, "Registered with token: %d bytes", token.count)
	}

	func deviceTokenRegistrationFailed(_ error: Error) {
		loggingService.log(.error, "Failed to register notification: %{public}@", error.localizedDescription)
	}
}
