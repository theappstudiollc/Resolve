//
//  CoreAPIRequestTask-Extensions.swift
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

import ResolveKit

public extension CoreAPIRequestTask {

	func performRequest(requestData: APIRequest.RequestDataType, backgroundable: Bool, completionHandler: @escaping (CoreAPIRequestTaskResult) -> Void) {
		guard backgroundable else {
			performRequest(requestData: requestData, completionHandler: completionHandler)
			return
		}
		let name = "\(self.apiRequest).\(requestData)"
		UIApplication.shared.continueTaskIfBackgrounded(withName: name, task: { timeRemaining, notifyCompletion in
//			print("Performing \(name) with \(timeRemaining)s")
			self.performRequest(requestData: requestData) { result in
				completionHandler(result)
				notifyCompletion()
			}
		}) { taskExpired in
			guard taskExpired else { return }
			print("Anticipating failure with \(name)")
		}
	}
}
