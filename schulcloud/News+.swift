//
//  News+.swift
//  schulcloud
//
//  Created by Florian Morel on 03.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData
import Marshal

extension News {
   
    static let newsDidChangeNotificationName = "didChangeNews"
    
    static func upsert(inContext context: NSManagedObjectContext, object: MarshaledObject) -> Future<News, SCError> {
        
        do {
           
            let fetchRequest = NSFetchRequest<News>(entityName: "News")
            let id: String = try object.value(for: "_id")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            let result = try context.fetch(fetchRequest)
            let news = result.first ?? News(context: context)
            
            if result.count > 1 {
                throw SCError.database("Found more than one result for \(fetchRequest)")
            }
            
            news.id = id
            news.title       = try object.value(for: "title")
            news.content     = try object.value(for: "content")
            news.displayedAt = try object.value(for: "displayedAt")
            news.createdAt   = try object.value(for: "createdAt")
            news.updatedAt   = try? object.value(for: "updatedAt")
            news.schoolId    = try? object.value(for: "schoolId")
            news.history     = try object.value(for: "history")
            
            let creatorId: String = try object.value(for: "creatorId")
            let updaterId: String? = try? object.value(for: "updaterId")
            
            let creatorFuture = news.fetchCreator(by: creatorId, context: context).onErrorLogAndRecover(with: Void() )
            let updaterFuture = news.fetchUpdater(by: updaterId, context: context).onErrorLogAndRecover(with: Void() )
            
            return [creatorFuture, updaterFuture].sequence().flatMap(object: news)
        } catch let error as MarshalError {
            return Future(error: .jsonDeserialization(error.description))
        } catch let error {
            return Future(error: .database(error.localizedDescription))
        }
    }
    
    func fetchCreator(by id: String, context: NSManagedObjectContext) -> Future< Void, SCError > {
        return User.fetchQueue.sync {
            return User.fetch(by: id, inContext:context).flatMap { creator -> Future<Void, SCError> in
                self.creator = creator
                return Future(value: Void() )
            }
        }
    }
        
    func fetchUpdater(by id: String?, context: NSManagedObjectContext) -> Future< Void, SCError > {
        guard let id = id else { return Future(value: Void() ) }
        return User.fetchQueue.sync {
            return User.fetch(by: id, inContext:context).flatMap { updater -> Future<Void, SCError> in
                self.updater = updater
                return Future(value: Void() )
            }
        }
    }
}

extension News {
    static let didChangeNotification = "newsDidChangeNotification"
}

