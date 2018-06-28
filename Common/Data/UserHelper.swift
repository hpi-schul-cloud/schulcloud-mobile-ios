//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import SyncEngine

public struct UserHelper {

    public static func syncUser(withId id: String) -> Future<SyncEngine.SyncSingleResult, SCError> {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        let query = SingleResourceQuery(type: User.self, id: id)
        return SyncHelper.syncResource(withFetchRequest: fetchRequest, withQuery: query)
    }
}
