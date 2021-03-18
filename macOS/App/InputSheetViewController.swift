//
//  InputSheetViewController.swift
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

import Cocoa

@objc protocol InputSheetViewControllerDelegate: NSObjectProtocol {
	
	func inputSheetViewControllerDidFinish(_ inputSheetViewController: InputSheetViewController)
}

class InputSheetViewController: NSViewController {
	
	weak var delegate: InputSheetViewControllerDelegate? = nil
	@IBOutlet private weak var doneButton: NSButton!
	@IBOutlet private weak var textField: NSTextField!
	var inputText: String {
		return _inputText
	}
	
	// MARK: - NSViewController overrides
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(inputTextDidChange(_:)), name: NSControl.textDidChangeNotification, object: nil)
    }
	
	// MARK: - Private properties and methods
	
	private var _inputText: String = ""
	
	@IBAction private func doneButtonClicked(_ sender: NSButton) {
		if textField.stringValue.count > 0 {
			_inputText = textField.stringValue
		}
		delegate?.inputSheetViewControllerDidFinish(self)
	}
	
	@objc private func inputTextDidChange(_ notification: Notification) {
		if notification.object as AnyObject === textField {
			doneButton.isEnabled = textField.stringValue.count > 0
		}
	}
}
