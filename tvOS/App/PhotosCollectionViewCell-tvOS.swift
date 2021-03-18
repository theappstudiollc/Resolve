//
//  PhotosCollectionViewCell-tvOS.swift
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

import Photos
import ResolveKit

extension PhotosCollectionViewCell {

	// MARK: - CoreCollectionViewCell overrides

	override func awakeFromNib() {
		super.awakeFromNib()
		contentView.layer.shadowColor = UIColor.black.cgColor
		contentView.layer.shadowOffset = CGSize(width: 0, height: 15)
		contentView.layer.shadowRadius = 15
		layer.cornerRadius = 8
		layer.masksToBounds = true
	}

	override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		if #available(tvOS 11.0, *) {
			if context.nextFocusedItem === self {
				coordinator.addCoordinatedFocusingAnimations({ context in
					self.applyFocusedState()
				})
			} else if context.previouslyFocusedItem === self {
				coordinator.addCoordinatedUnfocusingAnimations({ context in
					self.applyUnfocusedState()
				})
			}
		} else {
			coordinator.addCoordinatedAnimations({
				if context.nextFocusedItem === self {
					self.applyFocusedState()
				} else if context.previouslyFocusedItem === self {
					self.applyUnfocusedState()
				}
			})
		}
	}
}

extension PhotosCollectionViewCell {

	private func applyFocusedState() {
		backgroundColor = backgroundColor?.withAlphaComponent(1.0)
		contentView.layer.shadowOpacity = 0.2
		transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
		addMotionEffect(focusMotionEffectGroup)
	}

	private func applyUnfocusedState() {
		backgroundColor = backgroundColor?.withAlphaComponent(0.5)
		contentView.layer.shadowOpacity = 0
		transform = CGAffineTransform.identity
		removeMotionEffect(focusMotionEffectGroup)
	}
}
