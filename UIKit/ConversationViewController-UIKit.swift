//
//  UIKitConversationViewController.swift
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

import ResolveKit

/** UIKit version of ConversationViewController. UIStoryboards will use this instead of ConversationViewController */
final class UIKitConversationViewController: ConversationViewController {
	
	// MARK: - ConversationViewController overrides
	
	override var sendButton: Button! {
		didSet {
			guard #available(iOS 10.0, tvOS 10.0, *) else { return }
			sendButton.titleLabel?.adjustsFontForContentSizeCategory = true
		}
	}
	
	override func sendButtonClicked(_ sender: Button) {
		let message = textField.trimmedText
		super.sendButtonClicked(sender)
		guard message.count > 0, #available(iOS 9.0, tvOS 9.0, *) else { return }
		setNeedsFocusUpdate()
	}
	
	override var textField: TextField! {
		didSet {
			guard #available(iOS 10.0, tvOS 10.0, *) else { return }
			textField.adjustsFontForContentSizeCategory = true
		}
	}
	
	// MARK: - UIViewController overrides
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		if let restorationIdentifier = textField.restorationIdentifier, let text = coder.decodeObject(forKey: restorationIdentifier) as? String {
			textField.text = text // UITextField only preserves the selected range, so we need to restore the text
		}
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		guard let restorationIdentifier = textField.restorationIdentifier else { return }
		coder.encode(textField.text, forKey: restorationIdentifier)
	}
	
	@available(iOS 9.0, tvOS 9.0, *)
	override var preferredFocusEnvironments: [UIFocusEnvironment] {
		if sendButton != nil && (textField.text?.count)! > 0 {
			return [sendButton, textField]
		} else {
			return [textField]
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		guard presentedViewController == nil else { return } // This works around an issue on iOS 8
		#if os(iOS)
			UIApplication.shared.isIdleTimerDisabled = true
			textField.becomeFirstResponder()
		#endif
		if UIApplication.shared.applicationState == .active {
			startConversationConnection()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(applicationActivated(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
//		guard #available(iOS 10.0, tvOS 10.0, *) else { return }
//		restoresFocusAfterTransition = false
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		#if os(iOS)
			UIApplication.shared.isIdleTimerDisabled = false
//			if isBeingDismissed || isMovingFromParentViewController {
				textField.resignFirstResponder() // iOS is not handling this properly when Settings is being presented
//			}
		#endif
	}
	
	// MARK: - Private methods
	
	@objc private func applicationActivated(_ notification: Notification) {
		startConversationConnection()
	}
}

extension UIKitConversationViewController: UITextFieldDelegate {
	
	internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let message = textField.trimmedText
		if message.count > 0 {
			sendMessageToAllPeers(message)
			textField.text = ""
			if #available(iOS 9.0, tvOS 9.0, *) {
				setNeedsFocusUpdate()
			}
			return true
		}
		return false
	}
}
