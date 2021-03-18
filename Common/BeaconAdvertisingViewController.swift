//
//  BeaconAdvertisingViewController.swift
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

import ResolveKit

internal class BeaconAdvertisingViewController: ResolveViewController {

	#if os(iOS)
	@Service internal var beaconService: BeaconManager
	#else
	@Service internal var beaconService: BeaconAdvertiser
	#endif

	private var advertisingStateBinding: ResolveBinding.Unbind? {
		willSet { advertisingStateBinding?() }
	}

	@IBOutlet private var startAdvertisingButton: Button!
	@IBAction private func startAdvertisingButtonTapped(_ sender: Button) {
		beaconService.startAdvertising()
	}
	private var startAdvertisingButtonBinding: ResolveBinding.Unbind? {
		willSet { startAdvertisingButtonBinding?() }
	}

	@IBOutlet private var stopAdvertisingButton: Button!
	@IBAction private func stopAdvertisingButtonTapped(_ sender: Button) {
		beaconService.stopAdvertising()
	}
	private var stopAdvertisingButtonBinding: ResolveBinding.Unbind? {
		willSet { stopAdvertisingButtonBinding?() }
	}

	deinit {
		advertisingStateBinding = nil
		startAdvertisingButtonBinding = nil
		stopAdvertisingButtonBinding = nil
	}

	#if os(tvOS)

	@available(iOS 9.0, tvOS 9.0, *)
	override var preferredFocusEnvironments: [UIFocusEnvironment] {
		switch beaconService.advertisingState {
		case .advertising: return [stopAdvertisingButton]
		case .inTransition: return [startAdvertisingButton]
		case .notAdvertising: return [startAdvertisingButton]
		}
	}

	#endif

	override func viewDidLoad() {
		super.viewDidLoad()
		startAdvertisingButtonBinding = beaconService.bind(\.advertisingState, to: startAdvertisingButton, on: \.isEnabled) {
			$0 == .notAdvertising
		}
		stopAdvertisingButtonBinding = beaconService.bind(\.advertisingState, to: stopAdvertisingButton, on: \.isEnabled) {
			$0 == .advertising
		}

		#if os(tvOS)

		advertisingStateBinding = beaconService.bind(\.advertisingState) { [weak self] _ in
			guard let self = self else { return }
			self.setNeedsFocusUpdate()
		}

		#endif
	}
}
