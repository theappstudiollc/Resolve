//
//  UserTableViewDataSource.swift
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

extension UserTableView: CoreTable {
	typealias CellType = UserTableViewCell

	func cellIdentifierFor(result: User) -> String {
		return CellIdentifier.user.rawValue
	}
}

class UserTableViewCell: UITableViewCell, CoreTableCell {

	public typealias ResultType = User

	public func applyResult(_ result: User) {
		textLabel?.text = "\(result.userFirstName ?? "<no first>") \(result.userLastName ?? "<no last>")"
		let currentAppUser = result.managedObjectContext?.userInfo["CurrentAppUser"] as? User
		if currentAppUser == result {
			detailTextLabel?.text = "\(result.userAlias ?? "<no alias>") (you)"
		} else if currentAppUser?.friends?.contains(result) ?? false {
			detailTextLabel?.text = "\(result.userAlias ?? "<no alias>") (friend)"
		} else {
			detailTextLabel?.text = "\(result.userAlias ?? "<no alias>") (stranger)"
		}
	}
}

final class UserTableViewDataSource: CoreTableDataSource<UserTableView> {

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard section == 0 else { return nil }
		return "Your Resolve friends"
	}

	override class var tracksResults: Bool {
		return true
	}
}
