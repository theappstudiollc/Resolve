//
//  PhotosViewController.swift
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

import AVFoundation
import Photos
import ResolveKit

@available(macOS 10.15, *)
final class PhotosViewController: ResolveViewController, PhotosCollectionViewDelegate {
	
	@Service var userInputService: UserInputService
	
	// MARK: - Interface Builder properties and methods
	
	@IBOutlet private var requestPhotosAuthorizationButton: Button!
	@IBAction private func requestPhotosAuthorizationButtonTapped(_ sender: Button) {
		if photosAuthorizationStatus == .notDetermined {
			sender.isEnabled = false
			PHPhotoLibrary.requestAuthorization { authorizationStatus in
				DispatchQueue.runInMain {
					sender.isEnabled = true
					self.photosAuthorizationStatus = authorizationStatus
				}
			}
		} else {
			#if os(iOS) || os(tvOS)
			sender.isEnabled = false
			userInputService.presentAppSettings(withTitle: "Permission Required", message: "Please grant permission to access your Photo Library in Settings", from: sender) { _ in
				sender.isEnabled = true
			}
			#else
			userInputService.presentAlert("Please grant permission to access your Photo Library in Settings", withTitle: "Permission Required", from: sender, forDuration: TimeInterval(2))
			#endif
		}
	}
	
	// MARK: - ResolveViewController overrides
	
	override func prepare(for segue: StoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if let destination = segue.destination as? PhotosCollectionViewController {
			photosCollectionViewController = destination
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		updateAuthorizationStatus()
		#if os(iOS)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationActivated(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
		#endif
	}
	
	// MARK: - Private properties and methods
	
	@objc private func applicationActivated(_ notification: Notification) {
		updateAuthorizationStatus()
	}
	
	private var photosAuthorizationStatus = PHAuthorizationStatus.notDetermined {
		didSet { if photosAuthorizationStatus != oldValue { photosAuthorizationStatusUpdated() } }
	}
	private func photosAuthorizationStatusUpdated() {
		guard isViewLoaded, let photosCollectionViewController = photosCollectionViewController else { return }
		switch photosAuthorizationStatus {
		#if swift(>=5.3) // Xcode 12.x
		case .limited:
			fallthrough // Behave just like .authorized
		#endif
		case .authorized:
			let options = PHFetchOptions()
			options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
			photosCollectionViewController.assets = PHAsset.fetchAssets(with: .image, options: options)
			requestPhotosAuthorizationButton.isHidden = true
		case .denied:
			photosCollectionViewController.assets = nil
			requestPhotosAuthorizationButton.isEnabled = true
			requestPhotosAuthorizationButton.isHidden = false
		case .notDetermined:
			requestPhotosAuthorizationButton.isEnabled = true
			requestPhotosAuthorizationButton.isHidden = false
		case .restricted: // The user will not be able to change this
			photosCollectionViewController.assets = nil
			requestPhotosAuthorizationButton.isHidden = true
		@unknown default:
			fatalError()
		}
	}
	
	private var photosCollectionViewController: PhotosCollectionViewController! {
		didSet {
			photosCollectionViewController.photosDelegate = self
			photosAuthorizationStatusUpdated()
		}
	}
	
	private func updateAuthorizationStatus() {
		photosAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
	}
	
	// MARK: - PhotosCollectionViewDelegate methods
	
	internal func photosCollectionViewController(_ viewController: PhotosCollectionViewController, didSelect asset: PHAsset, at indexPath: IndexPath) {
		print("Asset selected: \(asset)")
	}
	
	internal func photosCollectionViewController(_ viewController: PhotosCollectionViewController, didScroll to: CGFloat) {
//		print("Scrolled to \(to)")
	}
}
