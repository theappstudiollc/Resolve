//
//  FileStoreManagerUrlProvider.swift
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

import CoreResolve

// MARK: - Adds directory types as one of the applicationReserved types

extension CoreFileStoreDirectoryType {
	
	/// The directory for application-specific data. TODO: Consider whether this needs to continue existing
	public static let applicationData = CoreFileStoreDirectoryType.applicationReserved0
	
	/// The custom directory for this application on iCloud Drive (TODO)
	public static let iCloudDrive = CoreFileStoreDirectoryType.applicationReserved1
}

/// Provides URLs for the FileStoreManager, including App Group URLs
public class FileStoreManagerUrlProvider: CoreFileStoreManagerUrlProvider {
	
	/// Returns the URL for the given CoreFileStoreDirectoryType
	///
	/// - Parameter directoryType: The CoreFileStoreDirectoryType for which information is being requested
	/// - Returns: The URL for the given CoreFileStoreDirectoryType, or nil if unknown
	public override func directoryUrl(for directoryType: CoreFileStoreDirectoryType) -> URL? {
		switch directoryType {
		case .applicationData:
			if let applicationSupportDirectory = directoryUrl(for: .applicationSupport) {
				return applicationSupportDirectory.appendingPathComponent("ApplicationData", isDirectory: true)
			}
		default:
			return super.directoryUrl(for: directoryType)
		}
		return nil
	}
}
