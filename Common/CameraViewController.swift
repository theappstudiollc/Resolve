//
//  CameraViewController.swift
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

import AVFoundation
import ResolveKit

@available(macCatalyst 14.0, *)
class CameraViewController: ResolveViewController {
	
	@Service var fileService: CoreFileStoreService
	@Service var notificationManager: NotificationService
	@Service var userInputService: UserInputService
	
	// MARK: - Interface Builder properties and methods
	
	@IBOutlet internal var cameraCaptureViewController: CameraCaptureViewController! {
		didSet {
			cameraCaptureViewObservation = cameraCaptureViewController!.observe(\.viewState, options: [.new]) { [weak self] viewState, observedChange in
				guard let self = self, self.isViewLoaded else { return }
				self.updateSelectedImageView()
			}
			cameraAuthorizationStatusUpdated()
		}
	}
	
	@IBOutlet private var photoButton: Button!

	@IBAction private func photoButtonTapped(_ sender: Button) {
		guard captureInProgress == false else { return }
		guard selectedImageData == nil else {
			selectedImageData = nil
			return
		}
		sender.isEnabled = false
		selectedImageData = nil
		capturePhoto {
			sender.isEnabled = true
		}
	}
	
	@IBOutlet private var requestCameraAuthorizationButton: Button!
	
	@available(macOS 10.14, *)
	@IBAction private func requestCameraAuthorizationButtonTapped(_ sender: Button) {
		if cameraAuthorizationStatus == .notDetermined {
			sender.isEnabled = false
			AVCaptureDevice.requestAccess(for: .video) { (accessGranted: Bool) in
				DispatchQueue.runInMain {
					sender.isEnabled = true
					if accessGranted {
						self.cameraAuthorizationStatus = .authorized
					}
				}
			}
		} else if cameraAuthorizationStatus != .authorized {
			#if os(iOS)
			sender.isEnabled = false
			userInputService.presentAppSettings(withTitle: "Permission Required", message: "Please grant permission to access your Photo Library in Settings", from: sender) { _ in
				sender.isEnabled = true
			}
			#else
			userInputService.presentAlert("Please grant permission to access the camera in Settings", withTitle: "Permission Required", from: sender, forDuration: TimeInterval(2))
			#endif
		}
	}
	
	@IBOutlet private var selectedImageView: ImageView!

	// MARK: - Public methods

	public func capturePhoto(_ completion: (() -> Void)?) {
		captureInProgress = true
		// Blank the screen so that the user knows a capture is in progress
		selectedImageView.image = nil
		selectedImageView.alpha = 1
		selectedImageView.backgroundColor = .black
		cameraCaptureViewController.capturePhoto() { imageData in
			DispatchQueue.main.async {
				self.captureInProgress = false
				self.selectedImageData = imageData
				DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(2)) {
					self.selectedImageData = nil
				}
				completion?()
			}
			if let jpegImageData = imageData {
				try? self.saveJpegImageData(jpegImageData)
			}
		}
	}

	// MARK: - ResolveViewController overrides

	deinit {
		cameraCaptureViewObservation?.invalidate()
	}
	
	override func prepare(for segue: StoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		switch segue.destination {
		case let cameraCaptureViewController as CameraCaptureViewController:
			self.cameraCaptureViewController = cameraCaptureViewController
		default:
			break
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		try? setupCaptureUrl()
		updateAuthorizationStatus()
    }

	// MARK: - Private properties and methods
	
	private var _cameraAuthorizationStatus: Int = 0
	@available(macOS 10.14, macCatalyst 14.0, *)
	private var cameraAuthorizationStatus: AVAuthorizationStatus {
		get { return AVAuthorizationStatus(rawValue: _cameraAuthorizationStatus)! }
		set {
			guard _cameraAuthorizationStatus != newValue.rawValue else { return }
			_cameraAuthorizationStatus = newValue.rawValue
			cameraAuthorizationStatusUpdated()
		}
	}
	
	private func cameraAuthorizationStatusUpdated() {
		guard isViewLoaded, let cameraCaptureViewController = cameraCaptureViewController else { return }
		guard #available(macOS 10.14, *) else {
			// This version of macOS does not support camera authorization
			cameraCaptureViewController.viewState = .livePreviewFront
			requestCameraAuthorizationButton.isHidden = true
			return
		}
		switch cameraAuthorizationStatus {
		case .authorized:
			cameraCaptureViewController.viewState = .livePreviewFront
			requestCameraAuthorizationButton.isHidden = true
		case .denied, .restricted, .notDetermined:
			cameraCaptureViewController.viewState = .off
			requestCameraAuthorizationButton.isEnabled = true
			requestCameraAuthorizationButton.isHidden = false
		@unknown default:
			fatalError()
		}
		photoButton.isHidden = !requestCameraAuthorizationButton.isHidden
	}
	
	private var cameraCaptureViewObservation: NSKeyValueObservation?
	private var captureInProgress = false
	private var captureUrl: URL!

	private func updateSelectedImageView() {
		guard selectedImageView != nil, cameraCaptureViewController != nil else { return }
		
		// TODO: We should pause the camera session (the code below can freeze)
//		if selectedImageData == nil, viewState != .off {
//			if !cameraView.session.isRunning {
//				cameraView.session.startRunning()
//			}
//		} else {
//			if cameraView.session.isRunning {
//				cameraView.session.stopRunning()
//			}
//		}
		
		let image = selectedImageData == nil ? nil : Image(data: selectedImageData!)
		#if os(iOS)
		UIView.transition(with: selectedImageView, duration: 0.15, options: .transitionCrossDissolve, animations: {
			self.selectedImageView.alpha = image == nil ? 0 : 1
			self.selectedImageView.image = image
		})
		#elseif os(macOS)
		NSAnimationContext.runAnimationGroup({ context in
			context.duration = 0.15
			self.selectedImageView.animator().alphaValue = image == nil ? 0 : 1
			self.selectedImageView.animator().image = image
		})
		#endif
	}
	
	private func saveJpegImageData(_ imageData: Data) throws {
		let fileName = "\(NSUUID().uuidString).jpg"
		let fileUrl = captureUrl.appendingPathComponent(fileName, isDirectory: false)
		try imageData.write(to: fileUrl, options: .withoutOverwriting)
	}
	
	public var selectedImageData: Data? {
		didSet { updateSelectedImageView() }
	}
	
	private func setupCaptureUrl() throws {
		let documentsUrl = try fileService.directoryUrl(for: .documents)
		try fileService.ensureDirectoryExists(for: .documents, withSubpath: "Experiments")
		captureUrl = documentsUrl.appendingPathComponent("Experiments", isDirectory: true)
	}
	
	internal func switchOff(for duration: TimeInterval) {
		photoButton.isEnabled = false
		cameraCaptureViewController.viewState = .off
		DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
			self.photoButton.isEnabled = true
			self.cameraCaptureViewController.viewState = .livePreviewFront
		}
	}

	internal func switchOn(for duration: TimeInterval) {
		photoButton.isEnabled = true
		cameraCaptureViewController.viewState = .livePreviewFront
		DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
			self.photoButton.isEnabled = false
			self.cameraCaptureViewController.viewState = .off
		}
	}
	
	internal var syncQueue = DispatchQueue(label: "\(CameraViewController.self).syncQueue", attributes: .concurrent)

	private func updateAuthorizationStatus() {
		guard #available(macOS 10.14, *) else { return }
		cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
	}
}
