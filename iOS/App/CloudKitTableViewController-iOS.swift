//
//  CloudKitTableViewController-iOS.swift
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
import UIKit

extension CloudKitTableViewController {

	@IBAction private func refreshControlRefreshing(_ sender: Any?) {
		let refreshControl = sender as? UIRefreshControl
		// TODO: Create a cloud sync that refreshes all users
		DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(1)) { [weak self] in
			defer {
				refreshControl?.endRefreshing()
			}
			// TODO: Would be nice to re-animate the new groupings
			guard let source = self?.source else { return }
			source.setNeedsReload()
			source.reloadIfNeeded()
		}
		refreshControl?.beginRefreshing()
	}
}
