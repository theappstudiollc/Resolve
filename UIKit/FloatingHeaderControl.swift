//
//  FloatingHeaderControl.swift
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

/// Base (abstract) class for representing a custom 'value' control with a placeholder that floats to the header
@IBDesignable open class FloatingHeaderControl: UIControl {

	// MARK: - Public properties

	@IBInspectable public var headerColor: UIColor! {
		get { morphingLabel.morphedTextColor }
		set { morphingLabel.morphedTextColor = newValue }
	}

	@IBInspectable public var placeholder: String? {
		didSet { updatePlaceholder() }
	}

	@IBInspectable public var placeholderColor: UIColor! {
		get { morphingLabel.textColor }
		set { morphingLabel.textColor = newValue }
	}

	@IBInspectable public var spacing: CGFloat = 1 {
		didSet { spacingConstraint.constant = spacing }
	}

	var _text: String?
	@IBInspectable public var text: String? {
		get { _text }
		set { updateText(newValue) }
	}

	// MARK: - UIControl overrides

	open override var accessibilityLabel: String? {
		get { super.accessibilityLabel ?? placeholder }
		set { super.accessibilityLabel = newValue }
	}

	open override var accessibilityValue: String? {
		get { super.accessibilityValue ?? (hasValue ? _text : nil) }
		set { super.accessibilityValue = newValue }
	}

	open override func becomeFirstResponder() -> Bool {
		guard super.becomeFirstResponder() else { return false }
		sendActions(for: .editingDidBegin)
		return true
	}

	open override var canBecomeFirstResponder: Bool { isEnabled && inputView != nil }

	public override var forFirstBaselineLayout: UIView { morphingLabel }

	public override var forLastBaselineLayout: UIView { valueView }

	var _inputAccessoryView: UIView?
	open override var inputAccessoryView: UIView? {
		get { _inputAccessoryView }
		set { _inputAccessoryView = newValue }
	}

	var _inputView: UIView?
	open override var inputView: UIView? {
		get { _inputView }
		set { _inputView = newValue }
	}

	public init(frame: CGRect, valueView: UIView) {
		self.valueView = valueView
		super.init(frame: frame)
		setupControl()
	}

	public init?(coder: NSCoder, valueView: UIView) {
		self.valueView = valueView
		super.init(coder: coder)
		setupControl()
	}

	public override init(frame: CGRect) {
		fatalError("init(frame:) is not allowed. Please use init(frame:valueView:). This definition is also required for Interface Builder")
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) is not allowed. Please use init(coder:valueView:)")
	}

	public override var intrinsicContentSize: CGSize {
		let valueSize = valueView.intrinsicContentSize
		let headerSize = morphingLabel.morphedLabel.intrinsicContentSize
		let morphingSize = morphingLabel.intrinsicContentSize
		let height = headerSize.height + valueSize.height + spacing
		guard traitCollection.displayScale > 0 else {
			return CGSize(width: max(valueSize.width, morphingSize.width), height: ceil(height))
		}
		return CGSize(width: max(valueSize.width, morphingSize.width), height: ceil(height * traitCollection.displayScale) / traitCollection.displayScale)
	}

	@IBInspectable open override var isEnabled: Bool {
		didSet { updateEnabled() }
	}

	open override func layoutSubviews() {
		let width = valueView.bounds.width
		super.layoutSubviews()
		// Changes to the valueView's width may change this control's height
		guard valueView.bounds.width != width else { return }
		invalidateIntrinsicContentSize()
		setNeedsLayout()
		layoutIfNeeded()
	}

	public override class var requiresConstraintBasedLayout: Bool { true }

	open override func resignFirstResponder() -> Bool {
		guard super.resignFirstResponder() else { return false }
		sendActions(for: .editingDidEnd)
		return true
	}

	open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesBegan(touches, with: event)
		_ = becomeFirstResponder()
	}

	public override func updateConstraints() {
		super.updateConstraints()
		// Ensure these two constraints are enabled/disabled in a specific order
		if hasValue {
			baselineConstraint.isActive = false
			spacingConstraint.isActive = true
		} else {
			spacingConstraint.isActive = false
			baselineConstraint.isActive = true
		}
	}

	// MARK: - Private properties and methods

	var baselineConstraint: NSLayoutConstraint! {
		didSet { baselineConstraint.identifier = "BaselineConstraint" }
	}
	var defaultValueFont: UIFont {
		return UIFont.systemFont(ofSize: 17)
	}
	var hasValue: Bool { (_text?.count ?? 0) > 0 }
	var morphingCenterConstraint: NSLayoutConstraint!
	let morphingLabel = MorphingLabel(frame: .zero)
	var spacingConstraint: NSLayoutConstraint! {
		didSet { spacingConstraint.identifier = "SpacingConstraint" }
	}
	let valueView: UIView
	var valueCenterConstraint: NSLayoutConstraint!
	var valueHorizontalConstraints: HorizontalBoundingConstraints!

	func refreshLayout() {
		morphingLabel.isMorphed = hasValue
		updateConstraintsIfNeeded()
		layoutIfNeeded()
	}

	func setupControl() {

		isAccessibilityElement = true

		morphingLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		morphingLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
		morphingLabel.translatesAutoresizingMaskIntoConstraints = false
		// Appearance API is supposed to override these sizes and colors -- but here are reasonable defaults
		morphingLabel.label.font = UIFont.systemFont(ofSize: 17, weight: .light)
		morphingLabel.label.textColor = tintColor.withAlphaComponent(0.5)
		morphingLabel.morphedLabel.font = UIFont.systemFont(ofSize: 17 * 0.8, weight: .semibold)
		morphingLabel.morphedLabel.textColor = .lightGray
		addSubview(morphingLabel)
		morphingLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
		let morphingHorizontalConstraints = constrainHorizontally(to: morphingLabel, trailingPriority: .defaultHigh)
		morphingCenterConstraint = centerYAnchor.constraint(equalTo: morphingLabel.centerYAnchor)
		morphingCenterConstraint.priority = .defaultLow

		valueView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		valueView.setContentHuggingPriority(.defaultHigh, for: .vertical)
		valueView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(valueView)
		valueView.backgroundColor = nil
		valueView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
		valueHorizontalConstraints = constrainHorizontally(to: valueView)
		valueCenterConstraint = centerYAnchor.constraint(equalTo: valueView.centerYAnchor)
		valueCenterConstraint.priority = .defaultLow

		NSLayoutConstraint.activate([morphingCenterConstraint, valueCenterConstraint] + morphingHorizontalConstraints.constraints + valueHorizontalConstraints.constraints)

		baselineConstraint = morphingLabel.firstBaselineAnchor.constraint(equalTo: valueView.firstBaselineAnchor)
		spacingConstraint = valueView.topAnchor.constraint(equalTo: morphingLabel.bottomAnchor, constant: spacing)
		spacingConstraint.constant = spacing

		updateText(text)
	}

	open func updateEnabled() {
		valueView.alpha = isEnabled ? 1 : 0.3
	}

	func updatePlaceholder() {
		guard morphingLabel.text != placeholder else { return }
		morphingLabel.text = placeholder
		invalidateIntrinsicContentSize()
	}

	open func updateText(_ text: String?) {
		guard _text != text else { return }
		let shouldAnimate = window != nil && ((_text?.count ?? 0) == 0) != ((text?.count ?? 0) == 0)
		_text = text
		invalidateIntrinsicContentSize()
		setNeedsLayout()
		setNeedsUpdateConstraints()
		if shouldAnimate {
			let animationDuration: TimeInterval = 0.2
			valueView.alpha = 0
			UIView.animate(withDuration: animationDuration * 0.5, delay: animationDuration * 0.5, options: .curveEaseIn, animations: updateEnabled)
			UIView.animate(withDuration: animationDuration, delay: 0, options: .beginFromCurrentState, animations: refreshLayout)
		} else {
			refreshLayout()
		}
		sendActions(for: .valueChanged)
	}
}

@available(iOS 10.0, tvOS 10.0, *)
extension FloatingHeaderControl: UIContentSizeCategoryAdjusting {

	public var adjustsFontForContentSizeCategory: Bool {
		get { categoryAdjustingChildren.allSatisfy({ $0.adjustsFontForContentSizeCategory }) }
		set { categoryAdjustingChildren.forEach { $0.adjustsFontForContentSizeCategory = newValue } }
	}

	private var categoryAdjustingChildren: [UIContentSizeCategoryAdjusting] {
		guard let valueAdjusting = valueView as? UIContentSizeCategoryAdjusting else {
			return [morphingLabel]
		}
		return [valueAdjusting, morphingLabel]
	}
}
