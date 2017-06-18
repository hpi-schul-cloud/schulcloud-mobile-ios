//
//  Lesson+CoreDataProperties.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData


extension Lesson {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Lesson> {
        return NSFetchRequest<Lesson>(entityName: "Lesson")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String?
    @NSManaged public var descriptionString: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var hidden: Bool
    @NSManaged public var contents: NSOrderedSet?
    @NSManaged public var course: Course?

}

// MARK: Generated accessors for contents
extension Lesson {

    @objc(insertObject:inContentsAtIndex:)
    @NSManaged public func insertIntoContents(_ value: Content, at idx: Int)

    @objc(removeObjectFromContentsAtIndex:)
    @NSManaged public func removeFromContents(at idx: Int)

    @objc(insertContents:atIndexes:)
    @NSManaged public func insertIntoContents(_ values: [Content], at indexes: NSIndexSet)

    @objc(removeContentsAtIndexes:)
    @NSManaged public func removeFromContents(at indexes: NSIndexSet)

    @objc(replaceObjectInContentsAtIndex:withObject:)
    @NSManaged public func replaceContents(at idx: Int, with value: Content)

    @objc(replaceContentsAtIndexes:withContents:)
    @NSManaged public func replaceContents(at indexes: NSIndexSet, with values: [Content])

    @objc(addContentsObject:)
    @NSManaged public func addToContents(_ value: Content)

    @objc(removeContentsObject:)
    @NSManaged public func removeFromContents(_ value: Content)

    @objc(addContents:)
    @NSManaged public func addToContents(_ values: NSOrderedSet)

    @objc(removeContents:)
    @NSManaged public func removeFromContents(_ values: NSOrderedSet)

}
