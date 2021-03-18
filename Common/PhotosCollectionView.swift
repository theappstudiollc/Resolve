//
//  PhotosCollectionView.swift
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

import ResolveKit

@available(iOS 8.0, macOS 10.13, tvOS 10.0, *)
final class PhotosCollectionView: CollectionView {
	
	// MARK: - CollectionView overrides
	
	#if os(macOS)
	
	override func awakeFromNib() {
		super.awakeFromNib()
		let identifier = "\(PhotosCollectionViewCell.self)"
		let nib = NSNib(nibNamed: identifier, bundle: .main)!
		register(nib, forItemWith: .photosCollectionViewCell)
	}
	
	#endif
}

@available(iOS 8.0, macOS 10.13, tvOS 10.0, *)
extension PhotosCollectionView: CoreCellDequeuing {
	
	public enum CellIdentifier: String {
		case photosCollectionViewCell
	}
}
