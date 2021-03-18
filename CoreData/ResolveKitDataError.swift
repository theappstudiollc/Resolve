//
//  ResolveKitDataError.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2019 The App Studio LLC.
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

/// Error describing the reason for data failures in ResolveKit
///
/// - initializationFailure: There was a failure in the closure to initialize the entity
/// - invalidState: The current state of the workflow in invalid for continuing the requested operation
/// - unexpectedNilRelationship: The business logic requires that the named relationship be non-nil
/// - unknownEntity: The named entity can not be identified by the context
public enum ResolveKitDataError: Error {
	
	case initializationFailure(_ underlyingError: Error)

	case invalidState
	
	case unexpectedNilRelationship(named: String)
	
	case unknownEntity(named: String)
}

extension ResolveKitDataError: LocalizedError {
	
	public var errorDescription: String? {
		return NSLocalizedString("\(self).errorDescription", tableName: "ResolveKitDataError", bundle: Bundle(for: ResolveKitCoreDataStack.self), comment: "\(self)")
	}
}
