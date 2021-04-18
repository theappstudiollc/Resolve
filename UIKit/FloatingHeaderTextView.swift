//
//  FloatingHeaderTextView.swift
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

@IBDesignable public class FloatingHeaderTextView: FloatingHeaderControl {

	public var attributedText: NSAttributedString? {
		get { valueTextView.attributedText }
		set {
			valueTextView.attributedText = newValue
			super.updateText(newValue?.string)
		}
	}

	public dynamic var font: UIFont? {
		get { valueTextView.font }
		set {
			guard valueTextView.font != newValue else { return }
			valueTextView.font = newValue ?? defaultValueFont
			invalidateIntrinsicContentSize()
		}
	}

	@IBInspectable public var textColor: UIColor? {
		get { valueTextView.textColor }
		set { valueTextView.textColor = newValue }
	}

	public override func becomeFirstResponder() -> Bool {
		guard valueTextView.becomeFirstResponder() else { return false }
		sendActions(for: .editingDidBegin)
		return true
	}

	public override var canBecomeFirstResponder: Bool { isEnabled && valueTextView.canBecomeFirstResponder }

	public override var canResignFirstResponder: Bool { valueTextView.canResignFirstResponder }

	public override class func forwardingTarget(for aSelector: Selector!) -> Any? {
		return super.forwardingTarget(for: aSelector)
	}

	public override var isFirstResponder: Bool { valueTextView.isFirstResponder }

	override init(frame: CGRect) {
		super.init(frame: frame, valueView: valueTextView)
		setupValueTextView()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder, valueView: valueTextView)
		setupValueTextView()
	}

	public override var inputAccessoryView: UIView? {
		didSet { valueTextView.inputAccessoryView = inputAccessoryView }
	}

	public override var inputView: UIView? {
		didSet { valueTextView.inputView = inputView }
	}

	public override func resignFirstResponder() -> Bool {
		guard valueTextView.resignFirstResponder() else { return false }
		sendActions(for: .editingDidEnd)
		return true
	}

	public override func updateConstraints() {
		super.updateConstraints()
		// Ensure these two constraints are enabled/disabled in a specific order
		let headerLineHeight = morphingLabel.morphedLabel.font.lineHeight
		if hasValue {
			valueTextView.textContainerInset = UIEdgeInsets(top: headerLineHeight, left: 0, bottom: 0, right: 0)
			baselineConstraint.constant = headerLineHeight / 2
		} else {
			let inset = UIEdgeInsets(top: headerLineHeight / 2, left: 0, bottom: 0, right: 0)
			valueTextView.textContainerInset = inset
			baselineConstraint.constant = inset.top + valueTextView.font!.lineHeight / 2
		}
		baselineConstraint.isActive = true
	}

	public override func updateEnabled() {
		super.updateEnabled()
		#if os(iOS)
		valueTextView.isEditable = isEnabled
		#endif
	}

	public override func updateText(_ text: String?) {
		if valueTextView.text != text {
			valueTextView.text = text ?? ""
		}
		super.updateText(text)
	}

	// MARK: - Private properties and methods

	func setupValueTextView() {
		if #available(iOS 13.0, tvOS 13, *) {
			valueTextView.automaticallyAdjustsScrollIndicatorInsets = false
		}
		valueTextView.delegate = self
		valueTextView.font = defaultValueFont
		valueTextView.isScrollEnabled = false
		valueTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
		valueTextView.setContentCompressionResistancePriority(.required, for: .vertical)
		valueTextView.textAlignment = .natural
		valueHorizontalConstraints.leading.constant = 5
		valueHorizontalConstraints.trailing.constant = 5
		// Replace base constraints
		baselineConstraint = morphingLabel.centerYAnchor.constraint(equalTo: valueTextView.topAnchor)
		spacingConstraint = valueTextView.topAnchor.constraint(equalTo: morphingLabel.topAnchor)
		NSLayoutConstraint.deactivate([morphingCenterConstraint, valueCenterConstraint])
		NSLayoutConstraint.activate(constrainVertically(to: valueTextView, with: .required))
	}

	private let valueTextView = FloatingTextView(frame: .zero, textContainer: nil)
}

extension FloatingHeaderTextView: UITextViewDelegate {

	public func textViewDidChange(_ textView: UITextView) {
		guard textView === valueTextView else { return }
		super.updateText(textView.text)
		sendActions(for: .editingChanged)
	}

	public func textViewDidEndEditing(_ textView: UITextView) {
		sendActions(for: .editingDidEnd)
	}
}

private class FloatingTextView: UITextView {

	override var textContainerInset: UIEdgeInsets {
		get { super.textContainerInset }
		set {
			// Prevent unnecessary animations
			guard textContainerInset != newValue else { return }
			super.textContainerInset = newValue
		}
	}
}
