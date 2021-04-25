//
//  LayoutViewController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2021 The App Studio LLC.
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

final class LayoutViewController: ResolveViewController {

	@Service var userActivityService: UserActivityService

	// MARK: - Interface Builder properties and methods

	@IBOutlet private var recipientLabel: FloatingHeaderLabel!
	@IBOutlet private var scrollView: UIScrollView!

	// MARK: - ResolveViewController overrides

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if userActivity == nil {
			userActivity = userActivityService.userActivity(for: .layout)
		}
		userActivity?.becomeCurrent()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.hidesBarsOnTap = false
		recipientLabel.inputView = recipientPicker()
		// Create the KeyboardLayoutPlugin and constrain the scrollView content's height to the plugin's layoutGuide
		let keyboardLayoutGuide = KeyboardLayoutPlugin(viewController: self, for: scrollView)
		if let contentView = scrollView.contentView {
			let heightConstraint = contentView.heightAnchor.constraint(equalTo: keyboardLayoutGuide.layoutGuide.heightAnchor)
			heightConstraint.priority = .defaultHigh
			heightConstraint.isActive = true
		}
	}

	// MARK: - Private properties and methods

	private var keyboardLayoutPlugin: KeyboardLayoutPlugin!

	fileprivate let recipients = ["", "Alice", "Bob", "Carol"]

	private func recipientPicker() -> UIPickerView {
		let picker = UIPickerView()
		picker.dataSource = self
		picker.delegate = self
		return picker
	}
}

extension LayoutViewController: UIPickerViewDataSource {

	func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		guard component == 0 else { return 0 }
		return recipients.count
	}
}

extension LayoutViewController: UIPickerViewDelegate {

	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		guard component == 0 else { return nil }
		return recipients[row]
	}

	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		guard component == 0 else { return }
		recipientLabel.text = recipients[row]
	}
}

fileprivate extension UIScrollView {

	var contentView: UIView? { subviews.first(where: { $0 is UIStackView }) }
}
