//
//  CameraMLViewController.swift
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

import AVFoundation
import CoreML
import ResolveKit
import Vision

@available(iOS 11.0, macOS 10.13, macCatalyst 14.0, *)
final class CameraMLViewController: CameraViewController {

	// MARK: - CameraViewController overrides

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
//		startAutoTimer()
		startCapture()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		setupImageClassifier()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		stopCapture()
	}

	// MARK: - Private properties and methods

	private var analysisImageOrientation: CGImagePropertyOrientation = .up
	private var analysisPixelBuffer: CVPixelBuffer?
	private var analysisQueue = DispatchQueue(label: "analysis.queue")
	private var analysisRequests = [VNRequest]()

	private var _captureDate: Date?
	private var captureDate: Date? {
		get { return syncQueue.sync { _captureDate } }
		set { syncQueue.sync(flags: .barrier) { _captureDate = newValue } }
	}
	private var captureTimer: Timer!

	private var _lastRecognizedIdentifier: String? = nil
	private var lastRecognizedIdentifier: String? {
		get { return syncQueue.sync { _lastRecognizedIdentifier } }
		set { syncQueue.sync(flags: .barrier) { _lastRecognizedIdentifier = newValue } }
	}

	private func notifyBadBehavior() {
		notificationManager.notify(withMessage: "Hands on the keyboard please", nil)
	}

	private func observedIdentifier(from observations: [VNClassificationObservation]) -> String {
//		print("Checking observations: \(observations)")
		let goodObservation = observations.first(where: { $0.identifier == "good.behavior" })!
		let badObservation = observations.first(where: { $0.identifier == "bad.behavior" })!
		if let firstObservation = observations.first, firstObservation.confidence > 0.85,
		   firstObservation.identifier != "bad.behavior" {
			print("Choosing \(firstObservation.identifier) \(firstObservation.confidence)")
			return firstObservation.identifier
		}
		// Lets really be sure whether we want to use "bad.behavior"
		if badObservation.confidence > 0.92 {
			print("Choosing \(badObservation.identifier) \(badObservation.confidence)")
			return badObservation.identifier
		}
//		print("Testing: \(badObservation.confidence / goodObservation.confidence) vs \(badObservation.confidence - goodObservation.confidence)")
//		if badObservation.confidence / goodObservation.confidence > 8 {
//			print("Choosing(1) \(badObservation.identifier): \(badObservation.confidence / goodObservation.confidence)")
//			return badObservation.identifier
//		}
		if badObservation.confidence - goodObservation.confidence > 0.6 {
			print("Choosing(2) \(badObservation.identifier): \(badObservation.confidence - goodObservation.confidence)")
			return badObservation.identifier
		}
		print("Choosing(3) \(goodObservation)")
		return goodObservation.identifier
	}

	private func setupImageClassifier() {
		guard let modelUrl = Bundle.main.url(forResource: "Habits", withExtension: "mlmodelc"), let model = try? VNCoreMLModel(for: MLModel(contentsOf: modelUrl)) else {
			return
		}
		let request = VNCoreMLRequest(model: model) { request, error in
			guard error == nil else {
				print("request error: \(error!)")
				return
			}
			guard let results = request.results as? [VNClassificationObservation] else { return }

			let identifiedBehavior = self.observedIdentifier(from: results)
			guard self.lastRecognizedIdentifier == identifiedBehavior else {
				self.captureDate = Date(timeIntervalSinceNow: 2)
				self.lastRecognizedIdentifier = identifiedBehavior
				return
			}

			switch identifiedBehavior {
			case "bad.behavior":
				self.captureDate = Date(timeIntervalSinceNow: 5)
				self.lastRecognizedIdentifier = nil
				DispatchQueue.main.async {
					self.notifyBadBehavior()
				}
			case "good.behavior":
				self.captureDate = Date(timeIntervalSinceNow: 2)
			case "no.behavior":
				let seconds: Double = 30
				self.captureDate = Date(timeIntervalSinceNow: seconds - 1)
				self.lastRecognizedIdentifier = nil
				#if os(macOS)
					DispatchQueue.main.async {
//						self.switchOff(for: TimeInterval(seconds))
					}
				#endif
			default:
				self.captureDate = Date(timeIntervalSinceNow: 1)
			}
		}
		analysisRequests.append(request)
	}

	private func startAutoTimer() {
		if captureTimer == nil {
//			switchOn(for: TimeInterval(4))
			captureTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(20), repeats: true) { timer in
//				self.switchOn(for: TimeInterval(4))
				self.capturePhoto(nil)
			}
		}
	}

	private func startCapture() {
		guard analysisRequests.count > 0 else { return }
		captureDate = Date()
		cameraCaptureViewController.startReadingData { [userInputService] pixelBuffer in
			guard self.analysisPixelBuffer == nil else { return } // Skip this reading
			guard let captureDate = self.captureDate, captureDate < Date() else { return }
			self.captureDate = nil
			self.analysisPixelBuffer = pixelBuffer
			let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: self.analysisImageOrientation)
			self.analysisQueue.async {
				do {
					defer { self.analysisPixelBuffer = nil }
					try requestHandler.perform(self.analysisRequests)
				} catch {
					userInputService.presentAlert(error.localizedDescription, withTitle: "Analysis Error", from: self, forDuration: 2.0)
				}
			}
		}
	}

	private func stopCapture() {
		cameraCaptureViewController.stopReadingData()
		captureTimer?.invalidate()
	}
}
