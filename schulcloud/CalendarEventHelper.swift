//
//  CalendarEventHelper.swift
//  schulcloud
//
//  Created by Florian Morel on 11.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData
import DateToolsSwift
import Alamofire

public struct CalendarEventHelper {
    
    static func synchronizeEvent() -> Future<[CalendarEvent], SCError> {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext
        
        let parameters : Parameters = ["all":true]
        return ApiHelper.request("calendar", parameters: parameters).jsonArrayFuture(keyPath: nil)
            //parse remote string into local model
            .flatMap(privateMOC.perform, f: { $0.map{EventData.upsert(inContext: privateMOC, object: $0)}.sequence() })
            .flatMap(privateMOC.perform, f: { dbItems -> Future<Void, SCError> in
                
                //remove unused event
                let ids = dbItems.map { $0.id }
                do {
                    let fetchRequest: NSFetchRequest<EventData> = EventData.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "NOT (id in %@)", ids)
                    
                    try CoreDataHelper.delete(fetchRequest: fetchRequest, context: privateMOC)
                    return Future(value: Void() )
                } catch let error {
                    return Future(error: .database(error.localizedDescription) )
                }
            })
            .flatMap { _ -> Future<Void, SCError> in
                // save new inserted
                return save(privateContext: privateMOC)
            }
            .flatMap { _ -> Future<[CalendarEvent], SCError> in
                // get local calendar event
                return fetchCalendarEvent(inContext: privateMOC)
            }
    }
    
    static func fetchCalendarEvent(inContext context: NSManagedObjectContext) -> Future<[CalendarEvent], SCError> {
        let fetchRequest: NSFetchRequest<EventData> = EventData.fetchRequest()

        do {
            let fetchedEvent = try context.fetch(fetchRequest)
            return Future(value: fetchedEvent.map({ $0.calendarEvent }))
        } catch let error {
            return Future(error: .database(error.localizedDescription))
        }
    }
}
