//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData

public final class WorkingSetSyncAnchor: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var value: Int64
}

public extension WorkingSetSyncAnchor {

    public static let mainId: String = "WorkingSetSyncAnchor"

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkingSetSyncAnchor> {
        return NSFetchRequest<WorkingSetSyncAnchor>(entityName: "WorkingSetSyncAnchor")
    }

    public static var mainAnchorFetchRequest: NSFetchRequest<WorkingSetSyncAnchor> {
        let result = WorkingSetSyncAnchor.fetchRequest() as NSFetchRequest<WorkingSetSyncAnchor>
        result.predicate = NSPredicate(format: "id == %@", WorkingSetSyncAnchor.mainId)
        return result
    }
}
