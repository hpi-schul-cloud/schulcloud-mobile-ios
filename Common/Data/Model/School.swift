//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import SyncEngine

public final class School: NSManagedObject {

    @NSManaged public var id: String
    @NSManaged public var name: String

    @NSManaged public var users: Set<User>

    @nonobjc public class func fetchRequest() -> NSFetchRequest<School> {
        return NSFetchRequest<School>(entityName: "School")
    }
}

extension School: Pullable {

    public static var type: String {
        return "schools"
    }

    public func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.name = try object.value(for: "name")
    }
}

