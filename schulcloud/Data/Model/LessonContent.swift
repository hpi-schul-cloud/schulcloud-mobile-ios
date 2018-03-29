//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation

final class LessonContent: NSManagedObject {

    @NSManaged public var id: String
    @NSManaged public var component: String?
    @NSManaged public var title: String?
    @NSManaged public var text: String?
    @NSManaged public var hidden: Bool
    @NSManaged public var lesson: Lesson?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LessonContent> {
        return NSFetchRequest<LessonContent>(entityName: "LessonContent")
    }

    enum ContentType: String {
        case text
        case other
    }

    var type: ContentType {
        guard let component = self.component else { return .other }
        return ContentType(rawValue: component) ?? .other
    }

}

extension LessonContent: Pullable {

    static var type: String {
        return "lesson-content"
    }

    func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.title = try object.value(for: "title")
        self.text = try object.value(for: "content.text")
        self.component = try object.value(for: "component")
        self.hidden = try object.value(for: "hidden")
    }

}