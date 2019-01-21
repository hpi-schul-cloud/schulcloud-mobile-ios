//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import SyncEngine
import UIKit

public final class Homework: NSManagedObject {

    @NSManaged public var id: String
    @NSManaged public var availableDate: Date
    @NSManaged public var descriptionText: String
    @NSManaged public var dueDate: Date
    @NSManaged public var isPrivate: Bool
    @NSManaged public var name: String
    @NSManaged public var publicSubmissions: Bool
    @NSManaged public var teacher: User?
    @NSManaged public var course: Course?
    
    @NSManaged public var submission: Submission?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Homework> {
        return NSFetchRequest<Homework>(entityName: "Homework")
    }

}

extension Homework {

    public static let shortDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    public static var dateTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    public static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()

    public static var timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    /// returns just the day of the due date as yyyy-MM-dd
    @objc public var dueDateShort: String {
        return Homework.shortDateFormatter.string(from: self.dueDate as Date)
    }

    public var courseName: String {
        return self.course?.name ?? "Persönlich"
    }

    public var color: UIColor {
        if let colorString = self.course?.colorString, let color = UIColor(hexString: colorString) {
            return color
        } else {
            return UIColor.clear
        }
    }

}

extension Homework: Pullable {

    public static var type: String {
        return "homework"
    }

    public func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.availableDate = try object.value(for: "availableDate")
        self.descriptionText = try object.value(for: "description")
        self.dueDate = try object.value(for: "dueDate")
        self.isPrivate = (try? object.value(for: "private")) ?? false
        self.name = try object.value(for: "name")
        self.publicSubmissions = (try? object.value(for: "publicSubmissions")) ?? true

        try self.updateRelationship(forKeyPath: \Homework.course, forKey: "courseId", fromObject: object, with: context)
    }

}
