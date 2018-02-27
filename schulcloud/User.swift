//
//  User.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 30.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData

final class User: NSManagedObject {

    @NSManaged public var id: String
    @NSManaged public var email: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var courses: Set<Course>
    @NSManaged public var taughtCourses: Set<Course>
    @NSManaged public var assignedHomeworks: Set<Homework>
    @NSManaged public var permissions_: [Int64]

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

}

extension User {

    var shortName: String {
        guard let lastName = self.lastName else {
            return self.firstName ?? ""
        }

        if let intialCharacter = self.firstName?.first  {
            return "\(String(intialCharacter)). \(lastName)"
        } else {
            return lastName
        }
    }

}

extension User : Pullable {

    static var type: String {
        return "users"
    }

    func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.email = try object.value(for: "email")
        self.firstName = try object.value(for: "firstName")
        self.lastName = try object.value(for: "lastName")
        let permissions : [String] = try object.value(for: "permissions")
        self.permissions = permissions.flatMap{ UserPermissions(str: $0) }.reduce(UserPermissions(), { (acc, permission) -> UserPermissions in
            return acc.union(permission)
        })
    }

}
