//
//  UserHelper.swift
//  schulcloud
//
//  Created by Max Bothe on 21.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import BrightFutures
import CoreData

struct UserHelper {

    static func syncUser(withId id: String) -> Future<SyncEngine.SyncSingleResult, SyncError> {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        let query = SingleResourceQuery(type: User.self, id: id)
        return SyncHelper.syncResource(withFetchRequest: fetchRequest, withQuery: query)
    }
}
