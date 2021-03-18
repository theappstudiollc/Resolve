//
//  SharedEventTableViewDataSource.swift
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

final class SharedEventTableViewDataSource: CoreTableDataSource<SharedEventTableView> {

	#if os(iOS) || os(tvOS)

	@Service var loggingService: CoreLoggingService

	override func getPrefetchDataSource() -> AnyPrefetchDataSource<SharedEvent>? {
		guard #available(iOS 10.0, macOS 10.13.0, tvOS 10.0, *) else { return nil }
		return SharedEventPrefetchDataSource(loggingService: loggingService).toAny()
	}

	#elseif os(macOS)
	
	override func tableView(_ tableView: SharedEventTableView, rowCellWith title: String, at indexPath: IndexPath) -> NSView {
		let cell: SharedEventRow = tableView.dequeueReusableCell(withIdentifier: .sharedEventRow)
		cell.textField?.stringValue = title
		return cell
	}

	#elseif os(watchOS)

	public override func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		super.controllerDidChangeContent(controller)
		// watchOS has limited ability to handle many records, let's keep the table pruned by the fetch limit
		if controller.fetchRequest.fetchLimit > 0, controller.fetchRequest.fetchLimit < table.numberOfRows {
			print("Too many rows: \(table.numberOfRows) vs. \(controller.fetchRequest.fetchLimit)")
			table.removeRows(at: IndexSet(controller.fetchRequest.fetchLimit..<table.numberOfRows))
		}
	}

	public override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		// Cut out early if we know there's an insert beyond our fetchLimit
		if type == .insert, let indexPath = newIndexPath, controller.fetchRequest.fetchLimit > 0, indexPath.row >= controller.fetchRequest.fetchLimit {
			print("Skipping insert @ \(indexPath.row) > than number of allowed rows: \(controller.fetchRequest.fetchLimit)")
			return
		}
		super.controller(controller, didChange: anObject, at: indexPath, for: type, newIndexPath: newIndexPath)
	}

	#endif
	
	override class var tracksResults: Bool {
		return true
	}
}
