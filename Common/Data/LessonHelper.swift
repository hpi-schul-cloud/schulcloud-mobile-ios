//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import SyncEngine

public enum LessonHelper {
    public static func syncLessons(for course: Course) -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest = Lesson.fetchRequest() as NSFetchRequest<Lesson>
        var query = MultipleResourcesQuery(type: Lesson.self)
        query.addFilter(forKey: "courseId", withValue: course.id)
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query)
    }
}
