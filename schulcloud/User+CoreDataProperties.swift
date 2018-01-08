//
//  User+CoreDataProperties.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 30.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var email: String?
    @NSManaged public var firstName: String
    @NSManaged public var id: String
    @NSManaged public var lastName: String
    @NSManaged public var schoolId: String
    @NSManaged public var groups: NSSet
    @NSManaged public var taughtCourses: NSSet?
    @NSManaged public var assignedHomeworks: NSSet?
    @NSManaged public var newsCreated: NSSet?
    @NSManaged public var newsUpdated: NSSet?

}

// MARK: Generated accessors for groups
extension User {

    @objc(addGroupsObject:)
    @NSManaged public func addToGroups(_ value: UserGroup)

    @objc(removeGroupsObject:)
    @NSManaged public func removeFromGroups(_ value: UserGroup)

    @objc(addGroups:)
    @NSManaged public func addToGroups(_ values: NSSet)

    @objc(removeGroups:)
    @NSManaged public func removeFromGroups(_ values: NSSet)

}

// MARK: Generated accessors for taughtCourses
extension User {

    @objc(addTaughtCoursesObject:)
    @NSManaged public func addToTaughtCourses(_ value: Course)

    @objc(removeTaughtCoursesObject:)
    @NSManaged public func removeFromTaughtCourses(_ value: Course)

    @objc(addTaughtCourses:)
    @NSManaged public func addToTaughtCourses(_ values: NSSet)

    @objc(removeTaughtCourses:)
    @NSManaged public func removeFromTaughtCourses(_ values: NSSet)

}

// MARK: Generated accessors for assignedHomeworks
extension User {

    @objc(addAssignedHomeworksObject:)
    @NSManaged public func addToAssignedHomeworks(_ value: Homework)

    @objc(removeAssignedHomeworksObject:)
    @NSManaged public func removeFromAssignedHomeworks(_ value: Homework)

    @objc(addAssignedHomeworks:)
    @NSManaged public func addToAssignedHomeworks(_ values: NSSet)

    @objc(removeAssignedHomeworks:)
    @NSManaged public func removeFromAssignedHomeworks(_ values: NSSet)

}
