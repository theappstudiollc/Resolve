//
//  CoreDataTableViewController.swift
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

import ResolveKit
#if canImport(Intents)
import Intents
#endif

final class CoreDataTableViewController: CloudSyncingTableViewController<SharedEventTableView> {

	@Service var userService: AppUserService
	@Service var userActivityService: UserActivityService

	// MARK: - Interface Builder outlets

	#if os(iOS)
	@IBOutlet private var columnSlider: UISlider!
	#endif

	@IBAction func addButtonTapped(_ sender: Any?) {
		dataService.performAndWait { [userInputService, userService] context in
			let transactionContext = context.beginTransaction()
			do {
				// Get the current user
				let appUser = try userService.currentAppUser(using: context)
				let sharedEvent = try context.create(SharedEvent.self)
				#if os(iOS) || os(tvOS)
				sharedEvent.createdByDevice = UIDevice.current.name
				#elseif os(macOS)
				sharedEvent.createdByDevice = ProcessInfo.processInfo.hostName
				#endif
				sharedEvent.createdLocallyAt = Date().withoutMilliseconds
				sharedEvent.uniqueIdentifier = UUID().uuidString
				sharedEvent.user = appUser
				sharedEvent.createICloudReference(for: .public, with: nil)
				try context.commitTransaction(transactionContext: transactionContext)
				try self.syncCloud(delay: .milliseconds(500))
				#if os(iOS)
				guard #available(iOS 12.0, *) else { return }
				let intent = CreateSharedEventIntent()
				INInteraction(intent: intent, response: nil).donate { error in
					guard let error = error else { return }
					print("Failure to donate intent: \(error)")
				}
				#endif
			} catch {
				context.cancelTransaction(transactionContext: transactionContext)
				userInputService.presentAlert(error.localizedDescription, withTitle: "Error", from: self, forDuration: 2.0)
			}
		}
	}

	// MARK: - CloudSyncingTableViewController overrides

	deinit {
		SharedEvent.clearGroupBy(in: dataService.viewContext)
		groupChangedObserver = nil
	}

	override func deletableObjectID(for result: SharedEvent) -> NSManagedObjectID? {
		return try? dataService.performAndReturn { [userService] context in
			guard let sharedEvent = try context.existingObject(with: result.objectID) as? SharedEvent, sharedEvent.cloudSyncStatus == .normal else {
				return nil
			}
			guard let appUser = try userService.currentAppUser(using: context), sharedEvent.user == appUser || sharedEvent.notLinked else {
				return nil
			}
			return sharedEvent.objectID
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if userActivity == nil {
			#if !os(tvOS)
			userActivity = userActivityService.userActivity(for: .coreData)
			#endif
		}
		userActivity?.becomeCurrent()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		setupGroupChangedObserver()

		source = SharedEventTableViewDataSource(for: sourceTableView) { [dataService] in
			return dataService.performAndReturn { context -> NSFetchedResultsController<SharedEvent>? in
				SharedEvent.setGroupByBehavior(.live(cutoffInterval: TimeInterval(-60 * 60 * 24 * 7)), in: context)
				let request: NSFetchRequest<SharedEvent> = SharedEvent.fetchRequest()
				request.predicate = Self.defaultPredicate
				request.relationshipKeyPathsForPrefetching = [#keyPath(SharedEvent.syncReferences)]
				// Always guarantee a stable sort order (include the unique identifier if the createdAt dates match)
				request.sortDescriptors = [NSSortDescriptor(key: #keyPath(SharedEvent.createdLocallyAt), ascending: false), NSSortDescriptor(key: #keyPath(SharedEvent.uniqueIdentifier), ascending: true)]
				return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: #keyPath(SharedEvent.groupNameByTime), cacheName: nil)
			}!
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		userActivity?.resignCurrent()
	}

	// MARK: - Private properties and methods

	var groupChangedObserver: NSObjectProtocol? {
		willSet {
			guard let groupChangedObserver = groupChangedObserver else { return }
			NotificationCenter.default.removeObserver(groupChangedObserver)
		}
	}

	func publishChanges(for sharedEventIDs: [NSManagedObjectID]) {
		// Fake a context did save notification to trigger an NSFetchedResultsController update
		DispatchQueue.global(qos: .utility).async { [dataService] in
			dataService.perform { context in
				let sharedEvents = sharedEventIDs.compactMap { context.object(with: $0) as? SharedEvent }
				guard sharedEvents.count > 0 else { return }
				sharedEvents.forEach { sharedEvent in
					sharedEvent.willChangeValue(for: \.groupNameByTime)
					sharedEvent.didChangeValue(for: \.groupNameByTime)
				}
				let contextDidSave = Notification(name: .NSManagedObjectContextDidSave, object: context, userInfo: [
					NSDeletedObjectsKey : [NSManagedObject](),
					NSInsertedObjectsKey : [NSManagedObject](),
					NSUpdatedObjectsKey : sharedEvents
				])
				// This must always be posted in the default NotificationCenter
				NotificationCenter.default.post(contextDidSave)
			}
		}
	}

	func setupGroupChangedObserver() {
		groupChangedObserver = NotificationCenter.default.addObserver(forName: .sharedEventGroupChanged, object: nil, queue: .main) { [weak self] notification in
			guard let self = self else { return }
			// TODO: If this view is not visible, defer all updates by writing into a set
			// Then when the view is displayed again create a single update for all objects updated
			#if os(iOS) || os(tvOS)
			guard let view = self.viewIfLoaded, view.window != nil else {
				print("Skipping update because window doesn't exist")
				return
			}
			#endif
			guard let sharedEvent = notification.object as? SharedEvent else { return }
			print("\(sharedEvent.createdByDevice!) (\(sharedEvent.createdLocallyAt!)) has changed to \(sharedEvent.groupNameByTime)")
			self.publishChanges(for: [sharedEvent.objectID])
		}
	}
}
