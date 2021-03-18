//
//  MorphingLabel.swift
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

@IBDesignable public class FloatingValueLabel: UIStackView {
	
	var font: UIFont! = UIFont.systemFont(ofSize: 18, weight: .regular) {
		didSet { valueLabel.font = font }
	}
	@IBInspectable public var textColor: UIColor! = UIColor.red {
		didSet { valueLabel.textColor = textColor }
	}
	@IBInspectable public var isSelected: Bool = false {
		didSet { updateSelected(oldValue: oldValue) }
	}
	@IBInspectable public var placeholder: String? = "Critical" {
		didSet { updateText() }
	}
	@IBInspectable public var text: String? = "YES" {
		didSet { updateText() }
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupControl()
	}
	
	required init(coder: NSCoder) {
		super.init(coder: coder)
		setupControl()
	}
	/*
	override var forFirstBaselineLayout: UIView {
		return valueLabel
	}
	*/
	public override var forLastBaselineLayout: UIView {
		return valueLabel
	}

	func setupControl() {
		alignment = .leading
		axis = .vertical
		distribution = .fill

		addArrangedSubview(morphingLabel)
		valueLabel.backgroundColor = UIColor.magenta.withAlphaComponent(0.1)
		valueLabel.font = font
		valueLabel.textAlignment = .natural
		valueLabel.textColor = textColor
		valueLabel.text = text
		valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		valueLabel.setContentHuggingPriority(.required, for: .horizontal)
		addArrangedSubview(valueLabel)
		updateSelected(oldValue: isSelected)
		updateText()
	}
	
	func updateSelected(oldValue: Bool) {
		if isSelected {
			isBaselineRelativeArrangement = false
			spacing = 1
			valueLabel.alpha = 1
		} else {
			isBaselineRelativeArrangement = true
			spacing = 0
			valueLabel.alpha = 0
		}
		morphingLabel.isSelected = isSelected
	}
	
	func updateText() {
		morphingLabel.text = placeholder
		valueLabel.text = text
	}

	let morphingLabel = MorphingLabel(frame: .zero)
	let valueLabel = CoreScalableLabel(textStyle: .body)
}

@IBDesignable final class MorphingLabel: UIStackView {
	
	var font: UIFont! = UIFont.systemFont(ofSize: 18, weight: .semibold) {
		didSet { label.font = font }
	}
	var selectedFont: UIFont! = UIFont.systemFont(ofSize: 12, weight: .regular) {
		didSet { selectedLabel.font = selectedFont }
	}
	@IBInspectable var textColor: UIColor! = UIColor.black {
		didSet { label.textColor = textColor }
	}
	@IBInspectable var textSelectedColor: UIColor! = UIColor.gray {
		didSet { selectedLabel.textColor = textSelectedColor}
	}
	@IBInspectable var isSelected: Bool = false {
		didSet { updateSelected(oldValue: oldValue) }
	}
	@IBInspectable var text: String? = "Placeholder" {
		didSet { updateText() }
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupControl()
	}
	
	required init(coder: NSCoder) {
		super.init(coder: coder)
		setupControl()
	}
	/*
	override var forFirstBaselineLayout: UIView {
		return label
	}

	override var forLastBaselineLayout: UIView {
		return label
	}
	*/
	func setupControl() {
		alignment = .leading
		axis = .vertical
		distribution = .fill
		isBaselineRelativeArrangement = true
		spacing = 0
		label.backgroundColor = UIColor.magenta.withAlphaComponent(0.1)
		label.font = font
		label.textAlignment = .natural
		label.textColor = textColor
		label.text = text
		label.setContentCompressionResistancePriority(.required, for: .horizontal)
		label.setContentHuggingPriority(.required, for: .horizontal)
		addArrangedSubview(label)
		selectedLabel.backgroundColor = UIColor.magenta.withAlphaComponent(0.1)
		selectedLabel.font = selectedFont
		selectedLabel.textAlignment = .natural
		selectedLabel.textColor = textSelectedColor
		selectedLabel.text = text
		selectedLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		selectedLabel.setContentHuggingPriority(.required, for: .horizontal)
		addArrangedSubview(selectedLabel)
		updateSelected(oldValue: isSelected)
	}
	
	func updateSelected(oldValue: Bool) {
		var hiddenView: UIView!
		var visibleView: UIView!
		if isSelected {
			hiddenView = label
			visibleView = selectedLabel
		} else {
			hiddenView = selectedLabel
			visibleView = label
		}
		visibleView.alpha = 1
		visibleView.transform = .identity
		hiddenView.alpha = 0
		let fromSize = hiddenView.intrinsicContentSize
		let toSize = visibleView.intrinsicContentSize
//		let xTranslate = (toSize.width - fromSize.width) / 4
//		let yTranslate = (toSize.height - fromSize.height) / -4
//		hiddenView.transform = CGAffineTransform(scaleX: toSize.width / fromSize.width, y: toSize.height / fromSize.height)
//			.translatedBy(x: xTranslate, y: yTranslate)
		let xTranslate = (toSize.width - fromSize.width) / 2
		let yTranslate = (toSize.height - fromSize.height) / -4
		hiddenView.transform = CGAffineTransform(translationX: xTranslate, y: yTranslate)
			.scaledBy(x: toSize.width / fromSize.width, y: toSize.height / fromSize.height)
	}
	
	func updateText() {
		label.text = text
		selectedLabel.text = text
	}
	
	let label = CoreScalableLabel(textStyle: .body)
	let selectedLabel = CoreScalableLabel(textStyle: .body)
}
