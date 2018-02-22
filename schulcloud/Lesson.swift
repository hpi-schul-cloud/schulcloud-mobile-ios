//
//  Lesson.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData

final class Lesson : NSManagedObject {

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

extension Lesson : Pullable {

    static var type: String {
        return "lessons"
    }

    func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.name = try object.value(for: "name")
        self.descriptionText = try object.value(for: "descriptionText")
        self.date = try object.value(for: "date")

        try self.updateRelationship(forKeyPath: \Lesson.contents, forKey: "contents", fromObject: object, with: context)
    }

}

//// MARK: Generated accessors for contents
//extension Lesson {
//
//    @objc(insertObject:inContentsAtIndex:)
//    @NSManaged public func insertIntoContents(_ value: Content, at idx: Int)
//
//    @objc(removeObjectFromContentsAtIndex:)
//    @NSManaged public func removeFromContents(at idx: Int)
//
//    @objc(insertContents:atIndexes:)
//    @NSManaged public func insertIntoContents(_ values: [Content], at indexes: NSIndexSet)
//
//    @objc(removeContentsAtIndexes:)
//    @NSManaged public func removeFromContents(at indexes: NSIndexSet)
//
//    @objc(replaceObjectInContentsAtIndex:withObject:)
//    @NSManaged public func replaceContents(at idx: Int, with value: Content)
//
//    @objc(replaceContentsAtIndexes:withContents:)
//    @NSManaged public func replaceContents(at indexes: NSIndexSet, with values: [Content])
//
//    @objc(addContentsObject:)
//    @NSManaged public func addToContents(_ value: Content)
//
//    @objc(removeContentsObject:)
//    @NSManaged public func removeFromContents(_ value: Content)
//
//    @objc(addContents:)
//    @NSManaged public func addToContents(_ values: NSOrderedSet)
//
//    @objc(removeContents:)
//    @NSManaged public func removeFromContents(_ values: NSOrderedSet)
//
//}

