//
//  CalendarEventHelper+EventKit.swift
//  schulcloud
//
//  Created by Florian Morel on 19.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import EventKit
import BrightFutures


// MARK: Extension with EvenKit convenience
extension CalendarEventHelper {
    
    private static var eventStore: EKEventStore = EKEventStore()
    private static var calendar : EKCalendar?

    private struct Keys {
        static let isSynchonized = "org.schul-cloud.calendar.eventKitIsSynchonized"
        static let calendarIdentifier = "org.schul-cloud.calendar.identifier"
    }
    
    struct EventKitSettings {
        
        static var current : EventKitSettings = EventKitSettings()
        var isSynchonized : Bool {
            get {
                return UserDefaults.standard.bool(forKey: Keys.isSynchonized)
            }
            set {
                UserDefaults.standard.set(newValue, forKey: Keys.isSynchonized)
                UserDefaults.standard.synchronize()
            }
        }
        
        var calendarIdentifier : String? {
            get {
                return UserDefaults.standard.string(forKey: Keys.calendarIdentifier)
            }
            
            set {
                UserDefaults.standard.set(newValue, forKey: Keys.calendarIdentifier)
                UserDefaults.standard.synchronize()
            }
        }
        var calendarTitle : String = "Schul-Cloud"
    }
    
    private static func update(event: EKEvent, with calendarEvent: CalendarEvent) {
        event.title = calendarEvent.title
        event.notes = calendarEvent.description
        event.location = calendarEvent.location
        event.startDate = calendarEvent.start
        event.endDate = calendarEvent.end
        event.recurrenceRules =  {
            guard let rule = calendarEvent.recurrenceRule else { return nil }
            return [rule.ekRecurrenceRule]
        }()
    }
    
    private static func requestCalendarPermission() -> Future<Void, SCError> {
        let promise = Promise<Void, SCError>()
        
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            eventStore.reset()
            promise.success()
        case .notDetermined:
            self.eventStore.requestAccess(to: .event) { (granted, error) in
                if granted && error == nil {
                    eventStore.reset()
                    promise.success()
                } else {
                    promise.failure(SCError.other("Missing Calendar Permission: \(error!.localizedDescription)"))
                }
            }
        default:
            promise.failure(SCError.other("Cannot request permision for calendar"))
        }
        return promise.future
    }

    
    private static func fetchOrCreateCalendar() -> Future<EKCalendar, SCError> {
        
        if let calendar = self.calendar { return Future(value: calendar) }
        
        if let calendarIdentifier = EventKitSettings.current.calendarIdentifier,
           let foundCalendar = eventStore.calendar(withIdentifier: calendarIdentifier) {
            self.calendar = foundCalendar
            return Future(value: foundCalendar)
        }
        
        if let calendar = eventStore.calendars(for: .event).first (where:  { $0.title == EventKitSettings.current.calendarTitle }) {
            self.calendar = calendar
            return Future(value: calendar)
        }
        
        guard let source = eventStore.sources.first(where: { return $0.sourceType == EKSourceType.subscribed }) else {
            return Future( error: .other("Can't find source for calendar") )
        }
        
        let calendar = EKCalendar(for: .event, eventStore: self.eventStore)
        calendar.title = EventKitSettings.current.calendarTitle
        calendar.source = source
        
        do {
            try self.eventStore.saveCalendar(calendar, commit: true)
        } catch {
            return Future( error: .other("Can't find source for calendar") )
        }
        
        EventKitSettings.current.calendarIdentifier = calendar.calendarIdentifier

        self.calendar = calendar
        return Future(value: calendar)
    }

    // This function pushes new or update events to the calander
    static func pushEventsToCalendar(calendarEvents: [CalendarEvent]) -> Future<Void, SCError> {
        
        let promise : Promise<Void, SCError> = Promise()
        let calendarEvents = calendarEvents
        
        requestCalendarPermission()
        .flatMap(fetchOrCreateCalendar)
        .onSuccess { calendar in
            
            for var calendarEvent in calendarEvents {
                var event : EKEvent
                var span : EKSpan
                
                if  let ekEventID = calendarEvent.eventKitID,
                    let foundEvent = eventStore.event(withIdentifier: ekEventID) {
                    event = foundEvent
                    span = .futureEvents
                    
                } else {
                    event = EKEvent(eventStore: eventStore)
                    event.calendar = calendar
                    span = .thisEvent
                    
                }
                
                update(event: event, with: calendarEvent)
                do {
                    try eventStore.save(event, span: span, commit: false)
                } catch let error {
                    promise.failure(.other("Cant create EKEvent: \(error.localizedDescription)") )
                    return ;
                }
                calendarEvent.eventKitID = event.eventIdentifier
            }
            
            do {
                try eventStore.commit()
            } catch let error {
                promise.failure( .other(" Error commiting store after creating events: \(error.localizedDescription)") )
                return;
            }
            
            do {
                try managedObjectContext.save()
                promise.success( Void() )
            } catch let error {
                promise.failure( .database(error.localizedDescription) )
            }
        }
        return promise.future
    }
    
    static func removeEvents(calendarEvents: [CalendarEvent]) -> Future<Void, SCError> {
        let eventsToDelete = eventStore.events(matching: NSPredicate(format: "eventIdentifer in %@", calendarEvents.map { $0.eventKitID }) )
        do {
            for event in eventsToDelete {
                try eventStore.remove(event, span: EKSpan.futureEvents, commit: false)
            }
            try eventStore.commit()
            return Future(value: Void() )
        } catch let error {
            return Future(error: SCError.other("Can't commit event removal\(error.localizedDescription)" ) )
        }
    }
    
    static func deleteSchulcloudCalendar() -> Future<Void, SCError> {
        guard let calendarIdentifier = EventKitSettings.current.calendarIdentifier,
              let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) else { return Future(value: Void() ) }

        let promise : Promise<Void, SCError> = Promise()
        do {
            try eventStore.removeCalendar(calendar, commit: true)
            EventKitSettings.current.calendarIdentifier = nil
            self.calendar = nil
        } catch let error {
            promise.failure( SCError.other("Failed to remove calendar:\(error.localizedDescription)") )
        }
        
        fetchCalendarEvent(inContext: managedObjectContext)
        .onSuccess { events in
            for var event in events {
                event.eventKitID = nil
            }
            do {
                try managedObjectContext.save()
                promise.success( Void() )
            } catch let error {
                promise.failure( .database(error.localizedDescription) )
            }
        }
        return promise.future
    }
}


// MARK: Convenience conversion
extension CalendarEvent.RecurrenceRule {
    var ekRecurrenceRule : EKRecurrenceRule {
        let until: EKRecurrenceEnd?
        if let endDate = self.endDate {
            until = EKRecurrenceEnd(end: endDate)
        } else {
            until = nil
        }
        let rule = EKRecurrenceRule(recurrenceWith: self.frequency.ekFrequency,
                                    interval: self.interval == 0 ? 1 : self.interval,
                                    daysOfTheWeek: [self.dayOfTheWeek.ekDayOfTheWeek],
                                    daysOfTheMonth: nil,
                                    monthsOfTheYear: nil,
                                    weeksOfTheYear: nil,
                                    daysOfTheYear: nil,
                                    setPositions: nil,
                                    end: until)
        return rule
    }
}

extension CalendarEvent.RecurrenceRule.Frequency {
    var ekFrequency : EKRecurrenceFrequency {
        switch self {
        case .daily:
            return .daily
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        case .yearly:
            return .yearly
        }
    }
}

extension CalendarEvent.RecurrenceRule.DayOfTheWeek {
    var ekDayOfTheWeek : EKRecurrenceDayOfWeek {
        let ekWeekday: EKWeekday = {
            switch self {
            case .monday:
                return .monday
            case .tuesday:
                return .tuesday
            case .wednesday:
                return .wednesday
            case .thursday:
                return .thursday
            case .friday:
                return .friday
            case .saturday:
                return .saturday
            case .sunday:
                return .sunday
            }
        }()
        return EKRecurrenceDayOfWeek(ekWeekday)
    }
}
