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

extension InternalCalendarEvent {
    
    static func synchronizeEvent() -> Future<[CalendarEvent], SCError> {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext
        
        return ApiHelper.request("calendar", parameters: ["all":true]).jsonArrayFuture(keyPath: nil)
            //parse remote string into local model
            .flatMap(privateMOC.perform, f: { $0.map{InternalCalendarEvent.upsert(inContext: privateMOC, object: $0)}.sequence() })
            //TODO: remove unsued event
            .flatMap { _ -> Future<Void, SCError> in
                // save new inseted
                return save(privateContext: privateMOC)
             }
            .flatMap(fetchCalendarEvent) // get local calendar event
            /* Do I do this processing here
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

}

extension InternalCalendarEvent {
    var calendarEvent : CalendarEvent {
        return CalendarEvent(internalEvent: self)
    }
    
    static func fetchCalendarEvent() -> Future<[CalendarEvent], SCError> {
        //TODO: implement this
        return Future(value: [])
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
}
