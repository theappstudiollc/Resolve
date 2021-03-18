//
//  DownloadManager.swift
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

/// Handles configuration and events with the DownloadManager
@objc public protocol DownloadManagerDelegate {
	
	/// The URLSessionConfiguration to use with the DownloadManager
	///
	/// - Parameter downloadManager: The DownloadManager instance requesting configuration
	/// - Returns: The URLSessionConfiguration you wish to use for the DownloadManager's URLSession
	func configuration(forDownloadManager downloadManager: DownloadManager) -> URLSessionConfiguration
	
	/// Informs the delegate that a download from a remote URL has been saved to a local file URL
	///
	/// - Parameters:
	///   - downloadManager: The DownloadManager instance notifying the change
	///   - remoteURL: The remote URL from which the download took place
	///   - fileURL: The local file URL where the download was saved
	func downloadManager(_ downloadManager: DownloadManager, didDownload remoteURL: URL, to fileURL: URL)
	
	/// Informs the delegate that a download from a remote URL has failed
	///
	/// - Parameters:
	///   - downloadManager: The DownloadManager instance notifying the change
	///   - remoteURL: The remote URL from which the download took place
	///   - withError: The Error encountered during the download
	func downloadManager(_ downloadManager: DownloadManager, downloadTo remoteURL: URL, failed withError: Error)
	
	/// Informs the delegate that the DownloadManager's URLSession is finished handling background events
	///
	/// - Parameter downloadManager: The DownloadManager instance notifying the change
	func downloadManagerDidFinishHandlingEvents(_ downloadManager: DownloadManager)
	
	/// Informs the delegate that the DownloadManager's URLSession has become invalid
	///
	/// - Parameters:
	///   - downloadManager: The DownloadManager instance notifying the change
	///   - withError: The Error encountered which invalidated the URLSession
	@objc optional func downloadManager(_ downloadManager: DownloadManager, sessionDidBecomeInvalid withError: Error)
}

/// Manages downloads from multiple remote URLs
final public class DownloadManager: NSObject {
	
	/// The URLSession used by the DownloadManager
	public private(set) var session: URLSession!
	
	/// Re-setting the delegate will cause a new call to configuration(forDownloadManager:) You may want to do this if you've invalidated the session on purpose AND you have waited for downloadManager(_:sessionDidBecomeInvalidWithError:) to be called. NOTE: all delegate calls will be made on a private background OperationQueue with one concurrent operation only
	@objc public weak var delegate: DownloadManagerDelegate? {
		didSet {
			if let delegate = delegate {
				let configuration = delegate.configuration(forDownloadManager: self)
				session = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
			}
		}
	}
	
	/// Initiates downloads from an array of remote URLs
	///
	/// - Parameter URLs: The array of remote URLs
	public func beginDownloading(from URLs: [URL]) {
		for url in URLs {
			let allTasks = tasksToRemoteURLs.values
			guard !allTasks.contains(url) else { continue }
			let request = URLRequest(url: url)
			let task = session.dataTask(with: request)
			operationQueue.addOperation {
				self.tasksToRemoteURLs[task] = url
				task.resume()
			}
		}
	}
	
	/// Cancels an outstanding download from a remote URL
	///
	/// - Parameter URL: The remote URL whose download should cancel
	public func cancelDownload(for URL: URL) {
		if let entry = tasksToRemoteURLs.first(where: { $1 == URL }) {
			operationQueue.addOperation {
				self.tasksToRemoteURLs[entry.key] = nil
				entry.key.cancel()
			}
		}
	}
	
	deinit {
		if let session = session, session.configuration.identifier == nil {
			session.invalidateAndCancel()
		}
	}
	
	/// Forces the DownloadManager's URLSession to invalidate and cancel all outstanding tasks
	// TODO: Maybe this is not needed if we expose the URLSession
	public func forceInvalidation() {
		session.invalidateAndCancel()
	}
	
	/// Initializes a new instance with a QualityOfService queue priority
	///
	/// - Parameter qualityOfService: The QualityOfService to use for the DownloadManager's OperationQueue
	required public init(qualityOfService: QualityOfService) {
		super.init()
		operationQueue.maxConcurrentOperationCount = 1
		operationQueue.name = "\(self).operationQueue"
		operationQueue.qualityOfService = qualityOfService
	}
	
	// MARK: - Private properties and methods
	
	fileprivate let operationQueue = OperationQueue()
	
	fileprivate var tasksToRemoteURLs = [URLSessionTask : URL]()
}

// MARK: - URLSessionDataDelegate implementation

extension DownloadManager: URLSessionDataDelegate {
	
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
		tasksToRemoteURLs[downloadTask] = tasksToRemoteURLs[dataTask]
		tasksToRemoteURLs.removeValue(forKey: dataTask)
	}
	
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		// TODO: Consider the case where the response is an error. We should call the delegate method with a generated Error
		if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
			completionHandler(URLSession.ResponseDisposition.becomeDownload)
		} else {
			completionHandler(URLSession.ResponseDisposition.cancel)
		}
	}
}

// MARK: - URLSessionDelegate implementation

extension DownloadManager: URLSessionDelegate {
	
	public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
		delegate?.downloadManager?(self, sessionDidBecomeInvalid: error!)
		if self.session === session {
			self.session = nil
		}
	}
	
	#if os(iOS)
	public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
		delegate?.downloadManagerDidFinishHandlingEvents(self)
	}
	#endif
}

// MARK: - URLSessionDownloadDelegate implementation

extension DownloadManager: URLSessionDownloadDelegate {
	
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		if let remoteURL = tasksToRemoteURLs[downloadTask] {
			delegate?.downloadManager(self, didDownload: remoteURL, to: location)
		}
	}
}

// MARK: - URLSessionTaskDelegate implementation

extension DownloadManager: URLSessionTaskDelegate {
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let remoteURL = tasksToRemoteURLs.removeValue(forKey: task), let error = error {
			delegate?.downloadManager(self, downloadTo: remoteURL, failed: error)
		}
	}
}
