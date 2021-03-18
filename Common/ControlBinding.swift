//
//  ControlBinding.swift
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

#if os(iOS) || os(tvOS)
import UIKit
typealias Control = UIControl
typealias ControlEvent = UIControl.Event
#elseif os(macOS)
import AppKit
typealias Control = NSControl
typealias ControlEvent = NSEvent.EventTypeMask
#endif

internal class ControlBinding: NSObject {

	let action: (Control) -> Void
	unowned var control: Control
	let event: ControlEvent

	deinit {
		print("\(type(of: self)) deinit")
	}

	fileprivate init(control: Control, action: @escaping (Control) -> Void, for event: ControlEvent) {
		self.action = action
		self.control = control
		self.event = event
		super.init()
		#if canImport(UIKit)
		control.addTarget(self, action: #selector(eventNotified(_:)), for: event)
		#elseif canImport(AppKit)
		control.target = self
		control.action = #selector(eventNotified(_:))
		control.sendAction(on: event)
		#endif
	}

	@objc func eventNotified(_ control: Control) {
		action(control)
	}

	func dispose() {
		#if canImport(UIKit)
		control.removeTarget(self, action: #selector(eventNotified), for: event)
		#elseif canImport(AppKit)
		control.target = nil
		control.action = nil
		#endif
	}
}

internal class Binding<TControl>: ControlBinding where TControl: Control {

	required init(control: TControl, action: @escaping (TControl) -> Void, for event: ControlEvent) {
		super.init(control: control, action: { action($0 as! TControl) }, for: event)
	}
}
