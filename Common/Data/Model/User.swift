//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import SyncEngine

public final class User: NSManagedObject {

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

public final class PermissionStorage: NSObject, NSCoding {

    var byte0: Int64 = 0
    var byte1: Int64 = 0

    init(byte1: Int64, byte0: Int64) {
        self.byte0 = byte0
        self.byte1 = byte1
        super.init()
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(byte0, forKey: "byte0")
        aCoder.encode(byte1, forKey: "byte1")
    }

    public init?(coder aDecoder: NSCoder) {
        self.byte0 = aDecoder.decodeInt64(forKey: "byte0")
        self.byte1 = aDecoder.decodeInt64(forKey: "byte1")
    }

}

extension User {

    public var shortName: String {
        guard let lastName = self.lastName else {
            return self.firstName ?? ""
        }

        if let intialCharacter = self.firstName?.first {
            return "\(String(intialCharacter)). \(lastName)"
        } else {
            return lastName
        }
    }

}

extension User: Pullable {

    public static var type: String {
        return "users"
    }

    public func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.email = try object.value(for: "email")
        self.firstName = try object.value(for: "firstName")
        self.lastName = try object.value(for: "lastName")

        let permissions: [String] = (try? object.value(for: "permissions")) ?? []
        self.permissions = UserPermissions(array: permissions)
    }

}

extension User {
    public var permissions: UserPermissions {
        get {
            return UserPermissions(rawValue: (self.permissionStorage.byte0, self.permissionStorage.byte1) )
        }
        set {
            self.permissionStorage = PermissionStorage(byte1: newValue.rawValue.1, byte0: newValue.rawValue.0)
        }
    }
}
