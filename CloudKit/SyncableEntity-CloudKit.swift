//
//  SyncableEntity-CloudKit.swift
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

import CoreData
import CloudKit

public extension SyncableEntity {
	
	func filteredCloudReferences<T>(_ filter: (T) -> Bool) -> [T]? where T: SyncReference {
		return syncReferences?.compactMap({ $0 as? T}).filter(filter)
	}

	@discardableResult func createICloudReference(for databaseType: CloudKitDatabaseType, with record: CKRecord?) -> ICloudSyncReference {
		guard let managedObjectContext = managedObjectContext else {
			fatalError("createICloudReference can only be used when a managedObjectContext is assigned")
		}
		assert(iCloudReference(for: databaseType) == nil, "Cannot create new ICloudReferences when one already exists for the specified databaseType")
		
		let retVal = try! managedObjectContext.create(ICloudSyncReference.self)
		addToSyncReferences(retVal)
		retVal.iCloudDatabaseType = "\(databaseType)"
		retVal.cloudRecord = record ?? Self.createICloudRecord()
		return retVal // NOTE: The caller is responsible for saving (or rolling back)
	}
	
	func iCloudReference(for databaseType: CloudKitDatabaseType) -> ICloudSyncReference? {
		guard let iCloudReferences: [ICloudSyncReference] = filteredCloudReferences({ $0.iCloudDatabaseType == "\(databaseType)" }) else {
			return nil
		}
		guard iCloudReferences.filter({ !$0.objectID.isTemporaryID }).count <= 1 else {
			fatalError("Inconsistent state")
		}
		return iCloudReferences.first
	}
	
	var notLinked: Bool {
		return syncReferences == nil || syncReferences!.count == 0
	}
	
	class func predicateForNotSyncedAs(_ syncStatus: CloudSyncStatus) -> NSPredicate {
		return NSPredicate(format:"(%K&%i)=0", #keyPath(SyncableEntity.syncStatus), syncStatus.rawValue)
	}
	
	class func predicateForSyncedAs(_ syncStatus: CloudSyncStatus) -> NSPredicate {
		return NSPredicate(format:"(%K&%i)=%i", #keyPath(SyncableEntity.syncStatus), syncStatus.rawValue, syncStatus.rawValue)
	}
	
	func removeCloudReferenceType<T>(_ cloudReferenceType: T.Type, using context: NSManagedObjectContext) where T: SyncReference {
		guard let referencesToDelete: [T] = syncReferences?.compactMap({ $0 as? T}) else {
			return
		}
		referencesToDelete.forEach { context.delete($0) }
	}
	
	class func createICloudRecord(with recordID: CKRecord.ID? = nil) -> CKRecord {
		let recordType = Self.cloudRecordType
		if let recordID = recordID {
			return CKRecord(recordType: recordType, recordID: recordID)
		}
		return CKRecord(recordType: recordType)
	}
}

extension SyncableEntity: CloudSynchronizing {
    
    public var cloudSyncStatus: CloudSyncStatus {
        get { return CloudSyncStatus(rawValue: syncStatus) }
        set { syncStatus = newValue.rawValue }
    }
}

extension SyncableEntity: CloudKitEntity {

	@objc public class var cloudRecordType: String {
		return "\(self)" // Default is to match the name of the Objective C class
	}
	
	@objc public func apply(cloudKitRecord: CKRecord, for databaseType: CloudKitDatabaseType) throws {
		fatalError("\(type(of: self)) must implement apply(cloudKitRecord:for:)")
	}
	
	@objc public func update(cloudKitRecord: CKRecord, for databaseType: CloudKitDatabaseType) throws {
		fatalError("\(type(of: self)) must implement update(cloudKitRecord:for:)")
	}
	
	@objc public class func localRecord(_ localRecord: CKRecord, isEqualTo serverRecord: CKRecord, in databaseType: CloudKitDatabaseType) -> Bool {
		fatalError("\(type(of: self)) must implement localRecord(_:isEqualTo:in:)")
	}

	@objc public class func userFieldNames(for databaseType: CloudKitDatabaseType) -> [String] {
		fatalError("\(type(of: self)) must implement userFieldNames(for:)")
	}
}

extension CloudKitEntity where Self: SyncableEntity {
	
    func applyValue<T>(from record: CKRecord, for key: String, as type: T.Type) where T: CKRecordValueProtocol & Equatable {
        let recordValue = record[key] as T?
        let localValue = primitiveValue(forKey: key) as! T?
        if localValue != recordValue {
			willChangeValue(forKey: key)
            setPrimitiveValue(recordValue, forKey: key)
			didChangeValue(forKey: key)
        }
    }
    
    func applyValue<T>(to record: CKRecord, for key: String, as type: T.Type) where T: CKRecordValueProtocol & Equatable {
        let recordValue = record[key] as T?
        let localValue = primitiveValue(forKey: key) as! T?
        if localValue != recordValue {
            record[key] = localValue
        }
    }
	
	public static func cloudQuery(with predicate: NSPredicate = NSPredicate(value: true)) -> CKQuery {
		return CKQuery(recordType: cloudRecordType, predicate: predicate)
	}
	
	public static func instance(for recordID: CKRecord.ID, in databaseType: CloudKitDatabaseType, using context: NSManagedObjectContext, includesSubentities: Bool = false) throws -> Self? {
        
        let request: NSFetchRequest<ICloudSyncReference> = ICloudSyncReference.fetchRequest()
        request.predicate = NSPredicate(format: "%K=%@ AND %K=%@",
                                        #keyPath(ICloudSyncReference.iCloudRecordID), recordID.indexableRepresentation,
                                        #keyPath(ICloudSyncReference.iCloudDatabaseType), "\(databaseType)")
        request.fetchLimit = 1
		request.includesSubentities = includesSubentities
        request.relationshipKeyPathsForPrefetching = [#keyPath(ICloudSyncReference.syncableEntity)]
        
        for reference in try context.fetch(request) {
            guard let retVal = reference.syncableEntity as? Self else {
				throw CloudKitError.internalInconsistency("Unexpected syncable entity type linked to entity")
            }
			return retVal
        }
        return nil
    }
    
    public func isSynchronized(in databaseType: CloudKitDatabaseType) -> Bool {
        guard let iCloudReference = self.iCloudReference(for: databaseType) else { return false }
        return iCloudReference.synchronized
    }
    
    public func markSynchronized(_ synchronized: Bool, in databaseType: CloudKitDatabaseType, using context: NSManagedObjectContext) {
        if let iCloudReference = self.iCloudReference(for: databaseType) {
            iCloudReference.synchronized = synchronized
        }
    }
    
    public func getCloudKitRecord(for databaseType: CloudKitDatabaseType) -> CKRecord? {
        guard let iCloudReference = iCloudReference(for: databaseType), let recordData = iCloudReference.iCloudSystemFieldsData else {
//            assert(syncReferences?.count ?? 0 <= 0, "We currently expect \(ICloudSyncReference.self) only")
            return nil
        }
        guard let retVal = CKRecord(with: recordData) else {
            return nil
        }
		do {
			try update(cloudKitRecord: retVal, for: databaseType)
		} catch {
			return nil
		}
        return retVal
    }
    
	public func setCloudKitRecord(_ record: CKRecord?, for databaseType: CloudKitDatabaseType) throws {
        if let record = record {
            if let reference = iCloudReference(for: databaseType) {
                reference.cloudRecord = record
            } else {
                createICloudReference(for: databaseType, with: record)
            }
			try apply(cloudKitRecord: record, for: databaseType)
        } else { // TODO: How do we (should we) handle a nil input?
            if let reference = iCloudReference(for: databaseType), let context = managedObjectContext {
                context.delete(reference)
            }
        }
    }
}

extension PublicCloudKitEntity where Self: SyncableEntity {
	
	public var publicCloudRecord: CKRecord? {
		get { return getCloudKitRecord(for: .public) }
	}
}

extension PrivateCloudKitEntity where Self: SyncableEntity {
	
	public var privateCloudRecord: CKRecord? {
		get { return getCloudKitRecord(for: .private) }
	}
}
