//
//  ShimExtensions.swift
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

import CoreResolve

public extension Label {

	var labelText: String {
		get {
			#if os(iOS) || os(tvOS)
			return text ?? ""
			#elseif os(macOS)
			return stringValue
			#endif
		}
		set {
			#if os(iOS) || os(tvOS)
			text = newValue
			#elseif os(macOS)
			stringValue = newValue
			#endif
		}
	}
}

public extension TextField {

	var trimmedText: String {
		get {
			#if os(iOS) || os(tvOS)
			return text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			#elseif os(macOS)
			return stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
			#endif
		}
		set {
			#if os(iOS) || os(tvOS)
			text = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
			#elseif os(macOS)
			stringValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
			#endif
		}
	}
}
