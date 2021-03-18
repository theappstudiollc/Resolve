//
//  PhotosCollectionViewFlowLayout.swift
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

import CoreResolve
#if os(iOS) || os(tvOS)
import UIKit
typealias CollectionViewFlowLayout = UICollectionViewFlowLayout
#elseif os(macOS)
import AppKit
typealias CollectionViewFlowLayout = NSCollectionViewFlowLayout
#endif

private struct PhotosCellSizes {
	let height: CGFloat
	let widths: [CGFloat]
	
	static let `default` = PhotosCellSizes(height: 0, widths: [])
}

final class PhotosCollectionViewFlowLayout: CollectionViewFlowLayout {
	
	private var itemSizes = PhotosCellSizes.default
	
	private var minimumCellWidth: CGFloat {
		#if os(tvOS)
		return 200
		#else
		return 100
		#endif
	}

	override func prepare() {
		super.prepare()
		
		guard let collectionView = collectionView else { return }
		
		let bounds = collectionView.frame.inset(by: sectionInset)
		guard bounds.width > 0, bounds.height > 0 else { return }
		let columns = floor((bounds.width + minimumInteritemSpacing) / (minimumCellWidth + minimumInteritemSpacing))
		let itemWidth = (bounds.width - minimumInteritemSpacing * (columns - 1)) / columns
		// TODO: Let the height be "sticky" until a threshold of aspect ratio is exceeded
		let desiredSize = CGSize(width: itemWidth, height: itemWidth)
		#if os(tvOS)
		estimatedItemSize = desiredSize
		#endif
		if itemSize != desiredSize || itemSizes.widths.count != Int(columns) {
			print("Desired Size: \(desiredSize)")
			var itemWidths = [CGFloat](repeating: 0, count: Int(columns))
			itemSize = desiredSize
			var remainingWidth = bounds.width
			for itemIndex in 0..<itemWidths.count - 1 {
				// TODO: Would be nice for ceil to just bump up to the next sub-pixel
				let width = itemIndex % 2 == 0 ? floor(itemWidth) : ceil(itemWidth)
				itemWidths[itemIndex] = width
				print(" - [\(itemIndex)]: \(width)")
				remainingWidth -= width + minimumInteritemSpacing
			}
			itemWidths[itemWidths.count - 1] = remainingWidth
			print(" - [\(itemWidths.count - 1)]: \(remainingWidth)")
			itemSizes = PhotosCellSizes(height: floor(itemWidth), widths: itemWidths)
		}
	}
	
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		return collectionViewContentSize.width != newBounds.width
	}
	/*
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: itemSizes.widths[indexPath.item % itemSizes.widths.count], height: itemSizes.height)
	}
	*/
}
