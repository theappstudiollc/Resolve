//
//  ConversationTableViewController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2020 The App Studio LLC.
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

final class ConversationTableViewCell: TableViewCell {

	fileprivate var peerName: String? {
		didSet { updatePeerName() }
	}

	fileprivate func updatePeerName() {
		#if os(macOS)
		textField?.labelText = peerName ?? ""
		#else
		textLabel?.labelText = peerName ?? ""
		#endif
	}
}

final class ConversationTableView: ResolveTableView { }

extension ConversationTableView: CoreCellDequeuing {

	public enum CellIdentifier: String {
		case peer
	}
}

final class ConversationTableViewController: TypedTableViewController<String, ConversationTableView> {

	override func tableView(_ tableView: ConversationTableView, cellFor result: String, at indexPath: IndexPath) -> TableViewCell {
		let cell: ConversationTableViewCell = tableView.dequeueReusableCell(withIdentifier: .peer, for: indexPath)
		cell.peerName = result
		return cell
	}

	#if !os(macOS)

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard section == 0 else { return nil }
		return "Connected Peers"
	}

	#endif
}
