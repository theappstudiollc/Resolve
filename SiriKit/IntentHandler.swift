//
//  IntentHandler.swift
//  Intent
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

import Intents
import ResolveKit

/// Represents the Application Extension's ServiceContext, which is usually referenced as the Extension's `Principal Class`
final class IntentHandler: INExtension, ServiceContext {

	// MARK: - Private properties and methods

	private var services: ExtensionServices!

	// MARK: - INExtension overrides

	override init() {
		super.init()
		services = ExtensionServices(context: self)
	}

    override func handler(for intent: INIntent) -> Any {
		guard #available(iOS 12.0, watchOS 7.0, *) else { return legacyHandler(for: intent) }
		switch intent {
		case is CreateSharedEventIntent:
			return try! Services.access(CreateSharedEventIntentHandling.self)
		default:
			print("Intent: \(intent)")
			return self
		}
    }

	/// Returns the handler for SiriKit Intents on iOS 11 and below
	func legacyHandler(for intent: INIntent) -> Any {
		print("Intent: \(intent)")
		return self
	}
}
