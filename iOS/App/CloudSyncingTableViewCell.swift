//
//  CloudSyncingTableViewCell.swift
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

internal class CloudSyncingTableViewCell<ResultType>: UITableViewCell where ResultType: SyncableEntity {
	
	func applyResult(_ result: ResultType) {
        if result.cloudSyncStatus.contains(.markedForDeletion) {
            contentView.backgroundColor = UIColor.red.withAlphaComponent(0.2)
		} else if result.notLinked {
			contentView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        } else if let iCloudReference = result.iCloudReference(for: .public), !iCloudReference.synchronized {
            contentView.backgroundColor = UIColor.green.withAlphaComponent(0.2)
        } else {
            contentView.backgroundColor = nil
        }
	}
}
