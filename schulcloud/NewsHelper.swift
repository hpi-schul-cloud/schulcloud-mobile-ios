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

public class NewsHelper {
    typealias FetchResult = Future<Void, SCError>
    
    static func fetchFromServer() -> Future<Void, SCError> {
        
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext
        
        return ApiHelper.request("news").jsonArrayFuture(keyPath: "data")
            .flatMap(privateMOC.perform, f: { $0.map({News.upsert(inContext: privateMOC, object: $0)}).sequence() })
            .flatMap { save(privateContext: privateMOC) }
            .flatMap { _ -> FetchResult in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: News.didChangeNotification), object: nil)
                return Future(value: Void())
        }
    }
}
