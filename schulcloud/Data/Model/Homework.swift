//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import UIKit

final class Homework: NSManagedObject {

    @NSManaged public var id: String
    @NSManaged public var availableDate: Date
    @NSManaged public var descriptionText: String
    @NSManaged public var dueDate: Date
    @NSManaged public var isPrivate: Bool
    @NSManaged public var name: String
    @NSManaged public var publicSubmissions: Bool
    @NSManaged public var teacher: User?
    @NSManaged public var course: Course?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Homework> {
        return NSFetchRequest<Homework>(entityName: "Homework")
    }

}

extension Homework {

    static let shortDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    /// returns just the day of the due date as yyyy-MM-dd
    @objc var dueDateShort: String {
        return Homework.shortDateFormatter.string(from: self.dueDate as Date)
    }

    var courseName: String {
        return self.course?.name ?? "Persönlich"
    }

    var color: UIColor {
        if let colorString = self.course?.colorString, let color = UIColor(hexString: colorString) {
            return color
        } else {
            return UIColor.clear
        }
    }

    var cleanedDescriptionText: String {
        return self.descriptionText.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
    }

    var dueTextAndColor: (String, UIColor) {
        let highlightColor = UIColor(red: 1.0, green: 45 / 255, blue: 0.0, alpha: 1.0)
        let timeDifference = Calendar.current.dateComponents([.day, .hour], from: Date(), to: self.dueDate as Date)

        guard let dueDay = timeDifference.day, !self.publicSubmissions else {
            return ("", UIColor.clear)
        }

        switch dueDay {
        case Int.min..<0:
            return ("⚐ Überfällig", highlightColor)
        case 0:
            if let dueHour = timeDifference.hour, dueHour > 0 {
                return ("⚐ In \(dueHour) Stunden fällig", highlightColor)
            } else {
                return ("⚐ Überfällig", highlightColor)
            }
        case 1:
            return ("⚐ Morgen fällig", highlightColor)
        case 2:
            return ("Übermorgen", UIColor.black)
        case 3...7:
            return ("In \(dueDay) Tagen", UIColor.black)
        default:
            return ("", UIColor.clear)
        }
    }

    static func relativeDateString(for date: Date) -> String {
        let calendar = NSCalendar.current
        if calendar.isDateInYesterday(date) {
            return "Gestern"
        } else if calendar.isDateInToday(date) {
            return "Heute"
        } else if calendar.isDateInTomorrow(date) {
            return "Morgen"
        } else {
            return DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none)
        }
    }

}

extension Homework: Pullable {

    static var type: String {
        return "homework"
    }

    func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.availableDate = try object.value(for: "availableDate")
        self.descriptionText = try object.value(for: "description")
        self.dueDate = try object.value(for: "dueDate")
        self.isPrivate = (try? object.value(for: "private")) ?? false
        self.name = try object.value(for: "name")
        self.publicSubmissions = (try? object.value(for: "publicSubmissions")) ?? true

        try self.updateRelationship(forKeyPath: \Homework.course, forKey: "courseId", fromObject: object, with: context)
    }

}
