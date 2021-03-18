//
//  Extensions-AppKit.swift
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

import AppKit

public extension ResolveBinding where Self: NSControl {

	func bind<Value>(_ event: NSEvent.EventTypeMask, from sourcePath: KeyPath<Self, Value>, to action: @escaping (Value) -> Void) -> Unbind {
		return Binding<Self>(control: self, action: { control in
			action(control[keyPath: sourcePath])
		}, for: event).dispose
	}

	func bind<Destination, Value>(_ event: NSEvent.EventTypeMask, from sourcePath: KeyPath<Self, Value>, to destination: Destination, on destinationPath: ReferenceWritableKeyPath<Destination, Value>) -> Unbind {
		return bind(event, from: sourcePath, to: destination, on: destinationPath) { $0 }
	}

	func bind<Destination, Value, Intermediate>(_ event: NSEvent.EventTypeMask, from sourcePath: KeyPath<Self, Intermediate>, to destination: Destination, on destinationPath: ReferenceWritableKeyPath<Destination, Value>, with conversion: @escaping (Intermediate) -> Value) -> Unbind {
		destination[keyPath: destinationPath] = conversion(self[keyPath: sourcePath])
		return bind(event, from: sourcePath) { source in
			destination[keyPath: destinationPath] = conversion(source)
		}
	}
}
