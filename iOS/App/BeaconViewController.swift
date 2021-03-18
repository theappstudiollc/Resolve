//
//  BeaconViewController.swift
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

import CoreLocation
import ResolveKit

final class BeaconViewController: BeaconAdvertisingViewController {

	private var beaconsTableViewController: BeaconsTableViewController!

	@IBOutlet private var startListeningButton: UIButton!
	@IBAction private func startListeningButtonTapped(_ sender: UIButton) {
		beaconService.startListening()
	}
	private var startListeningButtonBinding: ResolveBinding.Unbind? {
		willSet { startListeningButtonBinding?() }
	}

	@IBOutlet private var stopListeningButton: UIButton!
	@IBAction private func stopListeningButtonTapped(_ sender: UIButton) {
		beaconService.stopListening()
	}
	private var stopListeningButtonBinding: ResolveBinding.Unbind? {
		willSet { stopListeningButtonBinding?() }
	}

	deinit {
		startListeningButtonBinding = nil
		stopListeningButtonBinding = nil
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.destination {
		case let beaconsTableViewController as BeaconsTableViewController:
			self.beaconsTableViewController = beaconsTableViewController
		default: break
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		startListeningButtonBinding = beaconService.bind(\.listeningState, to: startListeningButton, on: \.isEnabled) {
			$0 == .notListening
		}
		stopListeningButtonBinding = beaconService.bind(\.listeningState, to: stopListeningButton, on: \.isEnabled) {
			$0 == .listening
		}
		NotificationCenter.default.addObserver(self, selector: #selector(beaconsRanged(_:)), name: .beaconsRanged, object: nil)
	}

	// MARK: - Private methods

	@objc func beaconsRanged(_ notification: Notification) {
		guard
			let beaconsTableViewController = self.beaconsTableViewController,
			let beacons = notification.userInfo?[BeaconNotificationOptionsKey.beacons] as? [CLBeacon]
		else {
			return
		}
		beaconsTableViewController.apply(beacons)
	}
}
