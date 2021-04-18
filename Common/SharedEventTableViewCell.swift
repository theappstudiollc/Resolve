//
//  SharedEventTableViewCell.swift
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

final class SharedEventTableViewCell: TableViewCell {

	#if os(watchOS)

	@IBOutlet var createdAtTimer: WKInterfaceTimer!

	internal var sharedEvent: SharedEvent?

	#else

	@IBOutlet fileprivate var createdAtLabel: Label!

	private var mappedToColumns = false

	public weak var columnLayoutProvider: CoreColumnLayoutProviding? {
		didSet {
			guard columnLayoutProvider !== oldValue else { return }
			mappedToColumns = false
			updateColumns()
		}
	}

	private func updateColumns() {
		guard superview != nil, window != nil, columnLayoutProvider != nil, createdAtLabel != nil, createdByLabel != nil else { return }
		guard mappedToColumns == false else {
			return
		}
		#if !os(macOS)
		try! constrainLayoutProvider(createdAtLabel, to: 1)
		try! constrainLayoutProvider(createdByLabel, to: 0)
		#endif
		mappedToColumns = true
	}

	#endif

	@IBOutlet fileprivate var createdByLabel: Label!
	
	#if os(macOS)
	
	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		updateColumns()
	}
	
	override func viewDidMoveToSuperview() {
		super.viewDidMoveToSuperview()
		if superview == nil {
			// This means our column constraints have been invalidated
			mappedToColumns = false
		}
		updateColumns()
	}
	
	#elseif os(iOS) || os(tvOS)
	
	override func didMoveToSuperview() {
		super.didMoveToSuperview()
        if superview == nil {
            // This means our column constraints have been invalidated
            mappedToColumns = false
        }
		updateColumns()
	}

	override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		guard #available(iOS 12.0, *) else { return } // Don't change anything if dark mode is not supported
		switch (traitCollection.userInterfaceStyle, isFocused) {
		case (_, true), (.light, false), (.unspecified, false):
			createdAtLabel.textColor = UIColor.black
			createdByLabel.textColor = UIColor.black
		case (_, _):
			createdAtLabel.textColor = UIColor.white
			createdByLabel.textColor = UIColor.white
		}
	}

	#endif
}

#if !os(watchOS)

extension SharedEventTableViewCell: CoreColumnLayoutAware { }

#endif

extension SharedEventTableViewCell: CoreTableCell {

	typealias ResultType = SharedEvent
	
	func applyResult(_ result: SharedEvent) {
		#if os(watchOS)
		sharedEvent = result
		createdByLabel.setText(result.createdByDevice)
		if let createdLocallyAt = result.createdLocallyAt {
			createdAtTimer.setDate(createdLocallyAt)
			createdAtTimer.start()
		} else {
			createdAtTimer.setHidden(true)
		}
		#else
		createdAtLabel.labelText = DateFormatter.localizedString(from: result.createdLocallyAt!, dateStyle: .short, timeStyle: .medium)
		createdByLabel.labelText = result.createdByDevice ?? "<no one>"
		#endif
		#if !os(macOS) && !os(watchOS)
        if result.cloudSyncStatus.contains(.markedForDeletion) {
            contentView.backgroundColor = UIColor.red.withAlphaComponent(0.2)
		} else if result.notLinked {
			contentView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        } else if let iCloudReference = result.iCloudReference(for: .public), !iCloudReference.synchronized {
            contentView.backgroundColor = UIColor.green.withAlphaComponent(0.2)
        } else {
            contentView.backgroundColor = nil
        }
		#endif
	}
}
