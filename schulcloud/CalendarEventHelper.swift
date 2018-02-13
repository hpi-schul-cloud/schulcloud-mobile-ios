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
        privateMOC.parent = CoreDataHelper.managedObjectContext
        
        let parameters : Parameters = ["all":true]
        return ApiHelper.request("calendar", parameters: parameters).jsonArrayFuture(keyPath: nil)
            //parse remote string into local model
            .flatMap(privateMOC.perform, f: { $0.map{EventData.upsert(inContext: privateMOC, object: $0)}.sequence() })
            .flatMap(privateMOC.perform, f: { dbItems -> Future<[EventData], SCError> in
                //remove unused event
                let ids = dbItems.map { $0.id }
                var eventsToDelete: [EventData] = []
                do {
                    let fetchRequest: NSFetchRequest<EventData> = EventData.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "NOT (id in %@)", ids)
                    
                    eventsToDelete = try privateMOC.fetch(fetchRequest)
                    if eventsToDelete.count > 0 {
                        let batchDelete = NSBatchDeleteRequest(objectIDs: eventsToDelete.map { $0.objectID } )
                        try privateMOC.execute(batchDelete)
                    }
                } catch let error {
                    return Future(error: .database(error.localizedDescription) )
                }
                return Future(value: eventsToDelete)
            })
            .flatMap { eventsToDelete -> Future<Void, SCError> in
                // remove events from calendar
                
                let promise: Promise<Void, SCError> = Promise()
                
                CalendarEventHelper.requestCalendarPermission()
                .andThen{ result in
                    if result.value != nil {
                        if CalendarEventHelper.EventKitSettings.current.shouldSynchonize,
                            eventsToDelete.count > 0 {
                            do {
                                try CalendarEventHelper.remove(events: eventsToDelete.map { $0.calendarEvent })
                            } catch let error {
                                promise.failure(.other("Could not remove events from calendar: \(error.localizedDescription)") )
                            }
                        }
                        promise.success( Void() )
                    }
                }
                return promise.future
            }
            .flatMap { _ -> Future<Void, SCError> in
                // save new inserted, and deleted
                return CoreDataHelper.save(privateContext: privateMOC)
            }
            .flatMap { _ -> Future<[CalendarEvent], SCError> in
                // get local calendar event
                return fetchCalendarEvent(inContext: privateMOC)
            }
            .andThen { result in
                // push new events to calendar
                guard let events = result.value, events.count > 0 else { return ; }
                
                CalendarEventHelper.requestCalendarPermission()
                .andThen { result in
                        if CalendarEventHelper.EventKitSettings.current.shouldSynchonize,
                            let calendar = CalendarEventHelper.fetchCalendar() ?? CalendarEventHelper.createCalendar() {
                            try? CalendarEventHelper.push(events: events , to: calendar)
                        }
                }
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
