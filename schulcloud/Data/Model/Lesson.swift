//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation

final class Lesson: NSManagedObject {

    @NSManaged public var id: String
    @NSManaged public var name: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var date: Date
    @NSManaged public var contents: Set<LessonContent>
    @NSManaged public var course: Course?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Lesson> {
        return NSFetchRequest<Lesson>(entityName: "Lesson")
    }

}

extension Lesson: Pullable {

    static var type: String {
        return "lessons"
    }

    func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.name = try object.value(for: "name")
        self.descriptionText = try object.value(for: "descriptionText")
        self.date = try object.value(for: "date")

        try self.updateRelationship(forKeyPath: \Lesson.course, forKey: "courseId", fromObject: object, with: context)
        try self.updateRelationship(forKeyPath: \Lesson.contents, forKey: "contents", fromObject: object, with: context)
    }

}
