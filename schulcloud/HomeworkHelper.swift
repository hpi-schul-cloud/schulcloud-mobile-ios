//
//  HomeworkHelper.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 28.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Alamofire
import BrightFutures
import CoreData

struct HomeworkHelper {

    static func syncHomework() -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest = Homework.fetchRequest() as NSFetchRequest<Homework>
        var query = MultipleResourcesQuery(type: Homework.self)
        query.include("courseId")
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query).onSuccess { _ in
            NotificationCenter.default.post(name: Homework.homeworkCountDidChange, object: nil)
        }
    }

}
