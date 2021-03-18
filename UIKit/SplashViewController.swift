//
//  SplashViewController.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2016 The App Studio LLC.
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

final class SplashViewController: CoreViewController {
	
	// MARK: - Interface Builder properties and methods
	
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var videoPlayerView: VideoPlayerView!
	
	// MARK: - CoreViewController overrides
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		performSegueDispatchGroup.leave()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		setupSegue(processCount: 1)
		setupSplashVideo()
    }
	
	// MARK: - Private properties
	
	private let performSegueDispatchGroup = DispatchGroup()

	// MARK: - Private methods
	
	private func leaveSplash() {
		// Only proceed if the SplashViewController is still the active View Controller
		let rootViewController = Application.rootViewController(for: self)!
		guard rootViewController.activeChild === self else {
			return
		}
		performSegue(withIdentifier: .leaveSplash, sender: self)
	}
	
	private func setupSplashVideo() {
		activityIndicator.startAnimating()
		if let url = Bundle.main.url(forResource: "intro", withExtension: "mov") {
			videoPlayerView.videoUrl = url
		} else {
			DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
				self.performSegueDispatchGroup.leave()
			}
		}
	}
	
	private func setupSegue(processCount: Int) {
		performSegueDispatchGroup.enter()
		for _ in 0..<processCount {
			performSegueDispatchGroup.enter()
		}
		performSegueDispatchGroup.notify(queue: .main) { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.activityIndicator.stopAnimating()
			strongSelf.leaveSplash()
		}
	}
}

extension SplashViewController: VideoPlayerViewDelegate {
	
	func videoPlayerViewReady(_ videoPlayerView: VideoPlayerView) {
		guard activityIndicator.isAnimating else { return }
		activityIndicator.stopAnimating()
		UIView.animate(withDuration: 0.2, animations: {
			videoPlayerView.alpha = 1
		}) { completed in
			if UIApplication.shared.applicationState == .active {
				videoPlayerView.play()
			} else {
				self.performSegueDispatchGroup.leave()
			}
		}
	}
	
	func videoPlayerView(_ videoPlayerView: VideoPlayerView, encountered error: Error) {
		performSegueDispatchGroup.leave()
	}
	
	func videoPlayerViewDidFinishPlaying(_ videoPlayerView: VideoPlayerView) {
		performSegueDispatchGroup.leave()
	}
}

extension SplashViewController: CoreSegueHandling {
	
	internal enum SegueIdentifier: String, CaseIterable {
		case leaveSplash
	}
}
