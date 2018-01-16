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

extension InternalCalendarEvent {
    var calendarEvent : CalendarEvent {
        return CalendarEvent(internalEvent: self)
    }
    
}

public struct CalendarEventHelper {
    
    static func synchronizeEvent() -> Future<[CalendarEvent], SCError> {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext
        
        return ApiHelper.request("calendar", parameters: ["all":true]).jsonArrayFuture(keyPath: nil)
            //parse remote string into local model
            .flatMap(privateMOC.perform, f: { $0.map{InternalCalendarEvent.upsert(inContext: privateMOC, object: $0)}.sequence() })
            .flatMap(privateMOC.perform, f: { dbItems -> Future<Void, SCError> in
               
                //remove unused event
                let ids = dbItems.map { $0.id }
                do {
                    let fetchRequest: NSFetchRequest<InternalCalendarEvent> = InternalCalendarEvent.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "NOT (id in %@)", ids)
                    
                    try CoreDataHelper.delete(fetchRequest: fetchRequest, context: privateMOC)
                    return Future(value: Void() )
                } catch let error {
                    return Future(error: .database(error.localizedDescription) )
                }
            })
            .flatMap { _ -> Future<Void, SCError> in
                // save new inseeted
                return save(privateContext: privateMOC)
            }
            .flatMap { _ -> Future<[CalendarEvent], SCError> in
                // get local calendar event
                return fetchCalendarEvent(inContext: privateMOC)
            }

         /* TODO: Do I do this processing here
         .andThen { result in
         if let calendarEvents = result.value {
         //store events in local cache
         }
         }
         .andThen { _ in
         // Send notification that local cache is avaible
         NotificationCenter.default.post(name: Notification.Name(rawValue: CalendarEvent.didFinishedProcessingEventName), object: nil)
         }
         */
    }
    
    static func fetchCalendarEvent(inContext context: NSManagedObjectContext) -> Future<[CalendarEvent], SCError> {
        let fetchRequest: NSFetchRequest<InternalCalendarEvent> = InternalCalendarEvent.fetchRequest()

        do {
            let fetchedEvent = try context.fetch(fetchRequest)
            return Future(value: fetchedEvent.map({ $0.calendarEvent }))
        } catch let error {
            return Future(error: .database(error.localizedDescription))
        }
    }
    
}

struct CalendarEvent {
    
    static var didFinishedProcessingEventName = "CalendarEventDidFinishProcessingEventName"
    
    let id: String
    let title: String
    let description: String
    let location: String
    let start: Date
    let end: Date
    let recurenceRule: RecurenceRule?

    struct RecurenceRule {
        
        let frequency: Frequency
        let dayOfTheWeek: DayOfTheWeek
        let endDate: Date?
        let interval: Int
        
        enum Frequency: Int {
            case daily
            case weekly
            case monthly
            case yearly
            
            init?(remoteString: String) {
                
                switch remoteString {
                case "DAILY":
                    self = .daily
                case "WEEKLY":
                    self = .weekly
                case "MONTHLY":
                    self = .monthly
                case "YEARLY":
                    self = .yearly
                default:
                    return nil
                }
            }
        }
        
        enum DayOfTheWeek: Int {
            case monday
            case tuesday
            case wednesday
            case thursday
            case friday
            case saturday
            case sunday
            
            init?(remoteString: String) {
                switch remoteString {
                case "MO":
                    self = .monday
                case "TU":
                    self = .tuesday
                case "WE":
                    self = .wednesday
                case "TH":
                    self = .thursday
                case "FR":
                    self = .friday
                case "SA":
                    self = .saturday
                case "SU":
                    self = .sunday
                default:
                    return nil
                }
            }
        }
    }
    
    init(internalEvent: InternalCalendarEvent) {
        id = internalEvent.id
        title = internalEvent.title
        description = internalEvent.desc
        location = internalEvent.location
        start = internalEvent.start as Date
        end = internalEvent.end as Date
        
        if  let rfrequency = internalEvent.rfrequency,
            let frequency = RecurenceRule.Frequency(remoteString: rfrequency),
            let rdayOfWeek = internalEvent.rdayOfTheWeek,
            let dayOfWeek = RecurenceRule.DayOfTheWeek(remoteString: rdayOfWeek) {
            
            recurenceRule = RecurenceRule(frequency: frequency,
                                          dayOfTheWeek: dayOfWeek,
                                          endDate:internalEvent.rendDate as Date?,
                                          interval: Int(internalEvent.rinterval))
        } else {
            recurenceRule = nil
        }
    }
}

extension CalendarEvent {
    
    var dates : EventSequence {
        return EventSequence(calendarEvent: self)
    }

    struct EventSequence : Sequence {
        
        let calendarEvent : CalendarEvent
        
        func makeIterator() -> EventDateIterator {
            return EventDateIterator(self)
        }
        
    }
    struct EventDateIterator : IteratorProtocol {
        typealias Element = (Date, Date)
    
        let sequence : EventSequence
        var iteration: Int = 0
        
        init(_ sequence: EventSequence) {
            self.sequence = sequence
        }
        
        mutating func next() -> (Date, Date)? {
        
            let event = sequence.calendarEvent
            // if non recurring event
            if event.recurenceRule == nil && iteration > 0 { return nil }
            // if we itereated more that the interval
            if let interval = event.recurenceRule?.interval, interval <= self.iteration { return nil }

            var dateComponents = DateComponents()
            if let recurenceRule = event.recurenceRule {
            
                switch recurenceRule.frequency {
                case .daily:
                    dateComponents.day = self.iteration
                case .weekly:
                    dateComponents.weekOfYear = self.iteration
                case .monthly:
                    dateComponents.month = self.iteration
                case .yearly:
                    dateComponents.year = self.iteration
                }
            }
            
            guard let computedStartDate = Calendar.current.date(byAdding: dateComponents, to: event.start),
                let computedEndDate = Calendar.current.date(byAdding: dateComponents, to: event.end)
                else {
                    return nil
            }
            
            if let recurenceEndDate = event.recurenceRule?.endDate,
                computedStartDate > recurenceEndDate {
                return nil
            }

            self.iteration += 1
            return (computedStartDate, computedEndDate)
        }
    }
}
