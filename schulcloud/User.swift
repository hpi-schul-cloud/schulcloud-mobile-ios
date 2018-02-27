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
    
    @NSManaged private var permissionStorage: PermissionStorage

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

}

final class PermissionStorage : NSObject, NSCoding {
    
    var byte0 : Int64 = 0
    var byte1 : Int64 = 0

    init(byte1: Int64, byte0: Int64) {
        self.byte0 = byte0
        self.byte1 = byte1
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(byte0, forKey: "byte0")
        aCoder.encode(byte1, forKey: "byte1")
    }
    
    init?(coder aDecoder: NSCoder) {
        self.byte0 = aDecoder.decodeInt64(forKey: "byte0")
        self.byte1 = aDecoder.decodeInt64(forKey: "byte1")
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
        
        let permissions : [String] = (try? object.value(for: "permissions")) ?? []
        self.permissions = permissions.flatMap{ UserPermissions(str: $0) }.reduce(UserPermissions(), { (acc, permission) -> UserPermissions in
            return acc.union(permission)
        })
    }

}

extension User {
    var permissions : UserPermissions {
        get {
            return UserPermissions(rawValue: (self.permissionStorage.byte0, self.permissionStorage.byte1) )
        }
        set {
            self.permissionStorage = PermissionStorage(byte1: newValue.rawValue.1, byte0: newValue.rawValue.0)
        }
    }
}
