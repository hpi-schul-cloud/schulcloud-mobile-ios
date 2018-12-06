//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import SyncEngine

public struct SchoolHelper {

    public static func syncSchool(withId id: String) -> Future<SyncEngine.SyncSingleResult, SCError> {
        let fetchRequest: NSFetchRequest<School> = School.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        let query = SingleResourceQuery(type: School.self, id: id)
        return SyncHelper.syncResource(withFetchRequest: fetchRequest, withQuery: query)
    }
}
