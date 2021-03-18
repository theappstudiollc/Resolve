//
//  AppGroupFileStoreURLProvider.swift
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

import CoreResolve

// MARK: - Application Reserved Directory Types for the CoreFileStoreService
extension CoreFileStoreDirectoryType {
	
	/// The shared App Group directory for the iOS app and its extensions
	public static let appGroup = CoreFileStoreDirectoryType.applicationReserved1
	
	/// The Application Data directory within the shared App Group directory
	public static let appGroupApplicationData = CoreFileStoreDirectoryType.applicationReserved2
}

/// Provides URLs for the FileStoreManager, including App Group URLs
public final class AppGroupFileStoreManagerUrlProvider: FileStoreManagerUrlProvider {
	
	/// The AppGroupProviding instance
	let appGroupProvider: AppGroupProviding!
	
	/// Returns the URL for the given CoreFileStoreDirectoryType
	///
	/// - Parameter directoryType: The CoreFileStoreDirectoryType for which information is being requested
	/// - Returns: The URL for the given CoreFileStoreDirectoryType, or nil if unknown
	override public func directoryUrl(for directoryType: CoreFileStoreDirectoryType) -> URL? {
		switch directoryType {
		case .appGroup:
			return appGroupProvider.appGroupContainer
		case .appGroupApplicationData:
			if let groupDirectory = directoryUrl(for: .appGroup) {
				return groupDirectory.appendingPathComponent("ApplicationData", isDirectory: true)
			}
		default:
			return super.directoryUrl(for: directoryType)
		}
		return nil
	}
	
	/// Initializes a new instance of the AppGroupFileStoreManagerUrlProvider
	///
	/// - Parameters:
	///   - applicationBundle: The Bundle for the Application so that proper URLs can be calculated
	///   - appGroupProvider: An AppGroupProviding instance to provide App Group information
	public required init(applicationBundle: Bundle, appGroupProvider: AppGroupProviding, fileManager: FileManager = .default) {
		self.appGroupProvider = appGroupProvider
		super.init(applicationBundle: applicationBundle, fileManager: fileManager)
	}
}
