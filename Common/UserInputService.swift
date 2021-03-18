//
//  UserInputService.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2017 The App Studio LLC.
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
import Foundation
#if canImport(MultipeerConnectivity)
import MultipeerConnectivity
#endif

#if os(iOS) || os(tvOS)

enum UserInputSaveConfirmationResult {
	case save
	case discard
	case cancel
}

#endif

protocol UserInputService {

	#if canImport(WatchKit)
	typealias DialogPresenter = WKInterfaceController
	#elseif canImport(UIKit)
	typealias DialogPresenter = UIResponder
	#elseif canImport(AppKit)
	typealias DialogPresenter = NSResponder
	#endif

	#if os(watchOS)

	func presentError(_ error: Error, withTitle title: String?, from presenter: DialogPresenter)

	#else
	
	func presentAlert(_ alert: String, withTitle title: String?, from presenter: DialogPresenter, forDuration duration: TimeInterval)

	#endif
	
	#if os(iOS) || os(tvOS)
	
	func presentAppSettings(withTitle title: String, message: String, from presenter: DialogPresenter, decisionHandler: ((_ launchedSettings: Bool) -> Void)?)
	
	func presentBrowser(for session: MCSession, from presenter: DialogPresenter)
	
	func presentSaveConfirmation(withTitle title: String?, message: String?, from presenter: DialogPresenter, decisionHandler: @escaping (_ result: UserInputSaveConfirmationResult) -> Void)

	func presentTextInputAlert(withTitle title: String, message: String, from presenter: DialogPresenter, completionHandler: @escaping (_ text: String?) -> Void)
	
	#endif
}
