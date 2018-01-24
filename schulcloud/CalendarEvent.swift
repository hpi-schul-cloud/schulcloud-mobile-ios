//
//  CalendarEvent.swift
//  schulcloud
//
//  Created by Florian Morel on 18.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData

extension EventData {
    var calendarEvent : CalendarEvent {
        return CalendarEvent(eventData: self)
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
    let recurrenceRule: RecurrenceRule?
    
    fileprivate let coreDataID : NSManagedObjectID?
    
    var eventKitID: String? {
        didSet {
            if let objectID = self.coreDataID {
                let event : EventData = managedObjectContext.object(with: objectID) as! EventData
                event.ekIdentifier = self.eventKitID
            }
        }
    }
    
    struct RecurrenceRule {
        
        let frequency: Frequency
        let dayOfTheWeek: DayOfTheWeek
        let endDate: Date?
        let interval: Int
        
        enum Frequency: String {
            case daily = "DAILY"
            case weekly = "WEEKLY"
            case monthly = "MONTHLY"
            case yearly = "YEARLY"
        }
        
        enum DayOfTheWeek: String {
            case monday = "MO"
            case tuesday = "TU"
            case wednesday = "WE"
            case thursday = "TH"
            case friday = "FR"
            case saturday = "SA"
            case sunday = "SU"
        }
    }
    
    init(id: String, title: String, description: String, location: String, startDate: Date, endDate: Date, rule: RecurrenceRule?, coreDataID: NSManagedObjectID?, ekEventID: String?) {
        
        self.id = id
        self.title = title
        self.description = description
        self.location = location
        self.recurrenceRule = rule
        self.coreDataID = coreDataID
        eventKitID = ekEventID
        
        var startDate = startDate
        var endDate = endDate
        
        if let rule = rule {
            
            // We receive date that starts at the beginning of the week when a recurring rule is specified
            // with the dayOfTheWeek property set to tell us which day the event occur
            // e.g. Start date set to monday 28.08.2017 with dayOfTheWeek == Tuesday, the event effectively starting Tuesday 29.08.2017
            //
            // For convenience, when a recurring rule is given, we align the start date to be the actual starting date of the event
            
            let internalEventWeekDay = startDate.weekday
            
            // we manually assign weekday indexes for each day, sunday being exception because in a german week sunday is the last day and not the first
            // to make things easy we simply assign sunday 8 (1 + 7days)
            
            var dayOfWeekIndex : Int = {
                switch rule.dayOfTheWeek {
                case .sunday:
                    return 8 // is because 1
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
            if dayOfWeekIndex < internalEventWeekDay { dayOfWeekIndex += 7 } // we always move to the next day with dayOfWeek (never go back in time to create event
            dateComponent.day = dayOfWeekIndex - internalEventWeekDay // calculate how many days to move foward the dates
            
            startDate = Calendar.current.date(byAdding: dateComponent, to: startDate)!
            endDate = Calendar.current.date(byAdding: dateComponent, to: endDate)!
        }
        
        self.start = startDate
        self.end = endDate
    }
    
    init(eventData: EventData) {
        
        var rule : RecurrenceRule? = nil
        
        if  let rfrequency = eventData.rrFrequency,
            let frequency = RecurrenceRule.Frequency(rawValue: rfrequency),
            let rdayOfWeek = eventData.rrDayOfWeek,
            let dayOfWeek = RecurrenceRule.DayOfTheWeek(rawValue: rdayOfWeek) {
            
            rule = RecurrenceRule(frequency: frequency,
                                  dayOfTheWeek: dayOfWeek,
                                  endDate:eventData.rrEndDate as Date?,
                                  interval: Int(eventData.rrInterval))
        }
        
        self.init(id: eventData.id,
                  title: eventData.title,
                  description: eventData.detail,
                  location: eventData.location,
                  startDate: eventData.start as Date,
                  endDate: eventData.end as Date,
                  rule: rule,
                  coreDataID: eventData.objectID,
                  ekEventID: eventData.ekIdentifier)
    }
}

// MARK: Date sequence for event
extension CalendarEvent {
    
    var dates : EventSequence {
        return EventSequence(calendarEvent: self, calculatedDate: [])
    }
    
    struct EventSequence : Sequence {
        
        var calendarEvent : CalendarEvent
        var calculatedDate: [CalendarEvent]
        
        func makeIterator() -> EventDateIterator {
            return EventDateIterator(self)
        }
    }
    
    struct EventDateIterator : IteratorProtocol {
        typealias Element = CalendarEvent
        
        var sequence : EventSequence
        var iteration: Int = 0
        
        init(_ sequence: EventSequence) {
            self.sequence = sequence
        }
        
        mutating func next() -> CalendarEvent? {
            guard self.iteration >= sequence.calculatedDate.count else {
                return sequence.calculatedDate[self.iteration]
            }
            
            let event = sequence.calendarEvent
            // if non recurring event
            if event.recurrenceRule == nil && iteration > 0 { return nil }
            // if we itereated more that the interval
            if event.recurrenceRule?.endDate == nil, let interval = event.recurrenceRule?.interval, interval <= self.iteration { return nil }
            
            var dateComponents = DateComponents()
            if let recurenceRule = event.recurrenceRule {
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
            
            if let recurenceEndDate = event.recurrenceRule?.endDate,
                computedStartDate > recurenceEndDate {
                return nil
            }
            
            let result = CalendarEvent(id: event.id,
                                       title: event.title,
                                       description: event.description,
                                       location: event.location,
                                       startDate: computedStartDate,
                                       endDate: computedEndDate,
                                       rule: event.recurrenceRule,
                                       coreDataID: event.coreDataID,
                                       ekEventID: event.eventKitID)
            
            sequence.calculatedDate.append(result)
            
            self.iteration += 1
            return result
        }
    }
}

extension Array where Array.Element == CalendarEvent {
    
    func filter(inInterval interval: DateInterval) -> [CalendarEvent] {
        return self.map { event in
            var dateIterator = event.dates.makeIterator()
            while let event = dateIterator.next(),
                event.start < interval.end {
                    
                    let eventInterval = DateInterval(start: event.start, end: event.end)
                    if  interval.intersects(eventInterval) {
                        return event
                    }
            }
            return nil
        }
        .flatMap { $0 } //apply tranform [CalendarEvent?] -> [CalendarEvent]
        .sorted(by: { (event1, event2) -> Bool in
            event1.start < event2.start
        })
    }
}
