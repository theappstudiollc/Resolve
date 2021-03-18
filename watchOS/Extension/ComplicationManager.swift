//
//  ComplicationManager.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2021 The App Studio LLC.
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

import ClockKit
import ResolveKit

final class ComplicationManager: ComplicationService {

	var complicationServer: CLKComplicationServer
	var settingsService: WatchSessionSettingsService
	@Service var loggingService: CoreLoggingService

	init(complicationServer: CLKComplicationServer = .sharedInstance(), settingsService: WatchSessionSettingsService) {
		self.complicationServer = complicationServer
		self.settingsService = settingsService
	}

	var tapCount: Int {
		return settingsService.lastSharedEventComplicationCount
	}

	func reloadDescriptors() {
		#if swift(>=5.3) // Xcode 12.x
		guard #available(watchOS 7.0, *) else { return }
		complicationServer.reloadComplicationDescriptors()
		#endif
	}

	func updateTapCount(_ tapCount: Int, forceReload: Bool) {
		guard forceReload || settingsService.lastSharedEventComplicationCount != tapCount else {
			loggingService.log(.info, "Skipping update because tap count of `%d` is unchanged", tapCount)
			return
		}
		settingsService.lastSharedEventComplicationCount = tapCount

		guard let complications = complicationServer.activeComplications else { return }
		for complication in complications {
			#if swift(>=5.3) // Xcode 12.x
			if #available(watchOS 7.0, *), complication.identifier != CLKDefaultComplicationIdentifier { continue }
			#endif
			complicationServer.reloadTimeline(for: complication)
		}
	}
}
