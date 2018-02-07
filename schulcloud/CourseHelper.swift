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

        let parameters: Parameters = [
            "$or[0][userIds]": Globals.account!.userId,
            "$or[1][teacherIds]": Globals.account!.userId
        ]
        return ApiHelper.request("courses", parameters: parameters).jsonArrayFuture(keyPath: "data")
            .flatMap(privateMOC.perform, f: { json -> Future<[Course], SCError> in
                let updatedCourseFutures = json.map{ Course.upsert(data: $0, context: privateMOC) }.sequence()
                return updatedCourseFutures
                
            }).flatMap(privateMOC.perform, f: { updatedCourses -> Future<Void, SCError> in
                do {
                    let ids = updatedCourses.map({$0.id})
                    let objectToDeleteFetchRequest : NSFetchRequest<Course> = Course.fetchRequest()
                    
                    objectToDeleteFetchRequest.predicate = NSPredicate(format: "NOT (id IN %@)", ids)
                    try CoreDataHelper.delete(fetchRequest: objectToDeleteFetchRequest)
                    
                    return Future(value: Void() )
                } catch let error {
                    return Future(error: .database(error.localizedDescription))
                }
            }).map {
                func filterCourses(managedObject: NSManagedObject) -> Bool {
                    guard let _ = managedObject as? Course else { return false }
                    return true
                }
                
                let inserted = Array(privateMOC.insertedObjects).filter(filterCourses) as! [Course]
                let updated = Array(privateMOC.updatedObjects).filter(filterCourses) as! [Course]
                let deleted = Array(privateMOC.deletedObjects).filter(filterCourses) as! [Course]
                
                return [NSInsertedObjectsKey: inserted, NSUpdatedObjectsKey: updated, NSDeletedObjectsKey: deleted]
            }.andThen { _ in
                save(privateContext: privateMOC)
            }
    }
}
