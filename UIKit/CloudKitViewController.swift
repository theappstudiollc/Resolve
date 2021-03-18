//
//  CloudKitViewController.swift
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

#if canImport(ContactsUI)
import ContactsUI
#endif
import ResolveKit

final class CloudKitViewController: ResolveViewController {
	
	@Service var cloudService: CloudKitService
	@Service var dataService: CoreDataService
	@Service var inputService: UserInputService
	@Service var userService: AppUserService
	
	@IBOutlet private var cloudKitTableViewController: CloudKitTableViewController!

	@IBOutlet private var lookupFriendButton: UIBarButtonItem!
	
	@IBOutlet private var userAliasTextField: UITextField!
	
	@IBOutlet private var updateUserAliasButton: UIButton!

	#if canImport(ContactsUI)

	@IBAction private func lookupFriendTapped(_ sender: UIBarButtonItem) {
		sender.isEnabled = false
		let contactPicker = CNContactPickerViewController()
		contactPicker.delegate = self
		contactPicker.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0")
		present(contactPicker, animated: true)
	}

	#endif
	
	@IBAction private func updateUserAliasTapped(_ sender: UIButton) {
		sender.isEnabled = false
		
		return dataService.performAndWait { [cloudService, userService] context in
			guard let appUser = try? userService.currentAppUser(using: context) else {
				sender.isEnabled = true
				return
			}
			let transactionContext = context.beginTransaction()
			do {
				appUser.userAlias = self.userAliasTextField.text
				appUser.markSynchronized(false, in: .public, using: context)
				try context.commitTransaction(transactionContext: transactionContext)
			} catch {
				loggingService.log(.error, "Error updating user alias: %{public}@", error.localizedDescription)
				context.cancelTransaction(transactionContext: transactionContext)
				sender.isEnabled = true
				return
			}
			guard let iCloudReference = appUser.iCloudReference(for: .public) else {
				sender.isEnabled = true
				return
			}
			iCloudReference.synchronized = false
			cloudService.synchronize(syncOptions: .fetchAll, qualityOfService: .userInitiated) { _ in
				DispatchQueue.main.async {
					sender.isEnabled = true
				}
			}
		}
	}
	
	@IBAction private func userAliasTextDidChange(_ sender: UITextField) {
		updateUpdateUserAliasButton(sender.text, currentUserAlias())
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let cloudKitTableViewController = segue.destination as? CloudKitTableViewController {
			self.cloudKitTableViewController = cloudKitTableViewController
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		userAliasTextField.text = currentUserAlias()
		updateUpdateUserAliasButton(userAliasTextField.text, userAliasTextField.text)
	}
	
	private func currentUserAlias() -> String? {
		return try? dataService.performAndReturn { [userService] context in
			return try userService.currentAppUser(using: context)?.userAlias
		}
	}
	
	private func updateUpdateUserAliasButton(_ labelText: String?, _ userAlias: String?) {
		updateUserAliasButton.isEnabled = labelText?.count ?? 0 > 0 && labelText != userAlias
	}
}

#if canImport(Contacts)

extension CloudKitViewController: CNContactPickerDelegate {

	func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
		lookupFriendButton.isEnabled = true
	}

	func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
		// Look up that friend with the CloudKitService
		cloudService.addFriends(contacts: [contact]) { [inputService] result in
			DispatchQueue.main.async {
				self.lookupFriendButton.isEnabled = true
			}
			switch result {
			case .success:
				// TODO: If no records are found, let's display a message
				break
			case .failure(let error):
				inputService.presentAlert(error.localizedDescription, withTitle: "Error adding contact", from: self, forDuration: 2.0)
			}
		}
	}
}

#endif
