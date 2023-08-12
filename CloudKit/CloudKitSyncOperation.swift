//
//  CloudKitSyncOperation.swift
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
import CoreData
import CoreResolve

internal class CloudKitSyncOperation: CloudKitDataOperation, CloudKitGroupMember {
	
	static let maxModifyCount: Int = 400
	
	// MARK: - Properties and initializers
	
	public let iCloudDatabaseType: CloudKitDatabaseType
	
	public var operationGroup: NSObject? {
		didSet {
			if #available(iOS 11.0, macOS 10.13.0, tvOS 11.0, watchOS 4.0, *) {
				assert(operationGroup == nil || operationGroup is CKOperationGroup)
			} else {
				assert(operationGroup == nil, "`operationGroup` must be of type `CKOperationGroup`")
			}
		}
	}
	
	required public init(with workflowContext: WorkflowContext, dataService: CoreDataService, loggingService: CoreLoggingService, in databaseType: CloudKitDatabaseType = .public) {
		self.iCloudDatabaseType = databaseType
		super.init(with: workflowContext, dataService: dataService, loggingService: loggingService)
		switch databaseType {
		case .private:
			name = "\(type(of: self)).Private"
		case .public:
			name = "\(type(of: self)).Public"
		}
	}
	
	// MARK: - Public properties and methods
	
	public func addQueries(from queries: [CKQuery]) {
		syncQueue.sync(flags: .barrier) {
			self.queries.append(contentsOf: queries)
		}
	}
	
	public func addRecordIDsToObjectIDs(from recordIDsToObjectIDs: [CKRecord.ID : NSManagedObjectID]) {
		syncQueue.sync(flags: .barrier) {
			_recordIDsToObjectIDs.merge(recordIDsToObjectIDs) { $1 }
		}
	}
	
	public func addRecordsToDelete(from recordIDsToObjectIDs: [CKRecord.ID : NSManagedObjectID]) {
		addRecordIDsToObjectIDs(from: recordIDsToObjectIDs)
		syncQueue.sync(flags: .barrier) {
			recordsToDelete.formUnion(recordIDsToObjectIDs.keys)
		}
	}
	
	public func addRecordsToFetch(from recordsToFetch: Set<CKRecord.ID>) {
		syncQueue.sync(flags: .barrier) {
			self.recordsToFetch.formUnion(recordsToFetch)
		}
	}

	public func addRecordsToSave(from recordIDsToRecords: [CKRecord.ID : CKRecord]) {
		syncQueue.sync(flags: .barrier) {
			recordsToSave.merge(recordIDsToRecords) { $1 }
		}
	}
	
	// MARK: - CloudKitDataOperation overrides -
	
	open override func cancel() {
		currentOperation?.cancel()
		super.cancel()
	}
	
	open override func main() {
		continuePipeline(result: .success(()))
	}
	
	open override func finish() {
		recordIDsToObjectIDs = _recordIDsToObjectIDs
		super.finish()
	}
	
	// MARK: - Private properties and methods -
	
	internal var _recordIDsToObjectIDs = [CKRecord.ID : NSManagedObjectID]()
	public internal(set) var recordIDsToObjectIDs: [CKRecord.ID : NSManagedObjectID]?
	internal var recordsToDelete = Set<CKRecord.ID>()
	internal var recordsToFetch = Set<CKRecord.ID>()
	internal var recordsToSave = [CKRecord.ID : CKRecord]()
	internal var currentModifyCount = CloudKitSyncOperation.maxModifyCount
	internal var currentOperation: CKOperation?
	internal var queries = [CKQuery]()

	private var syncQueue = DispatchQueue(label: "\(type(of: CloudKitSyncOperation.self)).syncQueue", attributes: .concurrent)
		
	private func continuePipeline(result: Result<Void, Error>, cursor: CKQueryOperation.Cursor? = nil) {
		if case Result.failure(let error) = result {
			finish(withError: error)
		} else if let cursor = cursor {
			startQueryOperation(CKQueryOperation(cursor: cursor))
		} else if let queryOperation = nextQueryOperation() {
			startQueryOperation(queryOperation)
		} else if recordsToFetch.count > 0 {
			startFetchOperation(recordsToFetch: Array(recordsToFetch.prefix(currentModifyCount)))
		} else if recordsToSave.count + recordsToDelete.count > 0 {
			prepareAndRunModifyOperation()
		} else {
			finish()
		}
	}

	private func prepareAndRunModifyOperation() {
		let totalToModify = Float(recordsToSave.count + recordsToDelete.count)
		let saveCount = Int(Float(currentModifyCount * recordsToSave.count) / totalToModify)
		let recordsToSave = self.recordsToSave.prefix(max(1, saveCount))
		let deleteCount = Int(Float(currentModifyCount * recordsToDelete.count) / totalToModify)
		let recordsToDelete = self.recordsToDelete.prefix(max(1, deleteCount))
		startModifyOperation(recordsToSave: recordsToSave.map { $0.value }, recordsToDelete: Array(recordsToDelete))
	}
	
	private func processResults(_ results: [CKRecord]?, deletedRecordIDs: [CKRecord.ID]?, fromModify modifyOperation: Bool, withError error: Error?, completion: @escaping (_ result: Result<Void, Error>) -> Void) {
		if let error = error as? CKError, error.code == .operationCancelled {
			completion(.failure(error))
			return
		}
		dataService.performAndWait { context in
			
			let savedRecordIDsToObjectIDs = _recordIDsToObjectIDs
			let savedRecordsToDelete = recordsToDelete
			let savedRecordsToFetch = recordsToFetch
			let savedRecordsToSave = recordsToSave
			
			let transactionContext = context.beginTransaction()

			do {
				deletedRecordIDs?.forEach {
					deleteRecord(with: $0, using: context)
					removeAllReferences(for: $0)
				}
				if let results = results {
					try sortResults(results).forEach {
						// TODO: Merges from here aren't with errors or conflicts -- the method should know this
						if try mergeServerRecord($0, from: modifyOperation, using: context) {
							recordsToSave[$0.recordID] = $0
						} else {
							recordsToSave.robustRemove(recordID: $0.recordID)
						}
						recordsToFetch.remove($0.recordID)
					}
				}
				
				switch error {
				case .some(let cloudKitError as CKError):
					switch cloudKitError.code {
					case .limitExceeded:
						loggingService.log(.error, "Operation size limit exceeded using %d records -- reducing in half and trying again", currentModifyCount)
						currentModifyCount /= 2
					case .unknownItem:
						// This happens on the first query when the database is reset (just allow the modify operation to proceed)
						guard let unknownRecord = cloudKitError.clientRecord ?? cloudKitError.ancestorRecord else {
							throw cloudKitError
						}
						try handleUnknownItem(cloudKitError, for: unknownRecord.recordID, from: modifyOperation, in: context)
						removeAllReferences(for: unknownRecord.recordID)
					case .serverRecordChanged:
						guard let serverRecord = cloudKitError.errorUserInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord else {
							throw cloudKitError
						}
						// TODO: We could pass additional info from the error to this merge
						if try mergeServerRecord(serverRecord, from: modifyOperation, using: context) {
							recordsToSave[serverRecord.recordID] = serverRecord
						} else {
							recordsToSave.robustRemove(recordID: serverRecord.recordID)
						}
					case .partialFailure:
						guard let partialErrors = cloudKitError.errorUserInfo[CKPartialErrorsByItemIDKey] as? [CKRecord.ID : Error] else {
							throw cloudKitError
						}
						for partialError in partialErrors {
							switch partialError.value {
							case let cloudKitError as CKError:
								switch cloudKitError.code {
								case .unknownItem:
									// TODO: When partial, consider this not to be a fatal error
									try? handleUnknownItem(cloudKitError, for: partialError.key, from: modifyOperation, in: context)
									removeAllReferences(for: partialError.key)
								case .serverRecordChanged:
									guard let serverRecord = cloudKitError.errorUserInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord else {
										throw cloudKitError
									}
									// TODO: We could pass additional info from the error to this merge
									if try mergeServerRecord(serverRecord, from: modifyOperation, using: context) {
										recordsToSave[serverRecord.recordID] = serverRecord
									} else {
										recordsToSave.robustRemove(recordID: serverRecord.recordID)
									}
									recordsToFetch.remove(serverRecord.recordID)
								default:
									throw cloudKitError
								}
							default:
								throw cloudKitError
							}
						}
					default:
						throw cloudKitError
					}
				case .some(let error):
					throw error
				default:
					// Any success means we can restore the modify operation count
					currentModifyCount = Self.maxModifyCount
				}
				try context.commitTransaction(transactionContext: transactionContext)
				completion(.success(()))
			} catch {
				loggingService.log(.error, " !! CloudKit Error: %{public}@", error.localizedDescription)
				syncQueue.sync(flags: .barrier) {
					_recordIDsToObjectIDs = savedRecordIDsToObjectIDs
					recordsToDelete = savedRecordsToDelete
					recordsToFetch = savedRecordsToFetch
					recordsToSave = savedRecordsToSave
				}
				workflowContext.addError(error)
				context.cancelTransaction(transactionContext: transactionContext)
				completion(.failure(error))
			}
		}
	}
	
	private func removeAllReferences(for recordIdentifier: CKRecord.ID) {
		syncQueue.sync(flags: .barrier) {
			_recordIDsToObjectIDs.robustRemove(recordID: recordIdentifier)
			recordsToFetch.remove(recordIdentifier)
			recordsToDelete.remove(recordIdentifier)
			recordsToSave.robustRemove(recordID: recordIdentifier)
		}
	}

	private func startFetchOperation(recordsToFetch: [CKRecord.ID]) {
		precondition(recordsToFetch.count > 0, "Must have some work to do")
		guard !isCancelled else {
			finish()
			return
		}
		let fetchRecords = fetchRecordsOperation(for: recordsToFetch)
		workflowContext.logger.debug("%{public}@ starting fetch for %ld records", nameForLogging, recordsToFetch.count)
		databaseForOperation(fetchRecords).add(fetchRecords)
		currentOperation = fetchRecords
	}

	private func startModifyOperation(recordsToSave: [CKRecord], recordsToDelete: [CKRecord.ID]) {
		precondition(recordsToSave.count + recordsToDelete.count > 0, "Must have some work to do")
		guard !isCancelled else {
			finish()
			return
		}
		let modifyRecords = modifyOperation(with: recordsToSave, recordIDsToDelete: recordsToDelete)
		if let firstRecord = recordsToSave.first {
			loggingService.debug("%{public}@ starting modify of %{public}@ with %ld changes and %ld deletions", nameForLogging, firstRecord.recordType, recordsToSave.count, recordsToDelete.count)
		} else {
			loggingService.debug("%{public}@ starting modify with %ld changes and %ld deletions", nameForLogging, recordsToSave.count, recordsToDelete.count)
		}
		databaseForOperation(modifyRecords).add(modifyRecords)
		currentOperation = modifyRecords
	}

	private func startQueryOperation(_ queryOperation: CKQueryOperation) {
		guard !isCancelled else {
			finish()
			return
		}
		var pendingResults = [CKRecord]()
		pendingResults.reserveCapacity(100)
		queryOperation.recordFetchedBlock = { pendingResults.append($0) }
		queryOperation.setOperationQuality(from: self)
		queryOperation.queryCompletionBlock = { [weak self] cursor, error in
			guard let self = self else { return }
			self.processResults(pendingResults, deletedRecordIDs: nil, fromModify: false, withError: error) { result in
				self.continuePipeline(result: result, cursor: cursor)
			}
		}
		if let query = queryOperation.query {
			loggingService.debug("%{public}@ starting query with %{public}@", nameForLogging, query)
		} else if let _ = queryOperation.cursor {
			loggingService.debug("%{public}@ starting query with cursor", nameForLogging)
		} else {
			loggingService.debug("%{public}@ starting query", nameForLogging)
		}
		databaseForOperation(queryOperation).add(queryOperation)
		currentOperation = queryOperation
	}

	// MARK: - Subclassing hooks -
	
	open func databaseForOperation(_ operation: CKOperation) -> CKDatabase {
		switch iCloudDatabaseType {
		case .private:
			return workflowContext.cloudContainer.privateCloudDatabase
		case .public:
			return workflowContext.cloudContainer.publicCloudDatabase
		}
	}
	
	open func deleteRecord(with recordID: CKRecord.ID, using context: NSManagedObjectContext) {
		fatalError("\(type(of: self)) must implement deleteRecord(with:using:) and not call super")
	}

	open func fetchRecordsOperation(for recordsToFetch: [CKRecord.ID]) -> CKFetchRecordsOperation {
		let retVal = CKFetchRecordsOperation(recordIDs: recordsToFetch)
		retVal.setOperationQuality(from: self)
		retVal.fetchRecordsCompletionBlock = { [weak self] recordsByRecordID, error in
			guard let self = self else { return }
			let results: [CKRecord]? = recordsByRecordID == nil ? nil : Array(recordsByRecordID!.values)
			self.processResults(results, deletedRecordIDs: nil, fromModify: false, withError: error) { result in
				self.continuePipeline(result: result)
			}
		}
		return retVal
	}

	open func handleUnknownItem(_ error: Error, for recordID: CKRecord.ID, from modifyOperation: Bool, in context: NSManagedObjectContext) throws {
		fatalError("\(type(of: self)) must implement handleUnknownItem(_:for:from:in:) and not call super")
	}

	open func mergeServerRecord(_ serverRecord: CKRecord, from modifyOperation: Bool, using context: NSManagedObjectContext) throws -> Bool {
		fatalError("\(type(of: self)) must implement mergeServerRecord(_:from:using:) and not call super")
	}
	
	open func modifyOperation(with recordsToSave: [CKRecord], recordIDsToDelete: [CKRecord.ID]) -> CKModifyRecordsOperation {
		let retVal = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
		retVal.setOperationQuality(from: self)
		retVal.savePolicy = .ifServerRecordUnchanged
		retVal.modifyRecordsCompletionBlock = { [weak self] savedRecords, deletedRecordIDs, error in
			guard let self = self else { return }
			self.processResults(savedRecords, deletedRecordIDs: deletedRecordIDs, fromModify: true, withError: error) { result in
				self.continuePipeline(result: result)
			}
		}
		return retVal
	}

	open func nextQueryOperation() -> CKQueryOperation? {
		guard let query = queries.first else { return nil }
		queries.removeFirst()
		return CKQueryOperation(query: query)
	}
	
	open func sortResults(_ results: [CKRecord]) -> [CKRecord] {
		return results
	}
}

// The hash function is known the fail when there are slight variations in the zoneID :(
// e.g. zoneID=_defaultZone:__defaultOwner__ vs zoneID=_defaultZone:_defaultOwner
internal extension Dictionary where Key == CKRecord.ID {

	func robustLookup(recordID: Key) -> Value? {
		if let result = self[recordID] {
			return result
		}
		let indexable = recordID.indexableRepresentation
		if let pair = first(where: { key, value in
			return key.indexableRepresentation == indexable
		}), let result = self[pair.key] {
			return result // Unfortunate workaround
		}
		return nil
	}

	@discardableResult mutating func robustRemove(recordID: Key) -> Value? {
		if let result = removeValue(forKey: recordID) {
			return result
		}
		let indexable = recordID.indexableRepresentation
		if let pair = first(where: { key, value in
			return key.indexableRepresentation == indexable
		}), let removed = removeValue(forKey: pair.key) {
			return removed // Unfortunate workaround
		}
		return nil
	}
}
