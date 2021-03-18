//
//  ResolveTableView.swift
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

import CoreResolve

#if os(iOS) || os(tvOS)

/// Custom UITableView subclass that better supports dynamically sized cells (NOTE: a better alternative is to use CoreTableViewDataSource)
open class ResolveTableView: UITableView, CoreTableViewPreparesViewsForSizing {

	override open func dequeueReusableCell(withIdentifier identifier: String) -> UITableViewCell? {
		guard let retVal = super.dequeueReusableCell(withIdentifier: identifier) else { return nil }
		if cellRequiresPreparation {
			prepareViewForSizing(retVal)
		}
		return retVal
	}

	override open func dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
		let retVal = super.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
		if cellRequiresPreparation {
			prepareViewForSizing(retVal)
		}
		return retVal
	}

	override open func dequeueReusableHeaderFooterView(withIdentifier identifier: String) -> UITableViewHeaderFooterView? {
		guard let retVal = super.dequeueReusableHeaderFooterView(withIdentifier: identifier) else { return nil }
		if sectionFooterRequiresPreparation || sectionHeaderRequiresPreparation {
			prepareViewForSizing(retVal)
		}
		return retVal
	}
}

public extension UITableView {

	func applyCollectionChanges<C>(_ changes: CollectionChanges<C>, to section: Int) where C: Collection, C.Index == Int {

		deleteRows(at: changes.deletes.map { IndexPath(row: $0, section: section) }, with: .automatic)
		insertRows(at: changes.inserts.map { IndexPath(row: $0, section: section) }, with: .automatic)
		for move in changes.moves {
			moveRow(at: IndexPath(row: move.from, section: section), to: IndexPath(row: move.to, section: section))
		}
	}
}

#elseif os(macOS)

open class ResolveTableView: NSTableView {

}

public extension NSTableView {

	func applyCollectionChanges<C>(_ changes: CollectionChanges<C>) where C: Collection, C.Index == Int {

		removeRows(at: IndexSet(changes.deletes), withAnimation: .slideUp)
		insertRows(at: IndexSet(changes.inserts), withAnimation: .slideUp)
		for move in changes.moves {
			moveRow(at: move.from, to: move.to)
		}
	}
	/*
	/// The preferred mechanism is to use `CoreCellDequeuing` with a custom subclass of NSTableView, but in interim cases this suffices
	func dequeueReusableCell(withReuseIdentifier reuseIdentifier: String, for indexPath: IndexPath) -> NSView {
		let identifier = NSUserInterfaceItemIdentifier(rawValue: reuseIdentifier)
		return makeView(withIdentifier: identifier, owner: self)!
	}
	*/
}

public extension CoreCellDequeuing where Self: TableView, CellIdentifier.RawValue == String {

	func dequeueReusableCell<T>(withIdentifier identifier: CellIdentifier, for indexPath: IndexPath, owner: Any? = nil) -> T where T: TableViewCell {
		let itemIdentifier = NSUserInterfaceItemIdentifier(rawValue: identifier.rawValue)
		return self.makeView(withIdentifier: itemIdentifier, owner: owner) as! T
	}
}

#endif
