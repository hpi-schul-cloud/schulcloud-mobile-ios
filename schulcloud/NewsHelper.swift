//
//  NewsHelper.swift
//  schulcloud
//
//  Created by Florian Morel on 04.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Alamofire
import BrightFutures
import CoreData

public class NewsArticleHelper {
    
    typealias FetchResult = Future<Void, SCError>
    
    static func fetchFromServer() -> Future<Void, SCError> {
        
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext
        
        //the feed contains all available news item,
        return ApiHelper.request("news").jsonArrayFuture(keyPath: "data")
            .flatMap(privateMOC.perform, f: { $0.map({NewsArticle.upsert(inContext: privateMOC, object: $0)}).sequence() }) //parse JSON and create local copy
            .flatMap(privateMOC.perform, f: { dbItems -> FetchResult in
                //remove items that are no longer in the feed
                do {
                    let ids = dbItems.map({$0.id})
                    let deleteRequest: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
                    deleteRequest.predicate = NSPredicate(format: "NOT (id IN %@)", ids)
                    try CoreDataHelper.delete(fetchRequest: deleteRequest, context: privateMOC)
                    return Future(value: Void())
                } catch let error {
                    return Future(error: .database(error.localizedDescription))
                }
            })
            .flatMap { save(privateContext: privateMOC) }
            .flatMap { _ -> FetchResult in //notify of changed in news
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: NewsArticle.didChangeNotification), object: nil)
                return Future(value: Void())
        }
    }
}
