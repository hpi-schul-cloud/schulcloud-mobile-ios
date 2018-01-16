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

extension InternalCalendarEvent {
    var calendarEvent : CalendarEvent {
        return CalendarEvent(internalEvent: self)
    }
    
}

public struct CalendarEventHelper {
    
    static func synchronizeEvent() -> Future<[CalendarEvent], SCError> {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext
        
        let parameters : Parameters = ["all":true]
        return ApiHelper.request("calendar", parameters: parameters).jsonArrayFuture(keyPath: nil)
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
                // save new inserted
                return save(privateContext: privateMOC)
            }
            .flatMap { _ -> Future<[CalendarEvent], SCError> in
                // get local calendar event
                return fetchCalendarEvent(inContext: privateMOC)
            }
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

        if  let rfrequency = internalEvent.rfrequency,
            let frequency = RecurenceRule.Frequency(remoteString: rfrequency),
            let rdayOfWeek = internalEvent.rdayOfTheWeek,
            let dayOfWeek = RecurenceRule.DayOfTheWeek(remoteString: rdayOfWeek) {
            
            let internalStartDate = internalEvent.start as Date
            let internalEndDate = internalEvent.end as Date
            
            let internalEventWeekDay = internalStartDate.weekday
            let dayOfWeekIndex : Int = {
                switch dayOfWeek {
                case .sunday:
                    return 8
                case .monday:
                    return 2
                case .tuesday:
                    return 3
                case .wednesday:
                    return 4
                case .thursday:
                    return 5
                case .friday:
                    return 6
                case .saturday:
                    return 7
                }
            }()
            
            var dateComponent = DateComponents()
            dateComponent.day = dayOfWeekIndex - internalEventWeekDay
            
            start = Calendar.current.date(byAdding: dateComponent, to: internalStartDate)!
            end = Calendar.current.date(byAdding: dateComponent, to: internalEndDate)!
                
                recurenceRule = RecurenceRule(frequency: frequency,
                                          dayOfTheWeek: dayOfWeek,
                                          endDate:internalEvent.rendDate as Date?,
                                          interval: Int(internalEvent.rinterval))
        } else {
            start = internalEvent.start as Date
            end = internalEvent.end as Date
            recurenceRule = nil
        }
    }
}

// MARK: Date sequence for event
extension CalendarEvent {
    
    var dates : EventSequence {
        return EventSequence(calendarEvent: self, calculatedDate: [])
    }

    struct EventSequence : Sequence {
        
        let calendarEvent : CalendarEvent
        var calculatedDate: [(Date, Date)]
        
        func makeIterator() -> EventDateIterator {
            return EventDateIterator(self)
        }
        
    }
    struct EventDateIterator : IteratorProtocol {
        typealias Element = (Date, Date)
    
        var sequence : EventSequence
        var iteration: Int = 0
        
        init(_ sequence: EventSequence) {
            self.sequence = sequence
        }
        
        mutating func next() -> (Date, Date)? {
            guard self.iteration >= sequence.calculatedDate.count else {
                return sequence.calculatedDate[self.iteration]
            }
        
            let event = sequence.calendarEvent
            // if non recurring event
            if event.recurenceRule == nil && iteration > 0 { return nil }
            // if we itereated more that the interval
            if event.recurenceRule?.endDate == nil, let interval = event.recurenceRule?.interval, interval <= self.iteration { return nil }

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
            
            let result = (computedStartDate, computedEndDate)
            sequence.calculatedDate.append(result)
            
            self.iteration += 1
            return result
        }
    }
}
