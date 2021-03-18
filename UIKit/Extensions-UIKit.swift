//
//  Extensions-UIKit.swift
//  Resolve
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

import CloudKit
import CoreResolve
import UIKit

extension Application {

	// Apps are usually launched by a single thing, not a combination.
	// TODO: Maybe replace the Dictionary extension below with a more advanced enum
	public enum LaunchSource {
		case team(bundleId: String)
		case unknown
	}
}

public extension Dictionary where Key == UIApplication.LaunchOptionsKey, Value == Any {

	var bluetoolCentrals: [String]? {
		return self[.bluetoothCentrals] as? [String]
	}

	var bluetoothPeripherals: [String]? {
		return self[.bluetoothPeripherals] as? [String]
	}

	var launchedViaLocation: Bool {
		return self[.location] as? Bool ?? false
	}

	var launchSource: Application.LaunchSource? {
		guard keys.contains(.sourceApplication) else { return nil }
		guard let bundleId = self[.sourceApplication] as? String else { return .unknown }
		return .team(bundleId: bundleId)
	}

	var launchUrl: URL? {
		return self[.url] as? URL
	}

	@available(iOS 10.0, tvOS 10.0, *)
	var shareMetadata: CKShare.Metadata? {
		#if os(iOS)
		return self[.cloudKitShareMetadata] as? CKShare.Metadata
		#else
		return nil
		#endif
	}

	private var userActivityDictionary: [String : Any]? {
		return self[.userActivityDictionary] as? [String : Any]
	}

	var userActivity: NSUserActivity? {
		guard let userActivityDictionary = self.userActivityDictionary else {
			return nil
		}
		return userActivityDictionary["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity
	}

	var userActivityIdentifier: String? {
		guard let userActivityDictionary = self.userActivityDictionary else {
			return nil
		}
		return userActivityDictionary["UIApplicationLaunchOptionsUserActivityIdentifierKey"] as? String
	}

	var userActivityType: String? {
		guard let userActivityDictionary = self.userActivityDictionary else {
			return nil
		}
		return userActivityDictionary["UIApplicationLaunchOptionsUserActivityTypeKey"] as? String
	}
}

public extension ResolveBinding where Self: UIControl {

	func bind<Value>(_ event: UIControl.Event, from sourcePath: KeyPath<Self, Value>, to action: @escaping (Value) -> Void) -> Unbind {
		return Binding<Self>(control: self, action: { control in
			action(control[keyPath: sourcePath])
		}, for: event).dispose
	}

	func bind<Destination, Value>(_ event: UIControl.Event, from sourcePath: KeyPath<Self, Value>, to destination: Destination, on destinationPath: ReferenceWritableKeyPath<Destination, Value>) -> Unbind {
		return bind(event, from: sourcePath, to: destination, on: destinationPath) { $0 }
	}

	func bind<Destination, Value, Intermediate>(_ event: UIControl.Event, from sourcePath: KeyPath<Self, Intermediate>, to destination: Destination, on destinationPath: ReferenceWritableKeyPath<Destination, Value>, with conversion: @escaping (Intermediate) -> Value) -> Unbind {
		destination[keyPath: destinationPath] = conversion(self[keyPath: sourcePath])
		return bind(event, from: sourcePath) { source in
			destination[keyPath: destinationPath] = conversion(source)
		}
	}
}

public extension UISplitViewController {
	
	var detailViewController: UIViewController? {
		guard let masterViewController = viewControllers.first else { return nil }
		if let detailViewController = viewControllers.last, detailViewController !== masterViewController {
			return detailViewController
		}
		// UISplitViewControllers are the only scenario where a UINavigationController may push another UINavigationController
		if let navigationController = masterViewController as? UINavigationController, let detailViewController = navigationController.topViewController as? UINavigationController {
			return detailViewController
		}
		return nil
	}
}

extension UITextField {

	public enum Conversions {

		public static func nilIfEmpty(_ text: String?) -> String? {
			return text?.count ?? 0 > 0 ? text : nil
		}
	}

	public func bindText<Destination>(to destination: Destination, on destinationPath: ReferenceWritableKeyPath<Destination, String?>) -> Unbind {
		return bindText(to: destination, on: destinationPath) { $0 }
	}

	public func bindText<Destination, Value>(to destination: Destination, on destinationPath: ReferenceWritableKeyPath<Destination, Value>, with conversion: @escaping (String?) -> Value) -> Unbind {
		return bind(.editingChanged, from: \.text, to: destination, on: destinationPath) { conversion($0) }
	}
}

public extension UIViewController {

	func findViewController<T>(as: T.Type) -> T? {
		guard let result = self as? T else {
			if let navigationController = self as? UINavigationController {
				return navigationController.topViewController?.findViewController(as: T.self)
			}
			return children.first(where: { $0 is T }) as? T
		}
		return result
	}
}
