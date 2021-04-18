//
//  CameraCaptureView.swift
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

public final class CameraCaptureView: View {
	
	// MARK: - View overrides
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		setupView()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupView()
	}
	
	#if os(iOS)

	public override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}
	
	#endif
	
	// MARK: - Public properties and methods

	public private(set) var session = AVCaptureSession()
	
	// MARK: - Private properties and methods
	
	private var videoLayer: AVCaptureVideoPreviewLayer {
		return self.layer as! AVCaptureVideoPreviewLayer
	}
	
	private func setupView() {
		session.sessionPreset = .photo
		#if os(macOS)
		self.layer = AVCaptureVideoPreviewLayer(session: session)
		#else
		videoLayer.session = session
		#endif
		videoLayer.videoGravity = .resizeAspectFill
	}
}

#if os(iOS)

extension CameraCaptureView {

	func setVideoOrientation(_ videoOrientation: UIInterfaceOrientation) {
		guard let connection = videoLayer.connection, connection.isVideoOrientationSupported else { return }
		switch videoOrientation {
		case .landscapeLeft: connection.videoOrientation = .landscapeLeft
		case .landscapeRight: connection.videoOrientation = .landscapeRight
		case .portrait: connection.videoOrientation = .portrait
		case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
		default: break
		}
	}
}

#endif
