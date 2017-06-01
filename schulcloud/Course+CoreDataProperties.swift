//
//  Course+CoreDataProperties.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData


extension Course {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Course> {
        return NSFetchRequest<Course>(entityName: "Course")
    }

    @NSManaged public var colorString: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var includedHomeworks: NSSet?
    @NSManaged public var lessons: NSSet?
    @NSManaged public var teachers: NSSet?

}

// MARK: Generated accessors for includedHomeworks
extension Course {

    @objc(addIncludedHomeworksObject:)
    @NSManaged public func addToIncludedHomeworks(_ value: Homework)

    @objc(removeIncludedHomeworksObject:)
    @NSManaged public func removeFromIncludedHomeworks(_ value: Homework)

    @objc(addIncludedHomeworks:)
    @NSManaged public func addToIncludedHomeworks(_ values: NSSet)

    @objc(removeIncludedHomeworks:)
    @NSManaged public func removeFromIncludedHomeworks(_ values: NSSet)

}

// MARK: Generated accessors for lessons
extension Course {

    @objc(addLessonsObject:)
    @NSManaged public func addToLessons(_ value: Lesson)

    @objc(removeLessonsObject:)
    @NSManaged public func removeFromLessons(_ value: Lesson)

    @objc(addLessons:)
    @NSManaged public func addToLessons(_ values: NSSet)

    @objc(removeLessons:)
    @NSManaged public func removeFromLessons(_ values: NSSet)

}

// MARK: Generated accessors for teachers
extension Course {

    @objc(addTeachersObject:)
    @NSManaged public func addToTeachers(_ value: User)

    @objc(removeTeachersObject:)
    @NSManaged public func removeFromTeachers(_ value: User)

    @objc(addTeachers:)
    @NSManaged public func addToTeachers(_ values: NSSet)

    @objc(removeTeachers:)
    @NSManaged public func removeFromTeachers(_ values: NSSet)

}
