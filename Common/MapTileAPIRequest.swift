//
//  MapTileAPIRequest.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2018 The App Studio LLC.
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

public struct MapTileIdentifierComponents: Hashable {
	
	let column: Int
	let row: Int
	let zoom: Int
}

extension MapTileIdentifierComponents: CustomDebugStringConvertible {

	public var debugDescription: String {
		return "\(zoom)/\(column)/\(row)"
	}
}

enum MapTileAPIRequestError: Error {
	case inputDataFailure
	case responseDataFailure
	case urlFailure
}

public struct MapTileAPIRequest: CoreAPIRequest {
	
	public typealias RequestDataType = MapTileIdentifierComponents

	public typealias ResponseDataType = Image

	public let baseURL: URL
	
	public func makeRequest(from data: MapTileIdentifierComponents) throws -> URLRequest {
		guard (0..<20).contains(data.zoom) else {
			throw MapTileAPIRequestError.inputDataFailure
		}
		let maxSide = Int(pow(2.0, Double(data.zoom)))
		guard (0..<maxSide).contains(data.column), (0..<maxSide).contains(data.row) else {
			throw MapTileAPIRequestError.inputDataFailure
		}
		guard let imageURL = URL(string: "\(data.zoom)/\(data.column)/\(data.row).png", relativeTo: baseURL) else {
			throw MapTileAPIRequestError.urlFailure
		}
		return URLRequest(url: imageURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
	}
	
	public func parseResponse(data: Data) throws -> Image {
		guard let retVal = Image(data: data) else {
			throw MapTileAPIRequestError.responseDataFailure
		}
		return retVal
	}
}
