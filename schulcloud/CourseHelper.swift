//
//  CourseHelper.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

//import Foundation
//import Alamofire
import BrightFutures
import CoreData

struct CourseHelper {

    static func syncCourses() -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest = Course.fetchRequest() as NSFetchRequest<Course>
        var query = MultipleResourcesQuery(type: Course.self)
        query.addFilter(forKey: "$or[0][userIds]", withValue: Globals.account!.userId)
        query.addFilter(forKey: "$or[1][teacherIds]", withValue: Globals.account!.userId)
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query)
    }
   
}

