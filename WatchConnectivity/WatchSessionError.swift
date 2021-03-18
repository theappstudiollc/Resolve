//
//  WatchSessionError.swift
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

import Foundation

public enum WatchSessionError: Error {

	case countNotAccepted
	case sessionNotAvailable
	case unexpected(_ inner: Error)
	case valueNotRetrieved
}

extension WatchSessionError: LocalizedError {

	public var errorDescription: String? {
		switch self {
		case .unexpected(let innerError):
			return innerError.localizedDescription
		default:
			return NSLocalizedString("\(self).errorDescription", tableName: "WatchSessionError", bundle: Bundle(for: WatchSessionManager.self), comment: "\(self)")
		}
	}
}
