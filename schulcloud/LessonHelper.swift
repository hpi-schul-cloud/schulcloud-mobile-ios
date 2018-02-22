//
//  LessonHelper.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

//import Foundation
//import Alamofire
import BrightFutures
import CoreData

struct LessonHelper {

    static func syncLessons(for course: Course) -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest = Lesson.fetchRequest() as NSFetchRequest<Lesson>
        var query = MultipleResourcesQuery(type: Lesson.self)
        query.addFilter(forKey: "courseId", withValue: course.id)
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query)
    }

}

