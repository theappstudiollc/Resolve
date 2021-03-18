//
//  PhotosCollectionViewController.swift
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

@available(macOS 10.13, *)
protocol PhotosCollectionViewDelegate: class {
	
	func photosCollectionViewController(_ viewController: PhotosCollectionViewController, didScroll to: CGFloat)
	
	func photosCollectionViewController(_ viewController: PhotosCollectionViewController, didSelect asset: PHAsset, at indexPath: IndexPath)
}

@available(macOS 10.13, *)
final class PhotosCollectionViewController: ResolveCollectionViewController<PhotosCollectionView> {
	
	// MARK: - Public properties and methods
	
	var assets: PHFetchResult<PHAsset>? {
		didSet {
			guard isViewLoaded, let collectionView = collectionView else { return }
			collectionView.reloadData()
		}
	}
	
	weak var photosDelegate: PhotosCollectionViewDelegate?
	
	// MARK: - Private properties and methods
	
	private var canNilAssets = false
	
	// MARK: - ResolveCollectionViewController overrides
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		canNilAssets = true
	}
	
	override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
		return assets?.count ?? 0
	}
	
	override func collectionView(_ collectionView: PhotosCollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
		let cell: PhotosCollectionViewCell = collectionView.dequeueReusableCell(withIdentifier: .photosCollectionViewCell, for: indexPath)
		cell.asset = assets![indexPath.item]
		return cell
	}
	
	#if os(iOS)
	
	// MARK: - UICollectionViewDelegate methods

	override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		guard canNilAssets, let cell = cell as? PhotosCollectionViewCell else { return }
		cell.asset = nil // This causes problems during UI State Restoration, so check canNilAssets
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		photosDelegate?.photosCollectionViewController(self, didSelect: assets![indexPath.item], at: indexPath)
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		photosDelegate?.photosCollectionViewController(self, didScroll: scrollView.contentOffset.y)
	}
	
	#elseif os(tvOS)
	
	override func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
		return true
	}
	
	#endif
}
