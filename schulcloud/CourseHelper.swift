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
    
    static func fetchFromServer() -> FetchResult {
        
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
            .flatMap(privateMOC.perform, f: { updatedCourses -> FetchResult in
                do {
                    let ids = updatedCourses.map({$0.id})
                    let deleteRequest: NSFetchRequest<Course> = Course.fetchRequest()
                    deleteRequest.predicate = NSPredicate(format: "NOT (id IN %@)", ids)
                    try CoreDataHelper.delete(fetchRequest: deleteRequest, context: privateMOC)
                    saveContext()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Homework.homeworkDidChangeNotificationName), object: nil)
                    return Future(value: Void())
                } catch let error {
                    return Future(error: .database(error.localizedDescription))
                }
            })
            .flatMap {  _ -> FetchResult in
                return save(privateContext: privateMOC)
            }
    }
    
}
