//
//  InterfaceController.swift
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

import ClockKit
import CloudKit
import Intents
import ResolveKit
import WatchKit

final class CoreDataInterfaceController: ResolveViewController {
	
	@Service var cloudService: CloudKitService
	@Service var complicationService: ComplicationService
	@Service var dataService: DataService
	@Service var inputService: UserInputService
	@Service var userService: AppUserService
	@Service var userActivityService: UserActivityService

	// MARK: - Interface Builder items

	@IBAction func tapButtonTapped() {
		
		dataService.performAndWait { context in
			// Get the current user
			guard let appUser = try? userService.currentAppUser(using: context) else {
				// TODO: Display an error of some kind
				return
			}
			self.tapsButton.setEnabled(false)
			let transactionContext = context.beginTransaction()
			do {
				let sharedEvent = try context.create(SharedEvent.self)
				sharedEvent.createdByDevice = WKInterfaceDevice.current().name
				sharedEvent.createdLocallyAt = Date().withoutMilliseconds
				sharedEvent.uniqueIdentifier = UUID().uuidString
				sharedEvent.user = appUser
				sharedEvent.createICloudReference(for: .public, with: nil)
				try context.commitTransaction(transactionContext: transactionContext)
				try self.syncCloud(delay: .milliseconds(500)) { [complicationService, dataService] in
					self.tapCount = (try? dataService.getTapCount()) ?? 0
					complicationService.updateTapCount(self.tapCount, forceReload: false)
					self.tapsButton.setEnabled(true)
				}
				guard #available(watchOS 5.0, *) else { return }
				let intent = CreateSharedEventIntent()
				intent.suggestedInvocationPhrase = "Create a shared event"
				INInteraction(intent: intent, response: nil).donate { [loggingService] error in
					switch error {
					case .some(let error):
						loggingService.log(.error, "Failure to donate intent: %{public}@", error.localizedDescription)
					default:
						loggingService.debug("Intent successfully donated")
					}
				}
			} catch {
				context.cancelTransaction(transactionContext: transactionContext)
				loggingService.log(.error, "Failure to add shared event: %{public}@", error.localizedDescription)
				self.tapsButton.setEnabled(true)
				inputService.presentError(error, withTitle: "Error", from: self)
			}
		}
	}

	@IBOutlet var table: SharedEventTableView!
	@IBOutlet var tapsButton: WKInterfaceButton!
	@IBOutlet var tapsLabel: WKInterfaceLabel!

	// MARK: - CoreViewController overrides

	override init() {
		super.init()
		source = SharedEventTableViewDataSource(for: table) { [dataService] in
			return dataService.performAndReturn { context -> NSFetchedResultsController<SharedEvent>? in
				let request: NSFetchRequest<SharedEvent> = SharedEvent.fetchRequest()
				request.predicate = Self.defaultPredicate
//				request.relationshipKeyPathsForPrefetching = [#keyPath(SharedEvent.syncReferences)]
				request.fetchLimit = 10
				// Always guarantee a stable sort order (include the unique identifier if the createdLocallyAt dates match)
				request.sortDescriptors = [NSSortDescriptor(key: #keyPath(SharedEvent.createdLocallyAt), ascending: false), NSSortDescriptor(key: #keyPath(SharedEvent.uniqueIdentifier), ascending: true)]
				return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			}!
		}
	}

	override func didAppear() {
		super.didAppear()
		userActivity = userActivityService.userActivity(for: .coreData)
	}

	override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
		guard let rowController = table.rowController(at: rowIndex) as? SharedEventTableViewCell else {
			return nil
		}
		return rowController.sharedEvent
	}

	override func willActivate() {
		super.willActivate()
		tapCount = (try? dataService.getTapCount()) ?? 0
		source.reloadIfNeeded()
	}

	override func willDisappear() {
		super.willDisappear()
		userActivity = nil
	}

	// MARK: - Private properties and methods
	
	private var cloudSyncWorkItem: DispatchWorkItem? {
		willSet { cloudSyncWorkItem?.cancel() }
	}
		
	private var currentProgress: Progress? {
		didSet {
			guard let currentProgress = currentProgress else {
				currentProgressObservation = nil
				return
			}
			currentProgressObservation = currentProgress.observe(\.fractionCompleted, options: [.initial, .new]) { [loggingService] progress, observedChange in
				guard let progressValue = observedChange.newValue else { return }
				loggingService.debug("Sync progress: %3.2f", progressValue)
			}
		}
	}

	internal class var defaultPredicate: NSPredicate {
		return SharedEvent.predicateForNotSyncedAs(.synchronizingRelationships)
	}

	var source: SharedEventTableViewDataSource!
	
	private var currentProgressObservation: NSKeyValueObservation?

	internal func syncCloud(delay: DispatchTimeInterval = .seconds(0), _ completion: (() -> Void)? = nil) throws {
		guard currentProgress == nil else {
			DispatchQueue.runInMain() {
				completion?()
			}
			return
		}
		// Trigger a cloud sync with a debounds of 0.5 seconds
		cloudSyncWorkItem = DispatchWorkItem { [weak self, cloudService] in
			guard let self = self else { return }
			self.currentProgress = cloudService.synchronize(syncOptions: .default, qualityOfService: .userInitiated) { [weak self] result in
				DispatchQueue.runInMain() {
					self?.currentProgress = nil
					completion?()
				}
			}
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: cloudSyncWorkItem!)
	}

	var tapCount: Int = 0 {
		didSet { updateTapsLabel() }
	}

	func updateTapsLabel() {
		tapsLabel.setText("\(tapCount) SharedEvents")
	}

	var userActivity: NSUserActivity? {
		willSet {
			guard let userActivity = userActivity else { return }
			userActivity.resignCurrent()
			invalidateUserActivity()
		}
		didSet {
			guard let userActivity = userActivity else { return }
			userActivity.becomeCurrent()
			guard #available(watchOS 5.0, *) else {
				updateUserActivity(userActivity.activityType, userInfo: userActivity.userInfo, webpageURL: nil)
				return
			}
			update(userActivity)
		}
	}
}
