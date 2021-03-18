//
//  Debugging-UIKit.swift
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

extension NavigationController /*: CorePrintsViewControllerLayout*/ {

	override var debugDescription: String {
		guard let topViewController = topViewController else { return "\(type(of: self))" }
		let title = topViewController.navigationItem.title ?? topViewController.title ?? "\(type(of: topViewController))"
		return "\(type(of: self))[\(title)]"
	}
}

extension RootViewController: CorePrintsStateRestoration {

	override var debugDescription: String {
		guard let activeChild = activeChild else { return "\(type(of: self))" }
		return "\(type(of: self))[\(type(of: activeChild))]"
	}
}

extension SplitViewController: CorePrintsStateRestoration {

	override var debugDescription: String {
		let childDescriptions = children.map({ $0.debugDescription }).joined(separator: ",")
		return "\(type(of: self))[\(childDescriptions)]"
	}
}

extension UIContentSizeCategory: CustomDebugStringConvertible {

	public var debugDescription: String {
		switch self {
		case .accessibilityExtraExtraExtraLarge: return "aXXXL"
		case .accessibilityExtraExtraLarge: return "aXXL"
		case .accessibilityExtraLarge: return "aXL"
		case .accessibilityLarge: return "aL"
		case .accessibilityMedium: return "aM"
		case .extraExtraExtraLarge: return "XXXL"
		case .extraExtraLarge: return "XXL"
		case .extraLarge: return "XL"
		case .extraSmall: return "XS"
		case .large: return "L"
		case .medium: return "M"
		case .small: return "S"
		default:
			if #available(iOS 10.0, tvOS 10.0, *), self == .unspecified {
				return "unspecified"
			}
			fatalError("Study new value of '\(rawValue)' for \(Self.self)")
		}
	}
}

@available(iOS 10.0, tvOS 10.0, *)
extension UIDisplayGamut: CustomDebugStringConvertible {

	public var debugDescription: String {
		switch self {
		case .P3: return "P3"
		case .SRGB: return "SRGB"
		case .unspecified: return "unspecified"
		@unknown default: fatalError("Study new value of '\(rawValue)' for \(Self.self)")
		}
	}
}

extension UITraitCollection {

	override open var debugDescription: String {
		/*
		<UITraitCollection: 0x2826ae580; _UITraitNameUserInterfaceIdiom = Phone, _UITraitNameDisplayScale = 3.000000, _UITraitNameDisplayGamut = P3, _UITraitNameHorizontalSizeClass = Compact, _UITraitNameVerticalSizeClass = Compact, _UITraitNameUserInterfaceStyle = 1, _UITraitNameUserInterfaceLayoutDirection = 0, _UITraitNameForceTouchCapability = 2, _UITraitNamePreferredContentSizeCategory = UICTContentSizeCategoryL>
		*/
		var components = [String]()
		components.append("\(userInterfaceIdiom)")
		components.append("H:\(horizontalSizeClass),V:\(verticalSizeClass)")
		if #available(iOS 10.0, tvOS 10.0, *) {
			components.append("C:\(preferredContentSizeCategory)")
			components.append("\(displayGamut)")
		}
		components.append("@\(displayScale)x")
		return "\(type(of: self))[\(components.joined(separator: " "))]"
	}
}

extension UIUserInterfaceIdiom: CustomDebugStringConvertible {

	public var debugDescription: String {
		switch self {
		case .carPlay: return "carPlay"
		#if swift(>=5.3) // Xcode 12.x
		case .mac: return "mac"
		#endif
		case .pad: return "iPad"
		case .phone: return "iPhone"
		case .tv: return "tv"
		case .unspecified: return "unspecified"
		@unknown default: fatalError("Study new value of '\(rawValue)' for \(Self.self)")
		}
	}
}

extension UIUserInterfaceSizeClass: CustomDebugStringConvertible {

	public var debugDescription: String {
		switch self {
		case .compact: return "compact"
		case .regular: return "regular"
		case .unspecified: return "unspecified"
		@unknown default: fatalError("Study new value of '\(rawValue)' for \(Self.self)")
		}
	}
}
