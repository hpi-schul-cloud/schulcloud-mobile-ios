//
//  CoreDataObserver.swift
//  schulcloud
//
//  Created by Max Bothe on 20.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import CoreData

class CoreDataObserver {

    static let shared = CoreDataObserver()

    func startObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: CoreDataHelper.viewContext)
    }

    func stopObserving() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: CoreDataHelper.viewContext)
    }

    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty {
            if CalendarEventHelper.EventKitSettings.current.shouldSynchonize {
                let insertedEvents = inserts.flatMap { $0 as? EventData }
                if !insertedEvents.isEmpty {
                    CalendarEventHelper.requestCalendarPermission().andThen { _ in
                        if let calendar = CalendarEventHelper.fetchCalendar() ?? CalendarEventHelper.createCalendar() {
                            try? CalendarEventHelper.push(events: insertedEvents.map { $0.calendarEvent }, to: calendar)
                        }
                    }
                }
            }
        }

        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updates.isEmpty {
            if CalendarEventHelper.EventKitSettings.current.shouldSynchonize {
                let updatedEvents = updates.flatMap { $0 as? EventData }
                if !updatedEvents.isEmpty {
                    CalendarEventHelper.requestCalendarPermission().andThen { _ in
                        if let calendar = CalendarEventHelper.fetchCalendar() ?? CalendarEventHelper.createCalendar() {
                            try? CalendarEventHelper.push(events: updatedEvents.map { $0.calendarEvent }, to: calendar)
                        }
                    }
                }
            }
        }

        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletes.isEmpty {
            if CalendarEventHelper.EventKitSettings.current.shouldSynchonize {
                let deletedEvents = deletes.flatMap { $0 as? EventData }
                if !deletedEvents.isEmpty {
                    CalendarEventHelper.requestCalendarPermission().andThen { _ in
                        try? CalendarEventHelper.remove(events: deletedEvents.map { $0.calendarEvent })
                    }
                }
            }
        }
    }

}
