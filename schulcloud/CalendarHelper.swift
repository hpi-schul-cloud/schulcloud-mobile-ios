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


public struct CalendarHelper {

    static var eventStore: EKEventStore = {
        return EKEventStore()
    }()

    private static let calendarIdentifierKey = "or.schul-cloud.calendar.identifier"
    private static let calendarTitle = "Schul-Cloud"

    static var schulCloudCalendar: EKCalendar?

    static func initializeCalendar(on controller: UIViewController, _ completion: @escaping (EKCalendar?) -> Void ) {
        let userDefaults = UserDefaults.standard
        let updateCalendarAndComplete: (EKCalendar?) -> Void = { calendar in
            self.schulCloudCalendar = calendar
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

// Calendar Sync
// We use EventKit to store the Schul-Cloud events on the device. This allows a better OS integration and supports
// recurring events. However, events of EventKit can't hold all the data we want to store. Therefore we have a separate
// 'EventData' mapping which connects the events of EventKit with the events return by the server API and can hold
// additonal data like the course id.
extension CalendarHelper {

    private static func fetchRemoteEvents() -> Future<[RemoteEvent], SCError> {
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

    private static func fetchLocalEventData(with context: NSManagedObjectContext) -> Future<[EventData], SCError> {
        return Future { complete in
            context.perform {
                let fetchRequest: NSFetchRequest<EventData> = EventData.fetchRequest()
                do {
                    let data = try context.fetch(fetchRequest)
                    complete(.success(data))
                } catch let error {
                    complete(.failure(SCError.database(error.localizedDescription)))
                }
            }
        }
    }

    private static func createEvent(for remoteEvent: RemoteEvent) -> EKEvent {
        let event = EKEvent(eventStore: self.eventStore)
        return CalendarHelper.update(event: event, for: remoteEvent)
    }

    private static func update(event: EKEvent, for remoteEvent: RemoteEvent) -> EKEvent {
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

        let remoteEventsFuture = self.fetchRemoteEvents()
        let localEventDataFuture = self.fetchLocalEventData(with: privateMOC)

        return remoteEventsFuture.zip(localEventDataFuture).map(privateMOC.perform) { (remoteEvents, origLocalEventData) in
            // hold a copy that can be modified
            var localEventData = origLocalEventData

            for remoteEvent in remoteEvents {
                // try to find local event data mapping for remote event
                if let eventData = localEventData.first(where: { $0.eventId == remoteEvent.id }) {
                    // event data mapping already exists locally
                    if var event = eventStore.event(withIdentifier: eventData.externalEventId) {
                        // event was found in EventKit -> update this event and the event data mapping
                        event = CalendarHelper.update(event: event, for: remoteEvent)

                        do {
                            try self.eventStore.save(event, span: EKSpan.futureEvents, commit: false)
                        } catch let error {
                            print("Failed to save event to eventstore: \(error)")
                        }

                        eventData.eventId = remoteEvent.id
                        eventData.externalEventId = event.eventIdentifier
                        eventData.courseId = remoteEvent.courseId
                    } else {
                        // event could not be found in EventKit -> create event and update event data mapping
                        let event = CalendarHelper.createEvent(for: remoteEvent)
                        event.calendar = calendar

                        do {
                            try self.eventStore.save(event, span: .thisEvent, commit: false)
                        } catch let error {
                            print("Failed to save event to eventstore: \(error)")
                        }

                        eventData.eventId = remoteEvent.id
                        eventData.externalEventId = event.eventIdentifier
                        eventData.courseId = remoteEvent.courseId
                    }

                    // remove the event data mapping from the list since it was processed
                    if let index = localEventData.index(of: eventData) {
                        localEventData.remove(at: index)
                    }
                } else {
                    // there is no local event data mapping -> create event and event data mapping
                    let event = CalendarHelper.createEvent(for: remoteEvent)
                    event.calendar = calendar

                    do {
                        try self.eventStore.save(event, span: .thisEvent, commit: false)
                    } catch let error {
                        print("Failed to save event to eventstore: \(error)")
                    }

                    let newEventData = EventData(context: privateMOC)
                    newEventData.eventId = remoteEvent.id
                    newEventData.externalEventId = event.eventIdentifier
                    newEventData.courseId = remoteEvent.courseId
                }
            }

            // delete all unprocessed event data mappings. they must be deleted on the server
            for eventData in localEventData {
                do {
                    if let event = self.eventStore.event(withIdentifier: eventData.externalEventId) {
                        try self.eventStore.remove(event, span: EKSpan.futureEvents)
                    }
                } catch let error {
                    print("Failed to delete event: \(error)")
                }

                privateMOC.delete(eventData)
            }

            // apply changes to the event store
            do {
                try self.eventStore.commit()
            } catch let error {
                print("Failed commit changes to eventstore: \(error)")
            }
        }.flatMap {
            // save event data mappings
            save(privateContext: privateMOC)
        }
    }

}
