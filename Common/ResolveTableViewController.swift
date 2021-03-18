//
//  ResolveTableViewController.swift
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

#if os(iOS) || os(tvOS)

#if TARGET_INTERFACE_BUILDER || targetEnvironment(simulator) || DEBUG

open class ResolveTableViewController: CoreTableViewController { }

#else // Production builds should just typealias so that we remove a layer in the class hierarchy

public typealias ResolveTableViewController = TableViewController

#endif

#elseif os(macOS)

open class ResolveTableViewController: CoreTableViewController, NSTableViewDataSource, NSTableViewDelegate {

    /// Common version of `viewDidAppear` matching UIKit. `animated` will always be false on macOS
    open func viewDidAppear(_ animated: Bool) { }

    /// Common version of `viewDidDisappear` matching UIKit. `animated` will always be false on macOS
    open func viewDidDisappear(_ animated: Bool) { }

    /// Common version of `viewWillAppear` matching UIKit. `animated` will always be false on macOS
    open func viewWillAppear(_ animated: Bool) { }

    /// Common version of `viewWillDisappear` matching UIKit. `animated` will always be false on macOS
    open func viewWillDisappear(_ animated: Bool) { }

	// MARK: - CoreTableViewController overrides

    override open func viewDidAppear() {
        super.viewDidAppear()
        viewDidAppear(false)
    }

    override open func viewDidDisappear() {
        super.viewDidDisappear()
        viewDidDisappear(false)
    }

	override open func viewDidLoad() {
		super.viewDidLoad()
		tableView.dataSource = self
		tableView.delegate = self
	}

    override open func viewWillAppear() {
        super.viewWillAppear()
        viewWillAppear(false)
    }

    override open func viewWillDisappear() {
        super.viewWillDisappear()
        viewWillDisappear(false)
    }

	// MARK: - NSTableViewDataSource methods

	open func numberOfRows(in tableView: NSTableView) -> Int {
		return 0
	}

	// MARK: - NSTableViewDelegate methods

	open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		fatalError("\(type(of: self)) is expected to implement tableView(_:viewFor:row:)")
	}
}

#endif
