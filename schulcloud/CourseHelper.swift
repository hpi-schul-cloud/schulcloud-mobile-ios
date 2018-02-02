//
//  CourseHelper.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Alamofire
import BrightFutures
import CoreData

public class CourseHelper {
    
    typealias FetchResult = Future<Void, SCError>
    
    static func fetchFromServer() -> Future<[String: [Course] ], SCError> {
        
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext
        
        let keyPath: String? = "data"
        
        let parameters: Parameters = [
            "$or[0][userIds]": Globals.account!.userId,
            "$or[1][teacherIds]": Globals.account!.userId
        ]
        return ApiHelper.request("courses", parameters: parameters).jsonArrayFuture(keyPath: keyPath)
            .flatMap(privateMOC.perform, f: { json -> Future<[Course], SCError> in
                let updatedCourseFutures = json.map{ Course.upsert(data: $0, context: privateMOC) }.sequence()
                return updatedCourseFutures
            })
            .flatMap(privateMOC.perform, f: { updatedCourses -> Future<[String: [Course] ], SCError> in
                do {
                    
                    let ids = updatedCourses.map({$0.id})
                    let objectToDeleteFetchRequest : NSFetchRequest<Course> = Course.fetchRequest()
                    objectToDeleteFetchRequest.predicate = NSPredicate(format: "NOT (id IN %@)", ids)
                    let objectToDelete = try privateMOC.fetch(objectToDeleteFetchRequest)
                    if objectToDelete.count > 0 {
                        let batchDelete = NSBatchDeleteRequest(objectIDs: objectToDelete.map { $0.objectID })
                        try privateMOC.execute(batchDelete)
                    }
                    return Future(value: ["updated": updatedCourses, "deleted": objectToDelete])
                } catch let error {
                    return Future(error: .database(error.localizedDescription))
                }
            })
            .andThen { _ in
                save(privateContext: privateMOC)
            }
    }
}
