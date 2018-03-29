//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import CoreData

final class Course: NSManagedObject {

    @NSManaged public var id: String
    @NSManaged public var colorString: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var name: String
    @NSManaged public var includedHomeworks: Set<Homework>
    @NSManaged public var lessons: Set<Lesson>
    @NSManaged public var teachers: Set<User>
    @NSManaged public var users: Set<User>

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Course> {
        return NSFetchRequest<Course>(entityName: "Course")
    }

}

extension Course: Pullable {

    static var type: String {
        return "courses"
    }

    func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.descriptionText = try object.value(for: "description")
        self.name = try object.value(for: "name")
        self.colorString = try object.value(for: "color")

        try self.updateRelationship(forKeyPath: \Course.teachers, forKey: "teacherIds", fromObject: object, with: context)
        try self.updateRelationship(forKeyPath: \Course.users, forKey: "userIds", fromObject: object, with: context)
    }

}
