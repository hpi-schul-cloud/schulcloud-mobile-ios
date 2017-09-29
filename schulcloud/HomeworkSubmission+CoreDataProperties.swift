//
//  HomeworkSubmission+CoreDataProperties.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 28.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//
//

import Foundation
import CoreData


extension HomeworkSubmission {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HomeworkSubmission> {
        return NSFetchRequest<HomeworkSubmission>(entityName: "HomeworkSubmission")
    }

    @NSManaged public var gradeComment: String?
    @NSManaged public var grade: Double
    @NSManaged public var comment: String
    @NSManaged public var id: String
    @NSManaged public var homework: Homework
    @NSManaged public var student: User
    @NSManaged public var comments: NSOrderedSet

}

// MARK: Generated accessors for comments
extension HomeworkSubmission {

    @objc(insertObject:inCommentsAtIndex:)
    @NSManaged public func insertIntoComments(_ value: HomeworkComment, at idx: Int)

    @objc(removeObjectFromCommentsAtIndex:)
    @NSManaged public func removeFromComments(at idx: Int)

    @objc(insertComments:atIndexes:)
    @NSManaged public func insertIntoComments(_ values: [HomeworkComment], at indexes: NSIndexSet)

    @objc(removeCommentsAtIndexes:)
    @NSManaged public func removeFromComments(at indexes: NSIndexSet)

    @objc(replaceObjectInCommentsAtIndex:withObject:)
    @NSManaged public func replaceComments(at idx: Int, with value: HomeworkComment)

    @objc(replaceCommentsAtIndexes:withComments:)
    @NSManaged public func replaceComments(at indexes: NSIndexSet, with values: [HomeworkComment])

    @objc(addCommentsObject:)
    @NSManaged public func addToComments(_ value: HomeworkComment)

    @objc(removeCommentsObject:)
    @NSManaged public func removeFromComments(_ value: HomeworkComment)

    @objc(addComments:)
    @NSManaged public func addToComments(_ values: NSOrderedSet)

    @objc(removeComments:)
    @NSManaged public func removeFromComments(_ values: NSOrderedSet)

}
