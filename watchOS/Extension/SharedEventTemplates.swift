//
//  SharedEventTemplates.swift
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

final class SharedEventTemplates {

	private static func ckComplicationText(_ key: String) -> String {
		return NSLocalizedString(key, tableName: "ckcomplication", bundle: Bundle(for: SharedEventTemplates.self), comment: "\(self)")
	}

	static func countTextProvider(for count: Int, localized: Bool) -> CLKTextProvider {
		// TODO: Work out whether we should include an accessibility label?
		let countString = "\(count)"
		guard localized else {
			guard #available(watchOS 6.0, *) else {
				return CLKSimpleTextProvider(text: countString)
			}
			let formatText = ckComplicationText("tapCount.format")
			return CLKSimpleTextProvider(format: formatText, countString)
		}
		let countProvider = CLKSimpleTextProvider(text: countString, shortText: nil, accessibilityLabel: nil)
		return CLKTextProvider.localizableTextProvider(withStringsFileFormatKey: "tapCount.format", textProviders: [countProvider])
	}

	static func sharedEventLabelTextProvider(localized: Bool) -> CLKTextProvider {
		guard localized else {
			let longText = ckComplicationText("sharedEventDescription")
			let shortText = ckComplicationText("sharedEventDescription.short")
			return CLKSimpleTextProvider(text: longText, shortText: shortText)
		}
		return CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "sharedEventDescription", shortTextKey: "sharedEventDescription.short")
	}

	static func circularSmallTemplate(with count: Int, localized: Bool) -> CLKComplicationTemplate {
		guard let image = UIImage(named: "Complication/Circular") else {
			let template = CLKComplicationTemplateCircularSmallSimpleText()
			template.textProvider = countTextProvider(for: count, localized: localized)
			return template
		}
		let template = CLKComplicationTemplateCircularSmallStackImage()
		template.line1ImageProvider = CLKImageProvider(onePieceImage: image)
		template.line2TextProvider = countTextProvider(for: count, localized: localized)
		return template
	}

	static func extraLargeTemplate(with count: Int, localized: Bool) -> CLKComplicationTemplate {
		guard let image = UIImage(named: "Complication/Extra Large") else {
			let template = CLKComplicationTemplateExtraLargeSimpleText()
			template.textProvider = countTextProvider(for: count, localized: localized)
			return template
		}
		let template = CLKComplicationTemplateExtraLargeStackImage()
		template.line1ImageProvider = CLKImageProvider(onePieceImage: image)
		template.line2TextProvider = countTextProvider(for: count, localized: localized)
		return template
	}

	static func graphicBezelTemplate(with count: Int, localized: Bool) throws -> CLKComplicationTemplate {
		guard #available(watchOS 5.0, *) else { throw ComplicationControllerError.unexpectedWatchOSVersion }
		let template = CLKComplicationTemplateGraphicBezelCircularText()
		template.circularTemplate = try graphicCircularTemplate(with: count, localized: localized) as! CLKComplicationTemplateGraphicCircular
		template.textProvider = sharedEventLabelTextProvider(localized: localized)
		return template
	}

	static func graphicExtraLargeTemplate(with count: Int, localized: Bool) throws -> CLKComplicationTemplate {
		guard #available(watchOS 7.0, *) else { throw ComplicationControllerError.unexpectedWatchOSVersion }
		guard let image = UIImage(named: "Complication/Graphic Extra Large") else {
			let template = CLKComplicationTemplateExtraLargeSimpleText()
			template.textProvider = countTextProvider(for: count, localized: localized)
			return template
		}
		let template = CLKComplicationTemplateGraphicExtraLargeCircularStackImage()
		template.line1ImageProvider = CLKFullColorImageProvider(fullColorImage: image)
		template.line2TextProvider = countTextProvider(for: count, localized: localized)
		return template
	}

	static func graphicRectangularTemplate(with count: Int, localized: Bool) throws -> CLKComplicationTemplate {
		guard #available(watchOS 5.0, *) else { throw ComplicationControllerError.unexpectedWatchOSVersion }
		let template = CLKComplicationTemplateGraphicRectangularStandardBody()
		template.headerTextProvider = countTextProvider(for: count, localized: localized)
		template.body1TextProvider = sharedEventLabelTextProvider(localized: localized)
		return template
	}

	static func graphicCircularTemplate(with count: Int, localized: Bool) throws -> CLKComplicationTemplate {
		guard #available(watchOS 6.0, *) else { throw ComplicationControllerError.unexpectedWatchOSVersion }
		let template = CLKComplicationTemplateGraphicCircularStackText()
		template.line1TextProvider = countTextProvider(for: count, localized: localized)
		template.line2TextProvider = sharedEventLabelTextProvider(localized: localized)
		return template
	}

	static func graphicCornerTemplate(with count: Int, localized: Bool) throws -> CLKComplicationTemplate {
		guard #available(watchOS 5.0, *) else { throw ComplicationControllerError.unexpectedWatchOSVersion }
		let template = CLKComplicationTemplateGraphicCornerStackText()
		template.innerTextProvider = sharedEventLabelTextProvider(localized: localized)
		template.outerTextProvider = countTextProvider(for: count, localized: localized)
		return template
	}

	static func modularLargeTemplate(with count: Int, localized: Bool) -> CLKComplicationTemplate {
		let template = CLKComplicationTemplateModularLargeStandardBody()
		template.headerTextProvider = sharedEventLabelTextProvider(localized: localized)
		template.body1TextProvider = countTextProvider(for: count, localized: localized)
		guard let image = UIImage(named: "Complication/Modular") else {
			return template
		}
		template.headerImageProvider = CLKImageProvider(onePieceImage: image)
		return template
	}

	static func modularSmallTemplate(with count: Int, localized: Bool) -> CLKComplicationTemplate {
		guard let image = UIImage(named: "Complication/Modular") else {
			let template = CLKComplicationTemplateModularSmallSimpleText()
			template.textProvider = countTextProvider(for: count, localized: localized)
			return template
		}
		let template = CLKComplicationTemplateModularSmallStackImage()
		template.line1ImageProvider = CLKImageProvider(onePieceImage: image)
		template.line2TextProvider = countTextProvider(for: count, localized: localized)
		return template
	}

	static func utilitarianLargeTemplate(with count: Int, localized: Bool) -> CLKComplicationTemplate {
		guard let image = UIImage(named: "Complication/Utilitarian") else {
			let template = CLKComplicationTemplateUtilitarianLargeFlat()
			template.textProvider = countTextProvider(for: count, localized: localized)
			return template
		}
		let template = CLKComplicationTemplateUtilitarianLargeFlat()
		template.imageProvider = CLKImageProvider(onePieceImage: image)
		template.textProvider = countTextProvider(for: count, localized: localized)
		return template
	}

	static func utilitarianSmallTemplate(with count: Int, localized: Bool) -> CLKComplicationTemplate {
		guard let image = UIImage(named: "Complication/Utilitarian") else {
			let template = CLKComplicationTemplateUtilitarianSmallFlat()
			template.textProvider = countTextProvider(for: count, localized: localized)
			return template
		}
		let template = CLKComplicationTemplateUtilitarianSmallFlat()
		template.imageProvider = CLKImageProvider(onePieceImage: image)
		template.textProvider = countTextProvider(for: count, localized: localized)
		return template
	}
}
