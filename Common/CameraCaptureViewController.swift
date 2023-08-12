//
//  CameraCaptureViewController.swift
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
import ResolveKit

@available(macCatalyst 14.0, *)
public final class CameraCaptureViewController: ResolveViewController {
	
	// MARK: - Interface Builder properties and methods

	@IBOutlet private var cameraView: CameraCaptureView!
	
	// MARK: - ResolveViewController overrides
	
	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		readyForCameraPreview = true
	}
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		viewStateUpdated()
	}
	
	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		readyForCameraPreview = false
	}

	// MARK: - Public properties and methods
	
	public typealias CameraCaptureCompletion = (_ imageData: Data?) -> Void
	public typealias DataCaptureEvent = (_ pixelBuffer: CVPixelBuffer) -> Void
	
	public func capturePhoto(completion: @escaping CameraCaptureCompletion) {
		assert(captureCompletion == nil, "We cannot have a captureCompletion handler already set")
		#if !targetEnvironment(macCatalyst)
		guard #available(iOS 10.0, macOS 10.15, *) else {
			guard let stillImageOutput = captureOutput as? AVCaptureStillImageOutput, let videoConnection = stillImageOutput.connection(with: .video) else {
				completion(nil)
				return
			}
			stillImageOutput.captureStillImageAsynchronously(from: videoConnection) { sampleBuffer, error in
				if let sampleBuffer = sampleBuffer, let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) {
					completion(data)
				} else {
					completion(nil)
				}
			}
			return
		}
		#endif
		guard let photoOutput = captureOutput as? AVCapturePhotoOutput else {
			completion(nil)
			return
		}
		captureCompletion = completion
		let settings = AVCapturePhotoSettings()
		#if os(iOS)
		let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
		settings.previewPhotoFormat = [
			kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
			kCVPixelBufferWidthKey as String: 480,
			kCVPixelBufferHeightKey as String: 480
		]
		#endif
		photoOutput.capturePhoto(with: settings, delegate: self)
	}
	
	public func startReadingData(dataCaptureEvent: @escaping DataCaptureEvent) {
		stopReadingData()
		self.dataCaptureEvent = dataCaptureEvent
		let videoDataOutput = AVCaptureVideoDataOutput()
		videoDataOutput.setSampleBufferDelegate(self, queue: videoDataDispatchQueue)
		dataOutput = videoDataOutput
	}
	
	public func stopReadingData() {
		dataOutput = nil
		dataCaptureEvent = nil
	}
	
	@objc public enum ViewState: Int {
		case livePreviewBack
		case livePreviewFront
		case off
	}
	
	@objc dynamic public var viewState: ViewState = .off {
		didSet { if viewState != oldValue { viewStateUpdated() } }
	}
	
	// MARK: - Private properties and methods
	
	fileprivate func callCaptureCompletion(withImageData imageData: Data?) {
		if let captureCompletion = captureCompletion {
			captureCompletion(imageData)
		}
		captureCompletion = nil
	}
	
	private var captureCompletion: CameraCaptureCompletion?
	
	private var captureOutput: AVCaptureOutput? {
		willSet {
			guard let captureOutput = captureOutput, let cameraView = cameraView else { return }
			cameraView.session.removeOutput(captureOutput)
		}
		didSet {
			guard let captureOutput = captureOutput, let cameraView = cameraView else { return }
			assert(cameraView.session.canAddOutput(captureOutput))
			cameraView.session.addOutput(captureOutput)
		}
	}
	
	private var dataCaptureEvent: DataCaptureEvent?
	
	private var dataOutput: AVCaptureOutput? {
		willSet {
			guard let dataOutput = dataOutput, let cameraView = cameraView else { return }
			cameraView.session.removeOutput(dataOutput)
		}
		didSet {
			guard let dataOutput = dataOutput, let cameraView = cameraView else { return }
			assert(cameraView.session.canAddOutput(dataOutput))
			cameraView.session.addOutput(dataOutput)
		}
	}
	
	private var readyForCameraPreview: Bool = false {
		didSet { if readyForCameraPreview != oldValue { viewStateUpdated() } }
	}
	
	private let videoDataDispatchQueue = DispatchQueue(label: "video.data.dispatch.queue")

	private func viewStateUpdated() {
		guard isViewLoaded, let cameraView = cameraView else { return }
		// Shut down any existing camera input
		for input in cameraView.session.inputs {
			cameraView.session.removeInput(input)
		}
		guard readyForCameraPreview, viewState != .off else {
			if cameraView.session.isRunning {
				cameraView.session.stopRunning()
			}
			captureOutput = nil // Shut off the output too, before returning
			return
		}
		// Now start up the desired input (and output if not already set)
		let position: AVCaptureDevice.Position = viewState == .livePreviewBack ? .back : .front
		guard let device = captureDevice(for: position) else {
			captureOutput = nil // Shut off the output too, before returning
			return
		}
		let input = try! AVCaptureDeviceInput(device: device)
		if captureOutput == nil {
			captureOutput = createCaptureOutput()
		}
		cameraView.session.addInput(input)
		#if os(iOS)
		let orientation = Application.interfaceOrientation(for: self)
		cameraView.setVideoOrientation(orientation)
		#endif
		if !cameraView.session.isRunning {
			cameraView.session.startRunning()
		}
	}
	
	private func captureDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
		// TODO: What to do in the simulator or with a device with no camera?
		#if !targetEnvironment(macCatalyst)
		guard #available(iOS 10.0, macOS 10.15, *) else {
			let devices = AVCaptureDevice.devices(for: .video)
			return devices.first(where: { $0.position == position }) ?? AVCaptureDevice.default(for: .video)
		}
		#endif
		return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
	}
	
	private func createCaptureOutput() -> AVCaptureOutput {
		#if !targetEnvironment(macCatalyst)
		guard #available(iOS 10.0, macOS 10.15, *) else {
			let stillImageOutput = AVCaptureStillImageOutput()
			stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
			return stillImageOutput
		}
		#endif
		return AVCapturePhotoOutput()
	}
}

@available(macCatalyst 14.0, *)
extension CameraCaptureViewController: AVCapturePhotoCaptureDelegate {
	
	@available(iOS 11.0, macOS 10.15, macCatalyst 14.0, *)
	public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		if let data = photo.fileDataRepresentation() {
			callCaptureCompletion(withImageData: data)
		} else {
			callCaptureCompletion(withImageData: nil)
		}
	}

	#if os(iOS) && !targetEnvironment(macCatalyst)
	@available(iOS 10.0, *)
	@available(iOS, deprecated: 11.0)
	public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
		if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
			callCaptureCompletion(withImageData: data)
		} else {
			callCaptureCompletion(withImageData: nil)
		}
	}
	#endif
}

@available(macCatalyst 14.0, *)
extension CameraCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
	
	public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
		let pixelBuffer = imageBuffer as CVPixelBuffer
		dataCaptureEvent?(pixelBuffer)
	}
}
