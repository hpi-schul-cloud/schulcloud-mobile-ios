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

public class HomeworkHelper {
    
    typealias FetchResult = Future<Void, SCError>
    
    static func fetchFromServer() -> FetchResult {
        let parameters: Parameters = [
            "$populate": "courseId"
        ]
        
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext
        
        return ApiHelper.request("homework", parameters: parameters).jsonArrayFuture(keyPath: "data")
            .flatMap(privateMOC.perform, f: { $0.map({Homework.upsert(inContext: managedObjectContext, object: $0)}).sequence() })
            .flatMap(privateMOC.perform, f: { dbItems -> FetchResult in
                do {
                    let ids = dbItems.map({$0.id})
                    let deleteRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
                    deleteRequest.predicate = NSPredicate(format: "NOT (id IN %@)", ids)
                    try CoreDataHelper.delete(fetchRequest: deleteRequest, context: privateMOC)
                    return Future(value: Void())
                } catch let error {
                    return Future(error: .database(error.localizedDescription))
                }
            })
            .flatMap { save(privateContext: privateMOC) }
            .flatMap { _ -> FetchResult in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Homework.changeNotificationName), object: nil)
                return Future(value: Void())
        }
    }
    
}
