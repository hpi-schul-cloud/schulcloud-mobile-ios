//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import Foundation
import SyncEngine

public enum HomeworkHelper {

    @discardableResult public static func syncHomework() -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest = Homework.fetchRequest() as NSFetchRequest<Homework>
        var query = MultipleResourcesQuery(type: Homework.self)
        query.include("courseId")
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query)
    }

}
