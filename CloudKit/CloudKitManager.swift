//
//  CloudKitManager.swift
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
#if canImport(Contacts)
import Contacts
#endif
import CoreData
import CoreResolve
import os.log

public final class CloudKitManager: CoreWorkflowOperationManager<CloudKitContext>, CloudKitService {
	
	public private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
	
	internal var configuration: CloudKitManagerConfigurationProviding

	public private(set) var currentUserRecordID: CKRecord.ID?
	
	public private(set) var linkedUserObjectID: NSManagedObjectID?

	public private(set) var retryAfterRequest: Date?
	
	public private(set) var userDiscoverabilityPermissionStatus: CKContainer.Application.PermissionStatus = .initialState

	public var lastFullSync: Date {
		return configuration.settingsService.lastFullSync ?? .distantPast
	}
	
	public func cancelAllOperations() {
		configuration.cancelAllOperations()
	}

	public func canProcess(notification: CKNotification) -> Bool {
		return notification.containerIdentifier == configuration.container.containerIdentifier
	}

	#if canImport(Contacts)

	@discardableResult public func addFriends(contacts: [CNContact], _ completion: CloudKitServiceSynchronizationCompletion?) -> Progress? {
		let context = CloudKitContext(with: self)

		let setupOperations = configureSetupOperations(with: context)
		let lookupFriendsOperations = LookupFriendsCloudKitOperations(with: context, contacts: contacts)
		let syncUserOperations = SyncUserCloudKitOperations(with: context, configuration: configuration)
		let cleanupOperation = configureCleanupOperation(with: context)

		// Setup inter-group dependencies (TODO: Determine if there's a better way to do this)
		setupOperations.lastOperation.linkWorkflow(to: lookupFriendsOperations.firstOperation)
//		setupOperations.lastOperation.linkWorkflow(to: syncUserOperations.firstOperation) // This is implied by the line below
		lookupFriendsOperations.lookupUsersOperation.linkWorkflow(to: syncUserOperations.updateUsersOperation, cancelOnError: true) { lookupUsers, updateUsers in
			context.logger.debug("%{public}@ found %ld users", "\(type(of: lookupUsers))", lookupUsers.userInfos.count)
			updateUsers.userInfos = lookupUsers.userInfos
		}
		syncUserOperations.lastOperation.linkWorkflow(to: cleanupOperation)

		// Assign an operation group so that we have a meaningful name in the logs
		let operationQueue = configuration.operationQueue(for: .default)
		if #available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *) {
			let operationGroup = configureOperationGroup(name: "requestUserDiscoverabilityPermission", qualityOfService: operationQueue.qualityOfService)
			setupOperations.applyOperationGroup(operationGroup)
			lookupFriendsOperations.applyOperationGroup(operationGroup)
			syncUserOperations.applyOperationGroup(operationGroup)
		}

		// Now send off the operations
		guard let operation = startOperations(cleanupOperation.allDependencies(), in: operationQueue, with: context, for: completion) else {
			return nil
		}
		let retVal = Progress(totalUnitCount: 3)
		retVal.addChild(setupOperations.progress, withPendingUnitCount: 1)
		retVal.addChild(lookupFriendsOperations.progress, withPendingUnitCount: 1)
		retVal.addChild(syncUserOperations.progress, withPendingUnitCount: 1)
		retVal.addChild(cleanupOperation.progress, withPendingUnitCount: 1)
		retVal.cancellationHandler = {
			operation.cancel()
		}
		return retVal
	}

	#endif
	
	@discardableResult public func requestUserDiscoverabilityPermission(_ completion: @escaping CloudKitServiceSynchronizationCompletion) -> Progress? {
		let context = CloudKitContext(with: self)

		let setupOperations = configureSetupOperations(with: context)
		let findFriendsOperations = FindFriendsCloudKitOperations(with: context)
		let syncUserOperations = SyncUserCloudKitOperations(with: context, configuration: configuration)
		let cleanupOperation = configureCleanupOperation(with: context)
		
		// Setup inter-group dependencies (TODO: Determine if there's a better way to do this)
		setupOperations.lastOperation.linkWorkflow(to: findFriendsOperations.firstOperation)
//		setupOperations.lastOperation.linkWorkflow(to: syncUserOperations.firstOperation) // This is implied by the line below
		findFriendsOperations.discoverUsersOperation.linkWorkflow(to: syncUserOperations.updateUsersOperation, cancelOnError: true) { discoverUsers, updateUsers in
			context.logger.debug("%{public}@ found %ld users", "\(type(of: discoverUsers))", discoverUsers.userInfos.count)
			updateUsers.userInfos = discoverUsers.userInfos
		}
		syncUserOperations.lastOperation.linkWorkflow(to: cleanupOperation)
		
		// Assign an operation group so that we have a meaningful name in the logs
		let operationQueue = configuration.operationQueue(for: .default)
		if #available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *) {
			let operationGroup = configureOperationGroup(name: "requestUserDiscoverabilityPermission", qualityOfService: operationQueue.qualityOfService)
			setupOperations.applyOperationGroup(operationGroup)
			findFriendsOperations.applyOperationGroup(operationGroup)
			syncUserOperations.applyOperationGroup(operationGroup)
		}
		
		// Now send off the operations
		guard let operation = startOperations(cleanupOperation.allDependencies(), in: operationQueue, with: context, for: completion) else {
			return nil
		}
		let retVal = Progress(totalUnitCount: 3)
		retVal.addChild(setupOperations.progress, withPendingUnitCount: 1)
		retVal.addChild(findFriendsOperations.progress, withPendingUnitCount: 1)
		retVal.addChild(syncUserOperations.progress, withPendingUnitCount: 1)
		retVal.addChild(cleanupOperation.progress, withPendingUnitCount: 1)
		retVal.cancellationHandler = {
			operation.cancel()
		}
		return retVal
	}
	
	@discardableResult public func fetchChanges(notification: CKNotification, qualityOfService: QualityOfService, _ completion: @escaping CloudKitServiceSynchronizationCompletion) -> Progress? {

		guard canProcess(notification: notification) else {
			completion(.failure(CloudKitError.unsupportedWorkflow("\(Self.self) does not support notifications with container identifier of `\(notification.containerIdentifier ?? "<nil>")`")))
			return nil
		}
		
		print("Received notification: \(notification)")
		if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *),
			// TODO: Implement this!
			let _ = notification as? CKDatabaseNotification {
//			let token = configuration.settingsService.fetchDatabaseChangeToken
//			let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: token)
			completion(.failure(CloudKitError.unsupportedWorkflow("Currently unsupported: \(type(of: notification))")))
			return nil
		}
		switch notification {
		case let queryNotification as CKQueryNotification:
			let context = CloudKitContext(with: self)
			guard let queryNotificationOperations = QueryNotificationCloudKitOperations(with: context, configuration: configuration, queryNotification: queryNotification) else {
				completion(.failure(CloudKitError.unsupportedWorkflow("Currently unsupported: \(type(of: queryNotification))")))
				return nil // We can't yet handle this notification
			}
			let setupOperations = configureSetupOperations(with: context)
			let cleanupOperation = configureCleanupOperation(with: context)
			
			// Setup inter-group dependencies (TODO: Determine if there's a better way to do this)
			setupOperations.lastOperation.linkWorkflow(to: queryNotificationOperations.firstOperation)
			queryNotificationOperations.lastOperation.linkWorkflow(to: cleanupOperation)
			
			// Assign an operation group so that we have a meaningful name in the logs
			if #available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *) {
				let operationGroup = configureOperationGroup(name: "fetchChanges", qualityOfService: qualityOfService)
				setupOperations.applyOperationGroup(operationGroup)
				queryNotificationOperations.applyOperationGroup(operationGroup)
			}

			// Now send off the operations
			let operationQueue = configuration.operationQueue(for: qualityOfService)
			guard let operation = startOperations(cleanupOperation.allDependencies(), in: operationQueue, with: context, for: completion) else {
				return nil
			}
			let retVal = Progress(totalUnitCount: 3)
			retVal.addChild(setupOperations.progress, withPendingUnitCount: 1)
			retVal.addChild(queryNotificationOperations.progress, withPendingUnitCount: 1)
			retVal.addChild(cleanupOperation.progress, withPendingUnitCount: 1)
			retVal.cancellationHandler = {
				operation.cancel()
			}
			return retVal
		default:
			completion(.failure(CloudKitError.unsupportedWorkflow("Unexpected CKNotification: \(type(of: notification))")))
			return nil
		}
	}
	
	@discardableResult public func synchronize(syncOptions: CloudKitServiceSyncOptions, qualityOfService: QualityOfService, _ completion: CloudKitServiceSynchronizationCompletion?) -> Progress? {
		
		var additionalProgress = [Progress]()
		let context = CloudKitContext(with: self)
		
		// First define the operations and add them
		let setupOperations = configureSetupOperations(with: context)
		let syncEntitiesOperations = SyncEntitiesCloudKitOperations(with: context, configuration: configuration, syncOptions: syncOptions)
		let cleanupOperation = configureCleanupOperation(with: context)
		if syncOptions.contains(.fullSync) {
			cleanupOperation.addFinishClosure { [settingsService = configuration.settingsService] operation in
				guard operation.workflowContext.error == nil else { return }
				settingsService.lastFullSync = Date()
			}
		}
		
		// Setup inter-group dependencies (TODO: Determine if there's a better way to do this)
		setupOperations.lastOperation.linkWorkflow(to: syncEntitiesOperations.firstOperation)
		if syncOptions.contains(.fetchAll) || syncOptions.contains(.refreshAll) {
			setupOperations.linkUserOperation.linkWorkflow(to: syncEntitiesOperations.syncRecordsPrivateOperation) { linkUser, syncPrivate in
				guard let userRecordID = linkUser.currentUserRecordID ?? context.currentUserRecordID else { fatalError("We should have a record ID by now") }
				syncPrivate.addRecordsToFetch(from: Set(arrayLiteral: userRecordID))
			}
		}
		syncEntitiesOperations.lastOperation.linkWorkflow(to: cleanupOperation)

		// TODO: Work out a scenario where watchOS < 6.0 can obtain all the records and updates it needs without a subscription
		// Currently a .fullSync (performed as often as every 2 weeks) may aleviate this issue
		let subscriptionOperation = UpdateSubscriptionCloudKitOperation(with: context)
		if !syncOptions.contains(.fullSync) {
			// Force a re-subscription by omitting the currently known subscribedUsers whenever performing a .fullSync
			subscriptionOperation.subscribedUsers = configuration.settingsService.subscribedUsers
		}
		syncEntitiesOperations.usersWithFriendsOperation.link(to: subscriptionOperation) { usersWithFriends, subscription in
			subscription.userRecordIDs = usersWithFriends.userRecordIDs
		}
		subscriptionOperation.addFinishClosure { operation in
			guard operation.error == nil else { return }
			self.configuration.settingsService.subscribedUsers = operation.subscribedUsers
		}
		subscriptionOperation.linkWorkflow(to: cleanupOperation)
		additionalProgress.append(subscriptionOperation.progress)

		// Assign an operation group so that we have a meaningful name in the logs
		if #available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *) {
			let operationGroup = configureOperationGroup(name: "synchronize.\(syncOptions.rawValue)", qualityOfService: qualityOfService)
			setupOperations.applyOperationGroup(operationGroup)
			subscriptionOperation.operationGroup = operationGroup
			syncEntitiesOperations.applyOperationGroup(operationGroup)
		}

		// Finally, startup the workflow
		let operationQueue = configuration.operationQueue(for: qualityOfService)
		guard let operation = startOperations(cleanupOperation.allDependencies(), in: operationQueue, with: context, for: completion) else {
			return nil
		}
		// Prepare the Progress return value
        let retVal = Progress(totalUnitCount: Int64(3 + additionalProgress.count))
		retVal.addChild(setupOperations.progress, withPendingUnitCount: 1)
		retVal.addChild(syncEntitiesOperations.progress, withPendingUnitCount: 1)
		retVal.addChild(cleanupOperation.progress, withPendingUnitCount: 1)
		additionalProgress.forEach({ retVal.addChild($0, withPendingUnitCount: 1) })
		retVal.cancellationHandler = {
			operation.cancel()
		}
		return retVal
	}
	
	public init(configuration: CloudKitManagerConfigurationProviding) {
		self.configuration = configuration
		super.init()
		configuration.notificationCenter.addObserver(self, selector: #selector(cloudUserLoginChanged(_:)), name: .CKAccountChanged, object: nil)
	}
	
	// MARK: - Private properties and methods
	
	@objc private func cloudUserLoginChanged(_ notification: Notification) {
		configuration.loggingService.log(.info, "CloudKit Login changed: %{public}@", String(describing: notification.userInfo))
		// TODO: Consider a waitUntilAllOperationsComplete()
		cancelAllOperations()
		accountStatus = .couldNotDetermine
		currentUserRecordID = nil
		userDiscoverabilityPermissionStatus = .initialState
		// TODO: Call a set of operations to fixup the user record - which will be the dependency for future operations
	}
	
	@discardableResult private func startOperations(_ operations: Set<CloudKitOperation>, in operationQueue: OperationQueue, with context: CloudKitContext, for completionHandler: CloudKitServiceSynchronizationCompletion?) -> Operation? {
		
		if let retryAfterRequest = retryAfterRequest, retryAfterRequest > Date() {
			let error = CloudKitError.cloudBusy(retryAfterRequest)
			configuration.loggingService.log(.error, "❌ Attempt to start cloud sync before retry date: %{public}@", error.localizedDescription)
			completionHandler?(.failure(error))
		} else {
			configuration.loggingService.log(.info, "Starting synchronization with %d operations", operations.count)
			retryAfterRequest = nil
			return super.start(operations: Array(operations), in: operationQueue, with: context) { [loggingService = configuration.loggingService] result in
				switch result {
				case .success:
					loggingService.log(.info, "CloudKit sync successful")
					completionHandler?(.success(()))
				case .failure(let error):
					loggingService.log(.error, "❌ CloudKit sync error: %{public}@", error.localizedDescription)
					completionHandler?(.failure(error))
				}
			}
		}
		return nil
	}
	
	private func configureCleanupOperation(with context: CloudKitContext) -> CleanupCloudKitOperation {
		let cleanupOperation = CleanupCloudKitOperation(with: context)
		var completed = false
		cleanupOperation.addFinishClosure { operation in
			completed = true
			guard let retryAfter = operation.retryAfter else { return }
			self.retryAfterRequest = retryAfter
		}
		// Optional watchdog
		DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(120)) { [loggingService = configuration.loggingService] in
			guard !completed else { return }
			loggingService.log(.error, "❌ Cleanup operation not started: %{public}@\n%{public}@", cleanupOperation, cleanupOperation.dependencies.map({ $0.isFinished ? " - \($0)" : " - \($0) (not finished)" }).joined(separator: "\n"))
		}
		return cleanupOperation
	}
	
	@available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *)
	private func configureOperationGroup(name: String, qualityOfService: QualityOfService = .utility) -> CKOperationGroup {
		let operationGroup = CKOperationGroup()
		let configuration = operationGroup.defaultConfiguration!
		configuration.qualityOfService = qualityOfService
		operationGroup.defaultConfiguration = configuration
		operationGroup.name = name
		return operationGroup
	}
	
	private func configureSetupOperations(with context: CloudKitContext) -> SetupCloudKitOperations {
		let setupOperations = SetupCloudKitOperations(with: context, configuration: configuration)
		setupOperations.accountStatusOperation.addFinishClosure { operation in
			guard operation.accountStatus != .couldNotDetermine else { return }
			self.accountStatus = operation.accountStatus
		}
		setupOperations.fetchUserOperation.addFinishClosure { operation in
			guard let currentUserRecordID = operation.currentUserRecordID else { return }
			self.currentUserRecordID = currentUserRecordID
		}
		setupOperations.linkUserOperation.addFinishClosure { operation in
			guard let currentUserObjectID = operation.currentUserObjectID else { return }
			self.linkedUserObjectID = currentUserObjectID
		}
		return setupOperations
	}
}

extension CoreAsynchronousOperationLinking where Self: CloudKitOperation {
	
	/// Sets up a dependency so that the provided operation waits for this one to finish, with a closure to execute in between
	///
	/// - Parameters:
	///   - operation: The operation to wait for this one to finish
	///   - closure: An optional closure to execute after this one finishes but before the `operation` begins, unless the dependent operation is cancelled
	func linkWorkflow<T>(to operation: T, cancelOnError: Bool = false, performing closure: ((Self, T) -> Void)? = nil) where T: CloudKitOperation {
		operation.addDependency(self)
		let logger = workflowContext.logger
		let sourceName = nameForLogging
		let operationName = operation.nameForLogging
		addFinishClosure { source in
			if let error = source.error, cancelOnError {
				switch error {
				case let cloudKitError as CKError where cloudKitError.code == CKError.serverRejectedRequest:
					// TODO: Should we cancel future operations because of this? Should we make this more generic to print CloudKit-specific reasons?
					logger.debug(" :: %{public}@ cancelling %{public}@ because encountered error: Server Rejected Request", sourceName, operationName)
				default:
					logger.debug(" :: %{public}@ cancelling %{public}@ because encountered error: %{public}@", sourceName, operationName, error.localizedDescription)
				}
				operation.cancel()
			} else if let error = source.workflowContext.error, operation.shouldCancelOnContextError {
				switch error {
				case let cloudKitError as CKError where cloudKitError.code == CKError.serverRejectedRequest:
					// TODO: Should we cancel future operations because of this? Should we make this more generic to print CloudKit-specific reasons?
					logger.debug(" :: WorkflowContext cancelling %{public}@ because: Server Rejected Request", operationName)
				default:
					logger.debug(" :: WorkflowContext cancelling %{public}@ because: %{public}@", operationName, error.localizedDescription)
				}
				operation.cancel()
			} else if !source.isCancelled, !operation.isCancelled {
				if let closure = closure {
					logger.debug(" :: %{public}@ -> %{public}@ with closure", sourceName, operationName)
					closure(source, operation)
				} else {
					logger.debug(" :: %{public}@ -> %{public}@", sourceName, operationName)
				}
			}
		}
	}
}

internal protocol CloudKitManagerOperationGroup {
    
    var firstOperation: CloudKitOperation { get }
    
    var lastOperation: CloudKitOperation { get }
    
    var progress: Progress { get }
	
	@available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *)
	func applyOperationGroup(_ operationGroup: CKOperationGroup)
}

extension CloudKitOperation {
	
	fileprivate func allDependencies() -> Set<CloudKitOperation> {
		var retVal = Set<CloudKitOperation>()
		retVal.insert(self)
		for dependency in dependencies.map({ $0 as! CloudKitOperation }) {
			retVal.formUnion(dependency.allDependencies())
		}
		return retVal
	}
}
