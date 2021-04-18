//
//  FloatingHeaderTextField.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2018 The App Studio LLC.
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
import UIKit

@IBDesignable public class FloatingHeaderTextField: FloatingHeaderControl {

	deinit {
		valueTextFieldBinding = nil
	}

	public var attributedText: NSAttributedString? {
		get { valueTextField.attributedText }
		set {
			valueTextField.attributedText = newValue
			super.updateText(newValue?.string)
		}
	}

	public dynamic var font: UIFont? {
		get { valueTextField.font }
		set {
			guard valueTextField.font != newValue else { return }
			valueTextField.font = newValue ?? defaultValueFont
			invalidateIntrinsicContentSize()
		}
	}

	@IBInspectable public var textColor: UIColor? {
		get { valueTextField.textColor }
		set { valueTextField.textColor = newValue }
	}

	public override func becomeFirstResponder() -> Bool {
		guard valueTextField.becomeFirstResponder() else { return false }
		sendActions(for: .editingDidBegin)
		return true
	}

	public override var canBecomeFirstResponder: Bool { isEnabled && valueTextField.canBecomeFirstResponder }

	public override var canResignFirstResponder: Bool { valueTextField.canResignFirstResponder }

	public override var isFirstResponder: Bool { valueTextField.isFirstResponder }

	override init(frame: CGRect) {
		super.init(frame: frame, valueView: valueTextField)
		setupValueTextField()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder, valueView: valueTextField)
		setupValueTextField()
	}

	public override var inputAccessoryView: UIView? {
		didSet { valueTextField.inputAccessoryView = inputAccessoryView }
	}

	public override var inputView: UIView? {
		didSet { valueTextField.inputView = inputView }
	}

	public override func resignFirstResponder() -> Bool {
		guard valueTextField.resignFirstResponder() else { return false }
		sendActions(for: .editingDidEnd)
		return true
	}

	public override func updateEnabled() {
		super.updateEnabled()
		valueTextField.isEnabled = isEnabled
	}

	public override func updateText(_ text: String?) {
		if valueTextField.text != text {
			valueTextField.text = text ?? ""
		}
		super.updateText(text)
	}

	func setupValueTextField() {
		valueTextField.font = defaultValueFont
		valueTextField.textAlignment = .natural
		valueTextFieldBinding = valueTextField.bind(.editingChanged, from: \.text, to: super.updateText(_:))
	}

	let valueTextField = UITextField()

	private var valueTextFieldBinding: ResolveBinding.Unbind? {
		willSet { valueTextFieldBinding?() }
	}
}
