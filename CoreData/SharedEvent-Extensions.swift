//
//  SharedEvent-Extensions.swift
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2019 The App Studio LLC.
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

import CoreData

public extension SharedEvent {

	enum GroupByBehavior {
		case live(cutoffInterval: TimeInterval?)
		case referenceDate(_ referenceDate: Date, cutoffInterval: TimeInterval?)
	}

	private class var groupByBehaviorKey: String {
		return "groupByBehavior"
	}

	class func clearGroupBy(in context: NSManagedObjectContext) {
		context.userInfo.removeObject(forKey: groupByBehaviorKey)
	}

	class func setGroupByBehavior(_ behavior: GroupByBehavior, in context: NSManagedObjectContext) {
		context.userInfo[groupByBehaviorKey] = behavior
	}

	@objc dynamic var groupNameByTime: String {

		// Use strings and stringsdict to display the name
		let bundle = Bundle(for: Self.self)
		let tableName = "\(Self.self)"

		guard let createdDate = createdLocallyAt, let groupByBehavior = managedObjectContext?.userInfo[SharedEvent.groupByBehaviorKey] as? GroupByBehavior else {
			return NSLocalizedString("unknown", tableName: tableName, bundle: bundle, comment: "UNKNOWN")
		}
		let referenceDate = groupByBehavior.referenceDate
		if let cutoffInterval = groupByBehavior.cutoffInterval {
			let cutoffDate = Date(timeInterval: cutoffInterval, since: referenceDate)
			guard createdDate >= cutoffDate else {
				return NSLocalizedString("older", tableName: tableName, bundle: bundle, comment: "OLDER")
			}
		}

		let desiredComponents: Set<Calendar.Component> = [.minute, .hour, .day]
		let diff = Calendar.current.dateComponents(desiredComponents, from: createdDate, to: referenceDate)
		
		if let day = diff.day, day > 0 {
			let format = NSLocalizedString("days_ago", tableName: tableName, bundle: bundle, comment: "n days ago")
			return String.localizedStringWithFormat(format, day)
		}
		if let hour = diff.hour, hour > 0 {
			let format = NSLocalizedString("hours_ago", tableName: tableName, bundle: bundle, comment: "n hours ago")
			return String.localizedStringWithFormat(format, hour)
		}
		if let minute = diff.minute, minute > 0 {
			let format = NSLocalizedString("minutes_ago", tableName: tableName, bundle: bundle, comment: "n minutes ago")
			return String.localizedStringWithFormat(format, minute)
		}
		return NSLocalizedString("under_a_minute", tableName: tableName, bundle: bundle, comment: "less than 1 minute ago")
	}

	override func awakeFromFetch() {
		super.awakeFromFetch()
		setupGroupNameByTimeTrigger()
	}

	override func awakeFromInsert() {
		super.awakeFromInsert()
		setupGroupNameByTimeTrigger()
	}

	func setupGroupNameByTimeTrigger() {
		guard let managedObjectContext = managedObjectContext, managedObjectContext.concurrencyType == .mainQueueConcurrencyType else {
			return
		}
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(groupNameByTimeTrigger(_:)), object: nil)
		guard let groupByBehavior = managedObjectContext.userInfo[SharedEvent.groupByBehaviorKey] as? GroupByBehavior, case .live = groupByBehavior else {
			return
		}
		guard let timeInterval = timeIntervalForNextGroupName(groupByBehavior: groupByBehavior) else { return }
		print("Setting refresh in \(timeInterval)s in '\(groupNameByTime)' for \(createdByDevice!) - \(createdLocallyAt!) on \(Date(timeIntervalSinceNow: timeInterval))")
		perform(#selector(groupNameByTimeTrigger(_:)), with: nil, afterDelay: timeInterval)
	}

	@objc func groupNameByTimeTrigger(_ sender: Any?) {
		guard managedObjectContext != nil else { return }
		NotificationCenter.default.post(name: .sharedEventGroupChanged, object: self)
	}

	func timeIntervalForNextGroupName(groupByBehavior: GroupByBehavior) -> TimeInterval? {
		// This access to `createdLocallyAt` can cause a fetch, which we want (but why?)
		guard let createdDate = createdLocallyAt else {
			return nil
		}
		let referenceDate = groupByBehavior.referenceDate
		if let cutoffInterval = groupByBehavior.cutoffInterval {
			let cutoffDate = Date(timeInterval: cutoffInterval, since: referenceDate)
			guard createdDate >= cutoffDate else {
				return nil
			}
		}

		let desiredComponents: Set<Calendar.Component> = [.minute, .hour, .day]
		let diff = Calendar.current.dateComponents(desiredComponents, from: createdDate, to: referenceDate)

		let next: Date?
		if let day = diff.day, day > 0 {
			next = Calendar.current.date(byAdding: .day, value: day + 1, to: createdDate)
		} else if let hour = diff.hour, hour > 0 {
			next = Calendar.current.date(byAdding: .hour, value: hour + 1, to: createdDate)
		} else if let minute = diff.minute {
			next = Calendar.current.date(byAdding: .minute, value: minute + 1, to: createdDate)
		} else {
			next = nil
		}
		guard let result = next else {
			return nil
		}
		return result.timeIntervalSince(referenceDate)
	}
}

public extension Notification.Name {

	static let sharedEventGroupChanged = Notification.Name("kSharedEventGroupChanged")
}

fileprivate extension SharedEvent.GroupByBehavior {

	var cutoffInterval: TimeInterval? {
		switch self {
		case .live(let cutoffInterval):
			return cutoffInterval
		case .referenceDate(_, let cutoffInterval):
			return cutoffInterval
		}
	}

	var referenceDate: Date {
		switch self {
		case .live:
			return Date()
		case .referenceDate(let date, _):
			return date
		}
	}
}
