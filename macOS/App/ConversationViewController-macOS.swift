//
//  ConversationViewController-macOS.swift
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
import ResolveKit
import Foundation

extension ConversationViewController {
	
	// MARK: - NSViewController overrides
	
	override func viewDidAppear() {
		super.viewDidAppear()
		startConversationConnection()
	}
}

extension ConversationViewController: InputSheetViewControllerDelegate {
	
	func inputSheetViewControllerDidFinish(_ inputSheetViewController: InputSheetViewController) {
		if inputSheetViewController.inputText.count > 0 {
			settingsService.peerID = MCPeerID(displayName: inputSheetViewController.inputText)
		}
		dismiss(inputSheetViewController)
		startConversationConnection()
	}
}
