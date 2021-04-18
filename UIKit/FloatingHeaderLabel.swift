//
//  FloatingHeaderLabel.swift
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

@IBDesignable public class FloatingHeaderLabel: FloatingHeaderControl {

	public var attributedText: NSAttributedString? {
		get { valueLabel.attributedText }
		set {
			valueLabel.attributedText = newValue
			super.updateText(newValue?.string)
		}
	}

	public dynamic var font: UIFont? {
		get { valueLabel.font }
		set {
			guard valueLabel.font != newValue else { return }
			valueLabel.font = newValue ?? defaultValueFont
			invalidateIntrinsicContentSize()
		}
	}

	@IBInspectable public var textColor: UIColor? {
		get { valueLabel.textColor }
		set { valueLabel.textColor = newValue }
	}

	override init(frame: CGRect) {
		super.init(frame: frame, valueView: valueLabel)
		setupValueLabel()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder, valueView: valueLabel)
		setupValueLabel()
	}

	public override func updateEnabled() {
		super.updateEnabled()
		valueLabel.isEnabled = isEnabled
	}

	public override func updateText(_ text: String?) {
		if valueLabel.text != text {
			valueLabel.text = text ?? ""
		}
		super.updateText(text)
	}

	private let valueLabel = FloatingScalableLable(textStyle: .body)

	func setupValueLabel() {
		valueLabel.backgroundColor = .clear // The base 'nil' value causes drawing bugs
		valueLabel.constrainsMinimumWidth = false
		valueLabel.font = defaultValueFont
		valueLabel.textAlignment = .natural
	}
}

private class FloatingScalableLable: CoreScalableLabel {

	open override var intrinsicContentSize: CGSize {
		let result = super.intrinsicContentSize
		guard result.height <= 0 else { return result }
		// Ensure that an empty label does not collapse the intrinsic height (use the font's lineHeight)
		return CGSize(width: result.width, height: font.lineHeight * transform.yScale)
	}
}
