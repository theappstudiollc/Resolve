//
//  CloudKit-Extensions.swift
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

extension CKRecord {
    
    convenience init?(with iCloudSystemFieldsData: Data) {
        guard #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) else {
            let decoder = NSKeyedUnarchiver(forReadingWith: iCloudSystemFieldsData)
            decoder.requiresSecureCoding = true
            self.init(coder: decoder)
            return
        }
        guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: iCloudSystemFieldsData) else {
            return nil
        }
        self.init(coder: decoder)
    }
	
	var creatorIsCurrentUser: Bool {
		get {
			let userName: String
			if #available(iOS 10.0, macOS 10.12.0, tvOS 10.0, *) {
				userName = CKCurrentUserDefaultName
			} else {
				userName = CKOwnerDefaultName
			}
			guard let creatorRecord = creatorUserRecordID, creatorRecord.recordName == userName else {
				return false
			}
			return true
		}
	}
    
    func fieldEquals<T>(_ field: String, to record: CKRecord, as type: T.Type) -> Bool where T: CKRecordValueProtocol & Equatable {
        let recordValue = record[field] as T?
        let localValue = self[field] as T?
        return localValue == recordValue
    }
    
    var encodedSystemFields: Data {
		guard #available(iOS 10.0, macOS 10.12.0, *) else {
            let retVal = NSMutableData()
            let encoder = NSKeyedArchiver(forWritingWith: retVal)
            encoder.requiresSecureCoding = true
            encodeSystemFields(with: encoder)
            encoder.finishEncoding()
            return retVal as Data
		}
		guard #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) else {
            let encoder = NSKeyedArchiver()
            encoder.requiresSecureCoding = true
            encodeSystemFields(with: encoder)
            encoder.finishEncoding()
            return encoder.encodedData
		}
		let encoder = NSKeyedArchiver(requiringSecureCoding: true)
		encodeSystemFields(with: encoder)
		encoder.finishEncoding()
		return encoder.encodedData
    }
	
	static func serverRecord(_ serverRecord: CKRecord, isNewerThan clientRecord: CKRecord) -> Bool {
		precondition(serverRecord.modificationDate != nil)
		precondition(serverRecord.recordID.indexableRepresentation == clientRecord.recordID.indexableRepresentation)
		return clientRecord.modificationDate == nil || serverRecord.modificationDate! > clientRecord.modificationDate! || serverRecord.recordChangeTag != clientRecord.recordChangeTag
	}
}

public extension CKRecord.ID {
    
    var indexableRepresentation: String {
		if isDefaultZone {
			return "\(recordName):default"
		}
		// Not currently expected in the Resolve app
		return "\(recordName):\(zoneID.zoneName):\(zoneID.ownerName)"
    }

	private var isDefaultZone: Bool {
		let defaultZoneID = CKRecordZone.default().zoneID
		// When CKContainer.fetchUserRecordID() is called, the `ownerName` usually normalizes
		return zoneID == defaultZoneID || zoneID.zoneName == defaultZoneID.zoneName && ["__defaultOwner__", "_defaultOwner"].contains(zoneID.ownerName)
	}
}

extension Date {
    
    public var withoutMilliseconds: Date {
        let interval = floor(self.timeIntervalSinceReferenceDate)
        return Date(timeIntervalSinceReferenceDate: interval)
    }
}
