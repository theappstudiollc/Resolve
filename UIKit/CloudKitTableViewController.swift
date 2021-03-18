//
//  CloudKitTableViewController.swift
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

final class CloudKitTableViewController: CoreTableViewController {

	@Service var appUserService: AppUserService
	@Service var dataService: CoreDataService

	internal var source: UserTableViewDataSource!

	internal var userTableView: UserTableView {
		get { return tableView as! UserTableView }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		source = UserTableViewDataSource(for: userTableView, with: { [appUserService, dataService] in
			let context = dataService.viewContext
			context.userInfo["CurrentAppUser"] = try? appUserService.currentAppUser(using: context)
			let request: NSFetchRequest<User> = User.fetchRequest()
			request.sortDescriptors = [NSSortDescriptor(key: "userAlias", ascending: true)]
			return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		})
    }
}
