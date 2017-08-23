//
//  CalendarHelper.swift
//  schulcloud
//
//  Created by Max Bothe on 16.08.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation

import CoreData
import EventKit

import Alamofire
import BrightFutures
import CalendarKit
import DateToolsSwift
import Marshal


public struct CalendarHelper {

    static var eventStore: EKEventStore = {
        return EKEventStore()
    }()

    private static let calendarIdentifierKey = "or.schul-cloud.calendar.identifier"
    private static let calendarTitle = "Schul-Cloud"

    static var schulcloudCalendar: EKCalendar?

    static func initializeCalendar(on controller: UIViewController, _ completion: @escaping (EKCalendar?) -> Void ) {
        let userDefaults = UserDefaults.standard
        let updateCalendarAndComplete: (EKCalendar?) -> Void = { calendar in
            self.schulcloudCalendar = calendar
            completion(calendar)
        }

        if let calendarIdentifier = userDefaults.string(forKey: self.calendarIdentifierKey) {
            // Schul-Cloud calendar was created before
            if let calendar = self.eventStore.calendar(withIdentifier: calendarIdentifier) {
                updateCalendarAndComplete(calendar)
            } else {
                // calendar identifier is invalid
                userDefaults.removeObject(forKey: self.calendarIdentifierKey)
                userDefaults.synchronize()

                // Let's try to retrieve the calendar by title
                guard let calendar = CalendarHelper.retrieveSchulCloudCalendarByTitle() else {
                    // Schul-Cloud calendar was deleted manually
                    return updateCalendarAndComplete(self.createSchulCloudCalendar())
                }

                self.askUserAboutEvents(in: calendar, on: controller, completion: updateCalendarAndComplete)
            }
        } else {
            // Let's try to retrieve the calendar by title
            guard let calendar = CalendarHelper.retrieveSchulCloudCalendarByTitle() else {
                // Schul-Cloud calendar has to be created
                return updateCalendarAndComplete(self.createSchulCloudCalendar())
            }

            self.askUserAboutEvents(in: calendar, on: controller, completion: updateCalendarAndComplete)
        }
    }

    private static func retrieveSchulCloudCalendarByTitle() -> EKCalendar? {
        let calendars = self.eventStore.calendars(for: .event).filter { (calendar) -> Bool in
            return calendar.title == self.calendarTitle
        }
        return calendars.first
    }

    private static func createSchulCloudCalendar() -> EKCalendar? {
        let subscribedSources = self.eventStore.sources.filter { (source: EKSource) -> Bool in
            return source.sourceType == EKSourceType.subscribed
        }

        guard let source = subscribedSources.first else {
            return nil
        }

        let calendar = EKCalendar(for: .event, eventStore: self.eventStore)
        calendar.title = self.calendarTitle
        calendar.source = source

        do {
            try self.eventStore.saveCalendar(calendar, commit: true)
        } catch {
            return nil
        }

        UserDefaults.standard.set(calendar.calendarIdentifier, forKey: self.calendarIdentifierKey)
        UserDefaults.standard.synchronize()

        return calendar
    }

    private static func askUserAboutEvents(in calendar: EKCalendar, on controller: UIViewController, completion: @escaping (EKCalendar?) -> Void) {
        let alert = UIAlertController(title: "Ein Schul-Cloud Kalender existiert bereits",
                                      message: "Was soll mit den Events in diesem Kalendar passieren?",
                                      preferredStyle: .alert)
        let keepAction = UIAlertAction(title: "Behalten", style: .cancel) { action in
            UserDefaults.standard.set(calendar.calendarIdentifier, forKey: self.calendarIdentifierKey)
            UserDefaults.standard.synchronize()

            completion(calendar)
        }
        let discardAction = UIAlertAction(title: "Verwerfen", style: .default) { action in
            do {
                try eventStore.removeCalendar(calendar, commit: true)
                let newCalendar = self.createSchulCloudCalendar()

                UserDefaults.standard.set(newCalendar?.calendarIdentifier, forKey: self.calendarIdentifierKey)
                UserDefaults.standard.synchronize()

                completion(newCalendar)
            } catch {
                completion(nil)
            }
        }

        alert.addAction(keepAction)
        alert.addAction(discardAction)

        controller.present(alert, animated: true, completion: nil)
    }

}

// calendar sync
extension CalendarHelper {

    typealias FetchResult = Future<Void, SCError>

    static func fetchRemoteEvents() -> Future<[RemoteEvent], SCError> {
        let parameters: Parameters = ["all": true]
        return ApiHelper.request("calendar", parameters: parameters).jsonArrayFuture(keyPath: nil).map { json in
            return json.flatMap {
                do {
                    return try RemoteEvent(object: $0)
                } catch {
                    return nil
                }
            }
        }
    }

    static func createEvent(for remoteEvent: RemoteEvent) -> EKEvent {
        let event = EKEvent(eventStore: self.eventStore)
        return CalendarHelper.update(event: event, for: remoteEvent)
    }

    static func update(event: EKEvent, for remoteEvent: RemoteEvent) -> EKEvent {
        event.title = remoteEvent.title
        event.notes = remoteEvent.description.isEmpty ? nil : remoteEvent.description
        event.location = remoteEvent.location
        event.startDate = remoteEvent.start
        event.endDate = remoteEvent.end
        event.recurrenceRules = remoteEvent.recurringRule?.eventRecurringRules ?? []
        return event
    }

    static func syncEvents(in calendar: EKCalendar) -> Future<Void, SCError> {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = managedObjectContext

        let remoteData = self.fetchRemoteEvents()
        let localData: Future<[EventData], SCError> = Future { complete in
            privateMOC.perform {
                let fetchRequest: NSFetchRequest<EventData> = EventData.fetchRequest()
                do {
                    let data = try privateMOC.fetch(fetchRequest)
                    complete(.success(data))
                } catch let error {
                    complete(.failure(SCError.database(error.localizedDescription)))
                }
            }
        }

        return remoteData.zip(localData).map(privateMOC.perform) { (remoteEvents, localEventData) -> Void in
            var localEvents = localEventData
            for remoteEvent in remoteEvents {
                let filteredEventData = localEvents.filter { eventData -> Bool in
                    eventData.eventId == remoteEvent.id
                }
                if let localEvent = filteredEventData.first {
                    // event already exists locally -> update eventKit
                    if var event = eventStore.event(withIdentifier: localEvent.externalEventId) {
                        event = CalendarHelper.update(event: event, for: remoteEvent)

                        do {
                            try self.eventStore.save(event, span: EKSpan.futureEvents, commit: true)
                            localEvent.eventId = remoteEvent.id
                            localEvent.externalEventId = event.eventIdentifier
                            localEvent.courseId = remoteEvent.courseId
                            if localEvent.hasChanges {
                                try privateMOC.save()
                                try privateMOC.parent?.save()
                            }
                        } catch {
                            print("error saving event")
                        }
                    } else {
                        // calendar deleted locally but we still have the event data

                        let event = CalendarHelper.createEvent(for: remoteEvent)
                        event.calendar = calendar

                        do {
                            try eventStore.save(event, span: .thisEvent, commit: true)
                            // created eventData object
                            localEvent.eventId = remoteEvent.id
                            localEvent.externalEventId = event.eventIdentifier
                            localEvent.courseId = remoteEvent.courseId
                            try privateMOC.save()
                            try privateMOC.parent?.save()
                        } catch {
                            print("error saving event")
                        }
                    }

                    if let index = localEvents.index(of: localEvent) {
                        localEvents.remove(at: index)
                    }
                } else {
                    // event has to be created
                    let event = CalendarHelper.createEvent(for: remoteEvent)
                    event.calendar = calendar

                    do {
                        try eventStore.save(event, span: .thisEvent, commit: true)
                        // created eventData object
                        let newEventData = EventData(context: privateMOC)
                        newEventData.eventId = remoteEvent.id
                        newEventData.externalEventId = event.eventIdentifier
                        newEventData.courseId = remoteEvent.courseId
                        try privateMOC.save()
                        try privateMOC.parent?.save()
                    } catch {
                        print("error saving event")
                    }
                }
            }

            do {
                for localEvent in localEvents {
                    if let event = eventStore.event(withIdentifier: localEvent.externalEventId) {
                        try eventStore.remove(event, span: EKSpan.futureEvents)
                    }
                }
                try eventStore.commit()
            } catch {
                print("Failed to delete remaining events")
            }
        }
    }

}


struct RemoteEvent: Unmarshaling {
    let id: String
    let title: String
    let description: String
    let location: String
    let start: Date
    let end: Date
    let courseId: String?
    let recurringRule: RemoteRecurringRule?

    init(object: MarshaledObject) throws {
        let attributes = try object.value(for: "attributes") as JSONObject
        let included = try? object.value(for: "included") as [JSONObject]
        let id: String = try object.value(for: "id")
        self.id = id
        self.title = try attributes.value(for: "summary")
        self.description = try attributes.value(for: "description")
        self.location = try attributes.value(for: "location")
        self.start = RemoteEvent.dateInCurrentTimeZone(for: try attributes.value(for: "dtstart"))
        self.end = RemoteEvent.dateInCurrentTimeZone(for: try attributes.value(for: "dtend"))
        self.courseId = try attributes.value(for: "x-sc-courseId")

        let recurringRuleData = included?.filter { json in
            return (json["type"] as? String) == "rrule" && (json["id"] as? String) == "\(id)-rrule"
        }.first

        self.recurringRule = try RemoteRecurringRule(object: recurringRuleData)
    }

    private static func dateInCurrentTimeZone(for date: Date) -> Date {
        let utcOffset = TimeZone.autoupdatingCurrent.secondsFromGMT(for: date)
        let utcOffsetChunk = TimeChunk(seconds: utcOffset, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        return date.subtract(utcOffsetChunk)
    }
}

struct RemoteRecurringRule: Unmarshaling {
    let frequency: RemoteRecurrenceFrequency
    let dayOfWeek: RemoteRecurrenceDayOfWeek
    let endDate: Date?
    let interval: Int?

    init(object: MarshaledObject) throws {
        let attributes = try object.value(for: "attributes") as JSONObject
        self.frequency = try attributes.value(for: "freq")
        self.dayOfWeek = try attributes.value(for: "wkst")
        self.endDate = try? attributes.value(for: "until")
        self.interval = try? attributes.value(for: "interval")
    }

    init?(object: MarshaledObject?) throws {
        guard let data = object else { return nil }
        try self.init(object: data)
    }

    var eventRecurringRules: [EKRecurrenceRule] {
        let until: EKRecurrenceEnd?
        if let endDate = self.endDate {
            until = EKRecurrenceEnd(end: endDate)
        } else {
            until = nil
        }
        let rule = EKRecurrenceRule(recurrenceWith: self.frequency.eventRecurrenceFrequency,
                                    interval: self.interval ?? 1,
                                    daysOfTheWeek: [self.dayOfWeek.eventRecurrenceDayOfWeek],
                                    daysOfTheMonth: nil,
                                    monthsOfTheYear: nil,
                                    weeksOfTheYear: nil,
                                    daysOfTheYear: nil,
                                    setPositions: nil,
                                    end: until)
        return [rule]
    }
}

enum RemoteRecurrenceFrequency: String {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"

    var eventRecurrenceFrequency: EKRecurrenceFrequency {
        switch self {
        case .daily:
            return EKRecurrenceFrequency.daily
        case .weekly:
            return EKRecurrenceFrequency.weekly
        case .monthly:
            return EKRecurrenceFrequency.monthly
        case .yearly:
            return EKRecurrenceFrequency.yearly
        }
    }
}

enum RemoteRecurrenceDayOfWeek: String {
    case monday = "MO"
    case tuesday = "TU"
    case wednesday = "WE"
    case thursday = "TH"
    case friday = "FR"
    case saturday = "SA"
    case sunday = "SU"

    var eventRecurrenceDayOfWeek: EKRecurrenceDayOfWeek {
        switch self {
        case .monday:
            return EKRecurrenceDayOfWeek(.monday)
        case .tuesday:
            return EKRecurrenceDayOfWeek(.tuesday)
        case .wednesday:
            return EKRecurrenceDayOfWeek(.wednesday)
        case .thursday:
            return EKRecurrenceDayOfWeek(.thursday)
        case .friday:
            return EKRecurrenceDayOfWeek(.friday)
        case .saturday:
            return EKRecurrenceDayOfWeek(.saturday)
        case .sunday:
            return EKRecurrenceDayOfWeek(.sunday)
        }
    }
}

extension EKEvent {
    var calendarEvent: Event {
        let event = Event()
        event.datePeriod = TimePeriod(beginning: self.startDate, end: self.endDate)
        event.text = self.title
        event.color = UIColor.red
        return event
    }
}
