//
//  ResolveCollectionViewController.swift
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

open class ResolveCollectionViewController<CollectionViewType>: CoreCollectionViewController where CollectionViewType: UICollectionView {
	
	open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return self.collectionView(collectionView as! CollectionViewType, cellForItemAt: indexPath)
	}
	
	// MARK: - Required overrides
	
	open func collectionView(_ collectionView: CollectionViewType, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
		fatalError("\(type(of: self)) must implement collectionView(_:cellForItemAt:) and not call super")
	}
}

#elseif os(macOS)

open class ResolveCollectionViewController<CollectionViewType>: CoreCollectionViewController, NSCollectionViewDataSource where CollectionViewType: NSCollectionView {
    
    /// Common version of `viewDidAppear` matching UIKit. `animated` will always be false on macOS
    open func viewDidAppear(_ animated: Bool) { }
	
    /// Common version of `viewDidDisappear` matching UIKit. `animated` will always be false on macOS
    open func viewDidDisappear(_ animated: Bool) { }
	
    /// Common version of `viewWillAppear` matching UIKit. `animated` will always be false on macOS
    open func viewWillAppear(_ animated: Bool) { }
	
    /// Common version of `viewWillDisappear` matching UIKit. `animated` will always be false on macOS
    open func viewWillDisappear(_ animated: Bool) { }
	
    open override func viewDidAppear() {
        super.viewDidAppear()
        viewDidAppear(false)
    }
	
    open override func viewDidDisappear() {
        super.viewDidDisappear()
        viewDidDisappear(false)
    }
	
    open override func viewWillAppear() {
        super.viewWillAppear()
        viewWillAppear(false)
    }
	
    open override func viewWillDisappear() {
        super.viewWillDisappear()
        viewWillDisappear(false)
    }
	
	// MARK: - NSCollectionViewDataSource methods
	
	open func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
		fatalError("\(type(of: self)) must implement collectionView(_:numberOfItemsInSection:) and not call super")
	}
	
	public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		return self.collectionView(collectionView as! CollectionViewType, cellForItemAt: indexPath)
	}
	
	// MARK: - Required overrides
	
	open func collectionView(_ collectionView: CollectionViewType, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
		fatalError("\(type(of: self)) must implement collectionView(_:cellForItemAt:) and not call super")
	}
}

public extension NSCollectionView {
	
	/// The preferred mechanism is to use `CoreCellDequeuing` with a custom subclass of NSCollectionView, but in interim cases this suffices
	func dequeueReusableCell(withReuseIdentifier reuseIdentifier: String, for indexPath: IndexPath) -> NSCollectionViewItem {
		let identifier = NSUserInterfaceItemIdentifier(rawValue: reuseIdentifier)
		return makeItem(withIdentifier: identifier, for: indexPath)
	}
}

#endif
