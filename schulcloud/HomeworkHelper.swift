//
//  HomeworkHelper.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 28.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData

public class HomeworkHelper {
    static func fetchFromServer() -> Future<Void, SCError> {
        return ApiHelper.request("homework").jsonArrayFuture(keyPath: "data")
            .flatMap { items -> Future<Void, SCError> in
                do {
                    let dbItems = try items.map {try Homework.createOrUpdate(inContext: managedObjectContext, object: $0)}
                    let ids = dbItems.map({$0.id})
                    let deleteRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
                    deleteRequest.predicate = NSPredicate(format: "NOT (id IN %@)", ids)
                    try CoreDataHelper.delete(fetchRequest: deleteRequest)
                    saveContext()
                    return Future(value: Void())
                } catch let error {
                    return Future(error: .database(error.localizedDescription))
                }
        }
    }
}
