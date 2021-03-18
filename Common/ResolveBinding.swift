//
//  ResolveBinding.swift
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

import Foundation

public protocol ResolveBinding {

	typealias Unbind = () -> Void
}

public extension ResolveBinding where Self: NSObject {

	func bind<Value>(_ sourcePath: KeyPath<Self, Value>, includeInitial: Bool = false, to action: @escaping (Value) -> Void) -> Unbind {
		let options: NSKeyValueObservingOptions = includeInitial ? [.initial, .new] : .new
		let observer = observe(sourcePath, options: options) { source, _ in
			action(source[keyPath: sourcePath])
		}
		return { observer.invalidate() }
	}

	func bind<Destination, Value>(_ sourcePath: KeyPath<Self, Value>, to destination: Destination, on destinationPath: ReferenceWritableKeyPath<Destination, Value>) -> Unbind {
		return bind(sourcePath, to: destination, on: destinationPath) { $0 }
	}

	func bind<Destination, Value, Intermediate>(_ sourcePath: KeyPath<Self, Intermediate>, to destination: Destination, includeInitial: Bool = true, on destinationPath: ReferenceWritableKeyPath<Destination, Value>, with conversion: @escaping (Intermediate) -> Value) -> Unbind {
		return bind(sourcePath, includeInitial: includeInitial) { source in
			destination[keyPath: destinationPath] = conversion(source)
		}
	}
}

extension NSObject: ResolveBinding { }

// TODO: Create a resolve binding set that can manage a collection of ResolveBindings
