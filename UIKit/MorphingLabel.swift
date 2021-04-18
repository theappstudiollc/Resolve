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

@IBDesignable public class MorphingLabel: UIView {
	
	public dynamic var font: UIFont! {
		get { label.font }
		set {
			guard label.font != newValue else { return }
			label.font = newValue
			invalidateIntrinsicContentSize()
			setNeedsLayout()
		}
	}
	public dynamic var morphedFont: UIFont! {
		get { morphedLabel.font }
		set {
			guard morphedLabel.font != newValue else { return }
			morphedLabel.font = newValue
			invalidateIntrinsicContentSize()
			setNeedsLayout()
		}
	}
	@IBInspectable public var morphedTextColor: UIColor! {
		get { morphedLabel.textColor }
		set { morphedLabel.textColor = newValue }
	}
	@IBInspectable public var textColor: UIColor! {
		get { label.textColor }
		set { label.textColor = newValue }
	}
	@IBInspectable public var isMorphed: Bool = false {
		didSet {
			updateMorphed(oldValue: oldValue)
			layoutIfNeeded()
			// Because the size is changing, superviews should adjust as well
			for view in viewLayoutChain {
				switch view {
				case let tableView as UITableView:
					tableView.beginUpdates()
					tableView.endUpdates()
				default:
					view.layoutIfNeeded()
				}
			}
		}
	}
	@IBInspectable public var text: String? {
		didSet { updateText() }
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupControl()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupControl()
	}

	public override var intrinsicContentSize: CGSize {
		isMorphed ? morphedLabel.intrinsicContentSize : label.intrinsicContentSize
	}

	public override var forFirstBaselineLayout: UIView {
		isMorphed ? morphedLabel : label
	}

	public override var forLastBaselineLayout: UIView {
		isMorphed ? morphedLabel : label
	}

	public override func layoutSubviews() {
		super.layoutSubviews()

		let hiddenView: UIView = isMorphed ? label : morphedLabel
		let visibleView: UIView = isMorphed ? morphedLabel : label

		let fromSize = hiddenView.intrinsicContentSize
		let toSize = visibleView.intrinsicContentSize
		guard fromSize != .zero, toSize != .zero else { return }

		let xTranslate = (toSize.width - fromSize.width) / 2
		let yTranslate = (toSize.height - fromSize.height) / -4
		hiddenView.transform = CGAffineTransform(translationX: xTranslate, y: yTranslate).scaledBy(x: toSize.width / fromSize.width, y: toSize.height / fromSize.height)
		hiddenView.alpha = 0

		visibleView.transform = .identity
		visibleView.alpha = 1
	}

	public override class var requiresConstraintBasedLayout: Bool { true }

	func setupControl() {

		label.constrainsMinimumWidth = false
		label.textAlignment = .natural
		label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		label.setContentHuggingPriority(.defaultHigh, for: .vertical)
		label.translatesAutoresizingMaskIntoConstraints = false
		addSubview(label)

		morphedLabel.constrainsMinimumWidth = false
		morphedLabel.textAlignment = .natural
		morphedLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		morphedLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
		morphedLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(morphedLabel)

		NSLayoutConstraint.activate(
			constrainVertically(to: label, with: .defaultHigh).constraints +
			constrainVertically(to: morphedLabel, with: .defaultHigh).constraints + [
			leadingAnchor.constraint(equalTo: label.leadingAnchor),
			leadingAnchor.constraint(equalTo: morphedLabel.leadingAnchor),
			label.firstBaselineAnchor.constraint(equalTo: morphedLabel.firstBaselineAnchor)
		])

		updateMorphed(oldValue: isMorphed)
	}
	
	func updateMorphed(oldValue: Bool) {
		guard oldValue != isMorphed else { return }
		setNeedsLayout()
		invalidateIntrinsicContentSize()
	}
	
	func updateText() {
		if label.text != text {
			label.text = text
			if !isMorphed {
				invalidateIntrinsicContentSize()
			}
		}
		if morphedLabel.text != text {
			morphedLabel.text = text
			if isMorphed {
				invalidateIntrinsicContentSize()
			}
		}
	}
	
	let label = CoreScalableLabel(textStyle: .body)
	let morphedLabel = CoreScalableLabel(textStyle: .body)
}

@available(iOS 10.0, tvOS 10.0, *)
extension MorphingLabel: UIContentSizeCategoryAdjusting {
	public var adjustsFontForContentSizeCategory: Bool {
		get { label.adjustsFontForContentSizeCategory && morphedLabel.adjustsFontForContentSizeCategory }
		set {
			label.adjustsFontForContentSizeCategory = newValue
			morphedLabel.adjustsFontForContentSizeCategory = newValue
		}
	}
}

internal extension UIView {

	var viewLayoutChain: [UIView] {
		var result = [UIView]()
		var view = self
		// Keep going until we encounter a UIScrollView, then stop
		while let parent = view.superview {
			result.append(parent)
			if parent is UIScrollView { break }
			view = parent
		}
		return result
	}
}
