//
//  SharedEventTableView.swift
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

#if os(watchOS)
protocol SharedEventTableImplements { }
#elseif os(macOS)
protocol SharedEventTableImplements: CoreColumnLayoutContaining { }
#else // iOS & tvOS
protocol SharedEventTableImplements: CoreColumnLayoutContaining, CoreTableViewPreparesViewsForSizing { }
#endif

#if os(watchOS)

final class SharedEventTableView: TableView, SharedEventTableImplements { }

#else

final class SharedEventTableView: TableView, SharedEventTableImplements {

	var columnAnchorGuide: CoreHorizontalLayoutAnchorable {
		#if os(macOS)
		return self
		#else
		return layoutMarginsGuide
		#endif
	}
	
	let columnLayoutProvider: CoreColumnLayoutProviding = CoreColumnLayoutProvider(numberOfColumns: 2, spacing: SharedEventTableView.defaultSpacing)
	
	private var columnRatioConstraint: NSLayoutConstraint!
	
	var currentRatio: Float {
		get {
			let width = columnAnchorGuide.currentLayoutWidth > 0 ? columnAnchorGuide.currentLayoutWidth : frame.width
			return Float(columnLayoutProvider.layoutProvider(for: 0).currentLayoutWidth / width)
		}
		set {
			if newValue < 0 {
				columnRatioConstraint.isActive = false
			} else {
				let width = columnAnchorGuide.currentLayoutWidth > 0 ? columnAnchorGuide.currentLayoutWidth : frame.width
				columnRatioConstraint.constant = CGFloat(newValue) * width
				columnRatioConstraint.isActive = true
			}
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupTableView()
	}
		
	#if !os(macOS)
	
	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)
		setupTableView()
	}
	
	#endif
	
	private class var defaultSpacing: CoreColumnLayoutProvider.Spacing {
		if #available(iOS 11.0, tvOS 11.0, *) {
			return .system
		}
		return .custom(8)
	}
	
	private func setupTableView() {
		NSLayoutConstraint.activate(configureColumns(to: columnAnchorGuide))
		let columnGuide = columnLayoutProvider.layoutProvider(for: 0)
		columnRatioConstraint = columnGuide.widthAnchor.constraint(equalToConstant: 0)
		columnRatioConstraint.priority = .required - 1
	}
}

#endif

extension SharedEventTableView: CoreCellDequeuing {
	
	public enum CellIdentifier: String {
		case sharedEventCell
		#if os(macOS)
		case sharedEventRow
		#endif
	}
}

extension SharedEventTableView: CoreTable {
	
	typealias CellType = SharedEventTableViewCell

	func cellIdentifierFor(result: SharedEvent) -> String {
		return CellIdentifier.sharedEventCell.rawValue
	}
}

#if os(macOS)

final class SharedEventRow: NSTableCellView { }

#endif
