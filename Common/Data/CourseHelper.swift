//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import SyncEngine

public struct CourseHelper {

    public static func syncCourses() -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest = Course.fetchRequest() as NSFetchRequest<Course>
        var query = MultipleResourcesQuery(type: Course.self)
        query.addFilter(forKey: "$or[0][userIds]", withValue: Globals.account!.userId)
        query.addFilter(forKey: "$or[1][teacherIds]", withValue: Globals.account!.userId)
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query)
    }
}
