//
//  CloudSyncingTableViewController.swift
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

internal class CloudSyncingTableViewController<TableViewType>: ResolveTableViewController, CoreResettable where TableViewType.CellType.ResultType: SyncableEntity, TableViewType: CoreTable {
	
	@Service var cloudService: CloudKitService
	@Service var dataService: CoreDataService
	@Service var loggingService: CoreLoggingService
	@Service var userInputService: UserInputService

	// MARK: - Interface Builder outlets
	
	#if os(macOS)
	@IBOutlet private var progressBar: NSProgressIndicator!
	#else
	@IBOutlet private var progressBar: UIProgressView!
	#endif

	#if os(iOS)
	
	@IBInspectable var supportsSearching: Bool = false

	// MARK: - CoreTableViewController overrides

	override func awakeFromNib() {
		super.awakeFromNib()
		// NavigationItems are most effective when they are configured before viewDidLoad, particularly within a UISplitViewController
		guard #available(iOS 11.0, *) else { return }
		if traitCollection.userInterfaceIdiom == .pad {
			navigationItem.largeTitleDisplayMode = .never
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Need this here because this is a generic class that cannot have its own outlets for Interface Builder
		if let refreshControl = self.refreshControl {
			refreshControl.addTarget(self, action: #selector(refreshControlRefreshing(_:)), for: .valueChanged)
		}
		// TODO: Need to disable pull to refresh when the search controller is active
		guard prepareSearchController() else { return }
		// TODO: iOS < 13.0 seems to have a problem with this in a SplitViewController + NavigationController
		// https://forums.developer.apple.com/thread/88774
		if #available(iOS 13.0, *) {
			setupSearchController(useNavigationItem: true)
		} else { // TODO: Identify the situation where we're not in a splitViewController and pass true anyway
			setupSearchController(useNavigationItem: false)
		}
	}

	@available(iOS 11.0, *)
	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let tableView = tableView as? TableViewType else { return nil }
		return swipeActions(forRowAt: indexPath, in: tableView)
	}
	
	@available(macCatalyst, deprecated: 13.0)
	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		guard let tableView = tableView as? TableViewType else { return nil }
		return editActions(forRowAt: indexPath, in: tableView)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		tableView.beginUpdates()
		coordinator.animate(alongsideTransition: { context in
			self.tableView.endUpdates()
		})
	}

	@IBAction func refreshControlRefreshing(_ sender: Any?) {
		// TODO: Need to disable pull to refresh when the search controller is active
        let refreshControl = sender as? UIRefreshControl
        do {
			try syncCloud(syncOptions: .fetchAll) { [weak self] in
				defer {
					refreshControl?.endRefreshing()
				}
                // TODO: Would be nice to re-animate the new groupings
				guard let source = self?.source else { return }
				source.setNeedsReload()
				source.reloadIfNeeded()
            }
            refreshControl?.beginRefreshing()
        } catch {
			userInputService.presentAlert(error.localizedDescription, withTitle: "Error initiating sync to cloud", from: refreshControl ?? self, forDuration: 2.0)
        }
	}

	var searchController: UISearchController?

	#endif

	// MARK: - CoreResettable methods

	func reset() {
		source.setNeedsReload()
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
			currentProgressObservation = currentProgress.observe(\.fractionCompleted, options: [.initial, .new]) { [weak progressBar] progress, observedChange in
				DispatchQueue.runInMain {
					guard let progressBar = progressBar, let progressValue = observedChange.newValue else { return }
					#if os(macOS)
					progressBar.doubleValue = progressValue
					#else
					progressBar.progress = Float(progressValue)
					#endif
				}
			}
		}
	}
	
	private var currentProgressObservation: NSKeyValueObservation? {
		didSet { progressBar?.isHidden = currentProgressObservation == nil }
	}

	internal class var defaultPredicate: NSPredicate {
		return TableViewType.CellType.ResultType.predicateForNotSyncedAs(.synchronizingRelationships)
	}

	internal func deletableObjectID(for result: TableViewType.CellType.ResultType) -> NSManagedObjectID? {
		return try? dataService.performAndReturn { context in
			guard let syncableEntity = try context.existingObject(with: result.objectID) as? SyncableEntity, syncableEntity.cloudSyncStatus == .normal else {
				return nil
			}
			return syncableEntity.objectID
		}
	}
	
	internal func deleteSyncableEntity(with objectID: NSManagedObjectID, completionHandler: ((Result<Bool, Error>) -> Void)? = nil) {
		let context = source.fetchedResultsController.managedObjectContext
		context.perform {
			do {
				guard let syncableEntity = try context.existingObject(with: objectID) as? SyncableEntity else {
					throw NSError(domain: "Resolve", code: -1, userInfo: nil)
				}
				if syncableEntity.notLinked {
					context.delete(syncableEntity)
					try context.save()
					completionHandler?(.success(true))
				} else {
					syncableEntity.cloudSyncStatus = .markedForDeletion
					if let reference = syncableEntity.iCloudReference(for: .public) {
						reference.synchronized = false
					}
					try context.save()
					try? self.syncCloud(delay: .seconds(2))
					completionHandler?(.success(false))
				}
			} catch {
				completionHandler?(.failure(error))
			}
		}
	}

	internal var source: CoreTableViewDataSource<TableViewType.CellType.ResultType, TableViewType>!

	internal var sourceTableView: TableViewType {
		get { return tableView as! TableViewType }
	}

	internal func syncCloud(syncOptions: CloudKitServiceSyncOptions = .default, delay: DispatchTimeInterval = .seconds(0), _ completion: (() -> Void)? = nil) throws {
		guard currentProgress == nil else {
			DispatchQueue.runInMain() {
				completion?()
			}
			return
		}
		// Trigger a cloud sync with a debounds of 0.5 seconds
		cloudSyncWorkItem = DispatchWorkItem { [weak self, cloudService] in
			guard let self = self else { return }
			self.currentProgress = cloudService.synchronize(syncOptions: syncOptions, qualityOfService: .userInitiated) { [weak self] result in
				DispatchQueue.runInMain() {
					self?.currentProgress = nil
					completion?()
				}
			}
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: cloudSyncWorkItem!)
	}

	internal func updatePredicate(_ predicate: NSPredicate) throws {
		let controller = source.fetchedResultsController
		controller.fetchRequest.predicate = predicate
		// TODO: See if we can somehow animate these changes
		try controller.performFetch()
		tableView.reloadData()
	}
}
