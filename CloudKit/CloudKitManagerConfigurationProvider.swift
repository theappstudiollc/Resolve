//
//  CloudKitManagerConfigurationProvider.swift
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

import CloudKit
import CoreResolve

public struct CloudKitManagerConfigurationProvider: CloudKitManagerConfigurationProviding {
	
	public var container: CKContainer

	@Service public var dataService: DataService
	@Service public var settingsService: CloudKitSettingsService
	@Service public var userService: AppUserService

	public let loggingService: CoreLoggingService
	
	public let notificationCenter: NotificationCenter
	
	private let resourceManager: ResourceManaging

	public func operationQueue(for qualityOfService: QualityOfService) -> OperationQueue {
		switch qualityOfService {
		case .background: return backgroundOperationQueue
		case .userInitiated: return userInitiatedOperationQueue
		case .userInteractive: return userInteractiveOperationQueue
		case .utility, .default: return utilityOperationQueue
		@unknown default: fatalError()
		}
	}

	public func cancelAllOperations() {
		backgroundOperationQueue.cancelAllOperations()
		userInitiatedOperationQueue.cancelAllOperations()
		userInteractiveOperationQueue.cancelAllOperations()
		utilityOperationQueue.cancelAllOperations()
	}

	private let backgroundOperationQueue: OperationQueue
	private let userInitiatedOperationQueue: OperationQueue
	private let userInteractiveOperationQueue: OperationQueue
	private let utilityOperationQueue: OperationQueue
	
	public init(with identifier: String, resourceManager: ResourceManaging, loggingService: CoreLoggingService, notificationCenter: NotificationCenter = .default) {
		// TODO: Assert that we are able to resolve CoreDataService and AppUserService before continuing and throw
		container = CKContainer(identifier: identifier)
		self.loggingService = loggingService
		self.notificationCenter = notificationCenter
		self.resourceManager = resourceManager
		backgroundOperationQueue = OperationQueue(name: "\(identifier).BackgroundOperationQueue", qualityOfService: .background)
		userInitiatedOperationQueue = OperationQueue(name: "\(identifier).UserInitiatedOperationQueue", qualityOfService: .userInitiated)
		userInteractiveOperationQueue = OperationQueue(name: "\(identifier).UserInteractiveOperationQueue", qualityOfService: .userInteractive)
		utilityOperationQueue = OperationQueue(name: "\(identifier).UtilityOperationQueue", qualityOfService: .utility)
	}
}

fileprivate extension OperationQueue {

	convenience init(name: String, qualityOfService: QualityOfService) {
		self.init()
		self.name = name
		self.qualityOfService = qualityOfService
	}
}
