//
//  TypedTableViewController.swift
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

import CoreResolve

open class TypedTableViewController<ResultType, TableViewType>: ResolveTableViewController where TableViewType: TableView, ResultType: Hashable {

	private var _results: [ResultType]!
	private var resultsApplied = false

	// MARK: - Public properties and methods

	public var results: [ResultType] {
		return _results
	}

	open func apply(_ results: [ResultType], to section: Int = 0, reloadRemaining: Bool = false) {
		// If the tableView's .window is nil, we should save off results for later
		guard isViewLoaded, let tableView = tableView, tableView.window != nil else {
			_results = results
			resultsApplied = false
			return
		}
		guard resultsApplied, let previous = _results else {
			_results = results
			tableView.reloadData()
			return
		}
		guard previous.count > 0 || results.count > 0 else { return }

		let collectionChanges = previous.collectionChanges(to: results)

		#if os(macOS)

		applyAsBatch(results, collectionChanges: collectionChanges, to: section, reloadRemaining: reloadRemaining)

		#else

		guard #available(iOS 11.0, tvOS 11.0, *) else {
			applyAsBatch(results, collectionChanges: collectionChanges, to: section, reloadRemaining: reloadRemaining)
			return
		}
		tableView.performBatchUpdates({
			tableView.applyCollectionChanges(collectionChanges, to: section)
			_results = results
		}) { [weak tableView] finished in
			guard finished, reloadRemaining, let tableView = tableView else { return }
			tableView.reloadRows(at: collectionChanges.reloads.map { IndexPath(row: $0, section: section) }, with: .automatic)
		}

		#endif
	}

	// MARK: - Private methods

	func applyAsBatch(_ results: [ResultType], collectionChanges: CollectionChanges<[ResultType]>, to section: Int, reloadRemaining: Bool) {
		tableView.beginUpdates()
		#if os(macOS)
		tableView.applyCollectionChanges(collectionChanges)
		#else
		tableView.applyCollectionChanges(collectionChanges, to: section)
		#endif
		_results = results
		tableView.endUpdates()
		guard reloadRemaining else { return }
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak tableView] in
			guard let tableView = tableView else { return }
			#if os(macOS)
			tableView.reloadData(forRowIndexes: IndexSet(collectionChanges.reloads), columnIndexes: IndexSet(arrayLiteral: 0))
			#else
			tableView.reloadRows(at: collectionChanges.reloads.map { IndexPath(row: $0, section: section) }, with: .automatic)
			#endif
		}
	}

	#if os(macOS)

	// MARK: - NSTableViewDataSource methods

	public override func numberOfRows(in tableView: NSTableView) -> Int {
		resultsApplied = true
		return _results?.count ?? 0
	}

	// MARK: - NSTableViewDelegate methods

	public override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let indexPath = IndexPath(arrayLiteral: row, 0)
		return self.tableView(tableView as! TableViewType, cellFor: _results[row], at: indexPath)
	}

	#else

	// MARK: - ResolveTableViewController overrides

	open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		resultsApplied = true
		return _results?.count ?? 0
	}

	open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return self.tableView(tableView as! TableViewType, cellFor: _results[indexPath.row], at: indexPath)
	}

	#endif

	// MARK: - Required overrides

	open func tableView(_ tableView: TableViewType, cellFor result: ResultType, at indexPath: IndexPath) -> TableViewCell {
		fatalError("\(type(of: self)) is expected to implement tableView(_:cellFor:at:)")
	}
}
