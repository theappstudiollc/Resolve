//
//  UserInputManager.swift
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

final class UserInputManager: NSObject, UserInputService, MCBrowserViewControllerDelegate, UITextFieldDelegate {
	
	private let bonjourServiceType: String
	private var browserViewController: MCBrowserViewController?
	private weak var enterAction: UIAlertAction?
	private let urlOpening: URLOpening!

	deinit {
		print("\(self) deinit")
	}
	
	required init(multipeerSettings: MultipeerSettingsService, urlOpening: URLOpening = UIApplication.shared) {
		self.bonjourServiceType = multipeerSettings.bonjourServiceType
		self.urlOpening = urlOpening
		super.init()
	}

	// MARK: MCBrowserViewControllerDelegate methods
	
	func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
		self.browserViewController = nil
		browserViewController.presentingViewController?.dismiss(animated: true, completion: nil)
	}
	
	func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
		self.browserViewController = nil
		browserViewController.presentingViewController?.dismiss(animated: true) {
			let session = browserViewController.session
			if session.connectedPeers.count == 0 {
//				self.presentBrowser(for: session)
			}
		}
	}
	
	// MARK: UITextFieldDelegate methods
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if let text = textField.text {
			enterAction?.isEnabled = text.count > 0 && text.count < 255
		}
		return true
	}

	// MARK: UserInputService methods
	
	func presentAlert(_ alert: String, withTitle title: String?, from presenter: DialogPresenter, forDuration duration: TimeInterval) {
		guard Thread.isMainThread else {
			DispatchQueue.main.async {
				self.presentAlert(alert, withTitle: title, from: presenter, forDuration: duration)
			}
			return
		}
		let presentIn = { (presentingViewController: UIViewController) in
			let alertController = UIAlertController(title: title ?? "Alert", message: alert, preferredStyle: .alert)
			if UIAccessibility.isVoiceOverRunning {
				_ = NotificationCenter.default.listen(forName: UIAccessibility.announcementDidFinishNotification) { (_ notification: Notification, _ stopListening: () -> Void) in
					guard let userInfo = notification.userInfo,
						let announcement = userInfo[UIAccessibility.announcementStringValueUserInfoKey] as? String,
						let didFinish = userInfo[UIAccessibility.announcementWasSuccessfulUserInfoKey] as? Bool else { return }
					print("displaySuccessful: \(didFinish)")
					if announcement == alert {
						stopListening()
						if didFinish {
							presentingViewController.dismiss(animated: true)
						} else {
							alertController.addAction(UIAlertAction(title: "Dismiss Alert", style: .default))
						}
					} else {
						print("announcement: \(announcement)")
					}
				}
			}
			presentingViewController.present(alertController, animated: true) {
				UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: alert)
				guard !UIAccessibility.isVoiceOverRunning else { return }
				DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
					if presentingViewController.presentedViewController === alertController && !alertController.isBeingDismissed {
						presentingViewController.dismiss(animated: true)
					}
				}
			}
		}
		let presentingViewController = self.presentingViewController(for: presenter)
		if let presentedViewController = presentingViewController.presentedViewController {
			if presentedViewController is UIAlertController {
				presentingViewController.dismiss(animated: true) {
					presentIn(presentingViewController)
				}
			} else {
				presentIn(presentedViewController)
			}
		} else {
			presentIn(presentingViewController)
		}
	}
	
	func presentAppSettings(withTitle title: String, message: String, from presenter: DialogPresenter, decisionHandler: ((Bool) -> Void)?) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		#if targetEnvironment(macCatalyst)
		alertController.addAction(UIAlertAction(title: "OK", style: .cancel) { (action: UIAlertAction) in
			decisionHandler?(false)
		})
		#else
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action: UIAlertAction) in
			decisionHandler?(false)
		})
		alertController.addAction(UIAlertAction(title: "Settings", style: .default) { (action: UIAlertAction) in
			if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
				if #available(iOS 10.0, tvOS 10.0, *) {
					self.urlOpening.open(url, options: [:]) {
						decisionHandler?($0)
					}
				} else {
					#if os(iOS)
					let openedSettings = self.urlOpening.openURL(url)
					decisionHandler?(openedSettings)
					#endif
				}
			} else {
				decisionHandler?(false)
			}
		})
		#endif
		var presentingViewController = self.presentingViewController(for: presenter)
		if presentingViewController.presentedViewController != nil {
			presentingViewController = presentingViewController.presentedViewController!
		}
		presentingViewController.present(alertController, animated: true, completion: nil)
	}
	
	func presentSaveConfirmation(withTitle title: String?, message: String?, from presenter: DialogPresenter, decisionHandler: @escaping (_ result: UserInputSaveConfirmationResult) -> Void) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
		alertController.addAction(UIAlertAction(title: "Save", style: .default) { _ in
			decisionHandler(.save)
		})
		alertController.addAction(UIAlertAction(title: "Discard Changes", style: .destructive) { _ in
			decisionHandler(.discard)
		})
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
			decisionHandler(.cancel)
		})
		var presentingViewController = self.presentingViewController(for: presenter)
		while presentingViewController.presentedViewController != nil {
			presentingViewController = presentingViewController.presentedViewController!
		}
		presentingViewController.present(alertController, animated: true, completion: nil)
	}
	
	func presentBrowser(for session: MCSession, from presenter: DialogPresenter) {
		let presentBlock = { [bonjourServiceType] in
			self.browserViewController = MCBrowserViewController(serviceType: bonjourServiceType, session: session)
			self.browserViewController?.delegate = self
			var presentingViewController = self.presentingViewController(for: presenter)
			if presentingViewController.presentedViewController != nil {
				presentingViewController = presentingViewController.presentedViewController!
			}
			presentingViewController.present(self.browserViewController!, animated: true, completion: nil)
		}
		if browserViewController == nil {
			presentBlock()
		} else {
			browserViewController?.presentingViewController?.dismiss(animated: true, completion: presentBlock)
		}
	}
	
	func presentTextInputAlert(withTitle title: String, message: String, from presenter: DialogPresenter, completionHandler: @escaping (String?) -> Void) {
		let inputController = UIAlertController(title: "Name Required", message: "Enter a name for this device so that other people may recognize you", preferredStyle: .alert)
		inputController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action: UIAlertAction) in
			completionHandler(nil)
		})
		let action = UIAlertAction(title: "Enter", style: .default) { (action: UIAlertAction) in
			let textField = inputController.textFields?.first
			completionHandler(textField?.text)
		}
		inputController.addAction(action)
		enterAction = action
		weak var weakSelf = self
		inputController.addTextField { (textField: UITextField) in
			let strongSelf = weakSelf
			textField.text = UIDevice.current.name
			textField.delegate = strongSelf
		}
		var presentingViewController = self.presentingViewController(for: presenter)
		if presentingViewController.presentedViewController != nil {
			presentingViewController = presentingViewController.presentedViewController!
		}
		presentingViewController.present(inputController, animated: true, completion: nil)
	}

	func presentingViewController(for presenter: DialogPresenter) -> UIViewController {
		guard let result = presenter.findResponder(as: UIViewController.self) else {
			// This should never happen
			return Application.rootViewController(for: presenter)!
		}
		return result
	}
}
