//
//  ComplicationController.swift
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

import ClockKit
import ResolveKit

public enum ComplicationControllerError: Error {

	case unexpectedComplicationFamily(rawValue: Int)
	case unexpectedWatchOSVersion
}

final class ComplicationController: NSObject {
	
	@Service var complicationService: ComplicationService
	@Service var loggingService: CoreLoggingService
	@Service var userActivityService: UserActivityService
	@Service var watchSessionService: WatchSessionService

	fileprivate var sharedEventComplicationFamilies: [CLKComplicationFamily] {
		let result: [CLKComplicationFamily] = [.circularSmall, .extraLarge, .modularLarge, .modularSmall, .utilitarianLarge, .utilitarianSmall, .utilitarianSmallFlat]
		guard #available(watchOS 5.0, *) else {
			return result
		}
		guard #available(watchOS 7.0, *) else {
			return result + [.graphicBezel, .graphicCircular, .graphicCorner, .graphicRectangular]
		}
		return CLKComplicationFamily.allCases
	}

	fileprivate func generateSharedEventTemplate(for complication: CLKComplication, with count: Int, localized: Bool) throws -> CLKComplicationTemplate {
		switch complication.family {
		case .circularSmall: return SharedEventTemplates.circularSmallTemplate(with: count, localized: localized)
		case .extraLarge: return SharedEventTemplates.extraLargeTemplate(with: count, localized: localized)
		case .graphicBezel: return try SharedEventTemplates.graphicBezelTemplate(with: count, localized: localized)
		case .graphicCircular: return try SharedEventTemplates.graphicCircularTemplate(with: count, localized: localized)
		case .graphicCorner: return try SharedEventTemplates.graphicCornerTemplate(with: count, localized: localized)
		case .graphicExtraLarge: return try SharedEventTemplates.graphicExtraLargeTemplate(with: count, localized: localized)
		case .graphicRectangular: return try SharedEventTemplates.graphicRectangularTemplate(with: count, localized: localized)
		case .modularSmall: return SharedEventTemplates.modularSmallTemplate(with: count, localized: localized)
		case .modularLarge: return SharedEventTemplates.modularLargeTemplate(with: count, localized: localized)
		case .utilitarianSmall, .utilitarianSmallFlat: return SharedEventTemplates.utilitarianSmallTemplate(with: count, localized: localized)
		case .utilitarianLarge: return SharedEventTemplates.utilitarianLargeTemplate(with: count, localized: localized)
		@unknown default:
			throw ComplicationControllerError.unexpectedComplicationFamily(rawValue: complication.family.rawValue)
		}
	}

	fileprivate func getCurrentCout() throws -> Int {
		do {
			return try Services.access(DataService.self).getTapCount()
		} catch {
			loggingService.log(.error, "Error obtaining tap count: %{public}@", error.localizedDescription)
			return try Services.access(WatchSessionSettingsService.self).lastSharedEventComplicationCount
		}
	}

	fileprivate func getTemplateWithPhoneData(for complication: CLKComplication, localized: Bool, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
		watchSessionService.fetchSharedEventCount { [self, loggingService] result in
			let template: CLKComplicationTemplate?
			do {
				switch result {
				case .success(let count):
					template = try self.generateSharedEventTemplate(for: complication, with: count, localized: localized)
				case .failure(let error):
					loggingService.log(.error, "ComplicationController unable to retrieve count for placeholde template: %{public}@", error.localizedDescription)
					template = try self.generateSharedEventTemplate(for: complication, with: 85, localized: localized)
				}
			} catch {
				loggingService.log(.error, "Error generating shared event template: %{public}@", error.localizedDescription)
				template = nil
			}
			handler(template)
		}
	}
}

extension ComplicationController: CLKComplicationDataSource {

	func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
		handler([])
	}

	#if swift(>=5.3) // Xcode 12.x

	@available(watchOS 7.0, *)
	func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
		loggingService.log(.info, "Getting complication descriptors")
		let descriptors: [CLKComplicationDescriptor] = [
			CLKComplicationDescriptor(identifier: CLKDefaultComplicationIdentifier, displayName: "Shared Events", supportedFamilies: sharedEventComplicationFamilies, userActivity: userActivityService.userActivity(for: .coreData))
		]
		handler(descriptors)
	}
	
	#endif

	func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
		getTemplateWithPhoneData(for: complication, localized: true, withHandler: handler)
	}

	func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
		getTemplateWithPhoneData(for: complication, localized: false, withHandler: handler)
	}

	func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
		// This complication only presents one piece of information at a time (the latest)
		do {
			let count = try getCurrentCout()
			let template = try generateSharedEventTemplate(for: complication, with: count, localized: false)
			handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template))
		} catch {
			loggingService.log(.error, "Error generating shared event template: %{public}@", error.localizedDescription)
			handler(nil)
		}
	}
}
