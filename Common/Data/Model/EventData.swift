//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import SyncEngine

final class EventData: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var title: String?
    @NSManaged var detail: String?
    @NSManaged var location: String?
    @NSManaged var start: Date
    @NSManaged var end: Date
    @NSManaged var course: Course?
    @NSManaged var ekIdentifier: String?

    @NSManaged var rrFrequency: String?
    @NSManaged var rrDayOfWeek: String?
    @NSManaged var rrEndDate: Date?
    @NSManaged var rrInterval: Int32

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventData> {
        return NSFetchRequest<EventData>(entityName: "EventData")
    }

}

extension EventData {

    static func isValidFrequency(remoteString: String) -> Bool {
        return ["DAILY", "WEEKLY", "MONTHLY", "YEARLY"].contains(remoteString)
    }

    static func isValidDayOfTheWeek(remoteString: String) -> Bool {
        return ["MO", "TU", "WE", "TH", "FR", "SA", "SU"].contains(remoteString)
    }

}

extension EventData: Pullable {

    static var type: String {
        return "calendar"
    }

    func update(from object: ResourceData, with context: SynchronizationContext) throws {
        let attributes = try object.value(for: "attributes") as JSON
        self.title = try attributes.value(for: "summary")
        self.detail = try attributes.value(for: "description")
        self.location = try attributes.value(for: "location")
        self.start = (try attributes.value(for: "dtstart") as Date).dateInCurrentTimeZone()
        self.end = (try attributes.value(for: "dtend") as Date).dateInCurrentTimeZone()

        try self.updateRelationship(forKeyPath: \EventData.course, forKey: "x-sc-courseid", fromObject: attributes, with: context)

        guard let included = try? object.value(for: "included") as [JSON] else { return }
        guard let recurringRuleData = included.first(where: { json in
                return (json["type"] as? String) == "rrule" && (json["id"] as? String) == "\(id)-rrule"
        }) else {
            self.rrInterval = 1
            return
        }

        let rrAttributes = try recurringRuleData.value(for: "attributes") as JSON
        let frequency = try rrAttributes.value(for: "freq") as String
        self.rrFrequency = EventData.isValidFrequency(remoteString: frequency) ? frequency : nil
        let dayOfTheWeek = try rrAttributes.value(for: "wkst") as String
        self.rrDayOfWeek = EventData.isValidDayOfTheWeek(remoteString: dayOfTheWeek) ? dayOfTheWeek : nil
        self.rrEndDate = try? rrAttributes.value(for: "until")

        if let interval = try? rrAttributes.value(for: "interval") as Int32 {
            self.rrInterval = interval > 0 ? interval : 1
        } else {
            self.rrInterval = 1
        }
    }

}
