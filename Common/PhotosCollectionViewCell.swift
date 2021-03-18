//
//  PhotosCollectionViewCell.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2017 The App Studio LLC.
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

@available(iOS 8.0, macOS 10.13, tvOS 10.0, *)
final class PhotosCollectionViewCell: CoreCollectionViewCell {
	
	// MARK: - Interface Builder properties and methods
	
	#if os(iOS) || os(tvOS)

	@IBOutlet private var imageView: ImageView!

	#endif
	
	// MARK: - CoreCollectionViewCell overrides

	override func prepareForReuse() {
		super.prepareForReuse()
		asset = nil
	}
	
	// MARK: - Public properties and methods
	
	var asset: PHAsset? {
		didSet {
			if assetRequest != PHInvalidImageRequestID {
				print("Cancelling image request: \(assetRequest)")
				PHImageManager.default().cancelImageRequest(assetRequest)
			}
			guard let asset = asset, let imageView = imageView else {
				assetRequest = PHInvalidImageRequestID
				return
			}
			#if canImport(UIKit)
			if let creationDate = asset.creationDate {
				let dateFormatter = DateFormatter()
				dateFormatter.dateStyle = .long
				dateFormatter.timeStyle = .short
				// TODO: Use localized strings for accessibility
				imageView.accessibilityHint = "Taken on \(dateFormatter.string(from: creationDate))"
			}
			#endif
			let targetSize = imageView.frame.size
			let options = PHImageRequestOptions()
			options.deliveryMode = .opportunistic
			options.isNetworkAccessAllowed = true
			assetRequest = PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] image, info in
				guard let self = self, let imageView = self.imageView, self.assetRequest != PHInvalidImageRequestID else { return }
				if let currentRequest = info?[PHImageResultRequestIDKey] as? PHImageRequestID, currentRequest != self.assetRequest {
					print("Skipping image assign because request is outdated")
				} else {
					DispatchQueue.runInMain {
						imageView.image = image
						if let imageIsDegraded = info?[PHImageResultIsDegradedKey] as? Bool, imageIsDegraded == false {
							self.assetRequest = PHInvalidImageRequestID // There will be no more images with this request
						} else {
							print("more images coming for \(self.assetRequest)")
						}
					}
				}
			}
		}
	}
	
	// MARK: Private properties and methods
	
	private var assetRequest = PHInvalidImageRequestID
	
	#if os(tvOS)

	lazy internal var focusMotionEffectGroup: UIMotionEffectGroup = {
		let horizontalAxisMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
		horizontalAxisMotionEffect.minimumRelativeValue = -8.0
		horizontalAxisMotionEffect.maximumRelativeValue = 8.0
		let verticalAxisMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
		verticalAxisMotionEffect.minimumRelativeValue = -8.0
		verticalAxisMotionEffect.maximumRelativeValue = 8.0
		let motionEffectGroup = UIMotionEffectGroup()
		motionEffectGroup.motionEffects = [horizontalAxisMotionEffect, verticalAxisMotionEffect]
		return motionEffectGroup
	}()
	
	#endif
}
