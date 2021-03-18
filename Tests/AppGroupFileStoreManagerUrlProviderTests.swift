//
//  AppGroupFileStoreManagerUrlProviderTests.swift
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

import XCTest
@testable import ResolveKit

class AppGroupFileStoreManagerUrlProviderTests: XCTestCase, ResolveKit.AppGroupProviding {
	
	private var appGroupIdentifier: String = "test.group.identifier"
	private var teamIdentifier: String = "team"
	var appGroupCookies: HTTPCookieStorage {
		return HTTPCookieStorage()
	}
	var appGroupContainer: URL {
		return URL(fileURLWithPath: "test.container", isDirectory: true)
	}
	var appGroupDefaults: UserDefaults {
		return UserDefaults(suiteName: "\(teamIdentifier).\(appGroupIdentifier)")!
	}
	
	var bundle: Bundle!
	var bundleIdentifier: String!
	var urlProvider: AppGroupFileStoreManagerUrlProvider!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		bundle = Bundle(for: AppGroupFileStoreManagerUrlProviderTests.self)
		bundleIdentifier = bundle.bundleIdentifier!
		urlProvider = AppGroupFileStoreManagerUrlProvider(applicationBundle: bundle, appGroupProvider: self)
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func getApplicationSupportUrl() -> URL {
		return getLibraryUrl().appendingPathComponent("Application Support", isDirectory: true)
	}
	
	func getCachesUrl() -> URL {
		return getLibraryUrl().appendingPathComponent("Caches", isDirectory: true)
	}
	
	func getLibraryUrl() -> URL {
		return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
	}
	
	func basicUrlAsserts(forUrl url: URL?) {
		XCTAssert(url != nil)
		XCTAssert(url?.isFileURL ?? false)
		XCTAssert(url?.hasDirectoryPath ?? false)
	}
	
	func testCaseSetup() {
		XCTAssert(getApplicationSupportUrl().isFileURL)
		XCTAssert(getLibraryUrl().isFileURL)
	}
	
	func testApplicationReservedDirectories() {
		XCTAssert(urlProvider.directoryUrl(for: .applicationReserved0) != nil)
		XCTAssert(urlProvider.directoryUrl(for: .applicationReserved1) != nil)
		XCTAssert(urlProvider.directoryUrl(for: .applicationReserved2) != nil)
		XCTAssert(urlProvider.directoryUrl(for: .applicationReserved3) == nil)
		XCTAssert(urlProvider.directoryUrl(for: .applicationReserved4) == nil)
		XCTAssert(urlProvider.directoryUrl(for: .applicationReserved5) == nil)
		XCTAssert(urlProvider.directoryUrl(for: .applicationReserved6) == nil)
		XCTAssert(urlProvider.directoryUrl(for: .applicationReserved7) == nil)
	}
	
	func testApplicationSupportDirectory() {
		let directoryUrl = urlProvider.directoryUrl(for: .applicationSupport)
		basicUrlAsserts(forUrl: directoryUrl)
		let expectedResult = getApplicationSupportUrl().appendingPathComponent(bundleIdentifier, isDirectory: true)
		XCTAssert(directoryUrl?.absoluteString == expectedResult.absoluteString)
	}
	
	func testApplicationSupportDirectoryBackup() {
		let shouldBackup = urlProvider.shouldExcludeForBackup(directoryType: .applicationSupport)
		XCTAssert(shouldBackup != nil && shouldBackup! == true) // ApplicationSupport should back up
	}

	func testCacheDirectory() {
		let directoryUrl = urlProvider.directoryUrl(for: .cache)
		basicUrlAsserts(forUrl: directoryUrl)
		let expectedResult = getCachesUrl().appendingPathComponent(bundleIdentifier, isDirectory: true)
		XCTAssert(directoryUrl?.absoluteString == expectedResult.absoluteString)
	}
	
	func testCacheDirectoryBackup() {
		let shouldBackup = urlProvider.shouldExcludeForBackup(directoryType: .cache)
		XCTAssert(shouldBackup != nil && shouldBackup! == true) // Cache should back up
	}
	
	func testUserDocumentsDirectory() {
		let directoryUrl = urlProvider.directoryUrl(for: .documents)
		basicUrlAsserts(forUrl: directoryUrl)
		let expectedResult = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		XCTAssert(directoryUrl?.absoluteString == expectedResult.absoluteString)
	}
	
	func testUserDocumentsDirectoryBackup() {
		let shouldBackup = urlProvider.shouldExcludeForBackup(directoryType: .documents)
		XCTAssert(shouldBackup == nil) // User Documents is already configured and no change should be made
	}
	
	func testResolveApplicationData() {
		let directoryUrl = urlProvider.directoryUrl(for: .applicationData)
		basicUrlAsserts(forUrl: directoryUrl)
		let expectedResult = getApplicationSupportUrl()
			.appendingPathComponent(bundleIdentifier, isDirectory: true)
			.appendingPathComponent("ApplicationData", isDirectory: true)
		XCTAssert(directoryUrl?.absoluteString == expectedResult.absoluteString)
	}
	
	func testResolveApplicationDataBackup() {
		let shouldBackup = urlProvider.shouldExcludeForBackup(directoryType: .applicationData)
		XCTAssert(shouldBackup == nil) // No change should be made to ResolveApplicationData (TODO: Are we sure?)
	}
	
	func testResolveGroup() {
		let directoryUrl = urlProvider.directoryUrl(for: .appGroup)
		basicUrlAsserts(forUrl: directoryUrl)
		let expectedResult = appGroupContainer
		XCTAssert(directoryUrl?.absoluteString == expectedResult.absoluteString)
	}
	
	func testResolveGroupBackup() {
		let shouldBackup = urlProvider.shouldExcludeForBackup(directoryType: .appGroup)
		XCTAssert(shouldBackup == nil) // No change should be made to ResolveGroup (TODO: Are we sure?)
	}
	
	func testResolveGroupApplicationData() {
		let directoryUrl = urlProvider.directoryUrl(for: .appGroupApplicationData)
		basicUrlAsserts(forUrl: directoryUrl)
		let expectedResult = appGroupContainer.appendingPathComponent("ApplicationData", isDirectory: true)
		XCTAssert(directoryUrl?.absoluteString == expectedResult.absoluteString)
	}
	
	func testResolveGroupApplicationDataBackup() {
		let shouldBackup = urlProvider.shouldExcludeForBackup(directoryType: .appGroupApplicationData)
		XCTAssert(shouldBackup == nil) // No change should be made to ResolveGroupApplicationData (TODO: Are we sure?)
	}
}
