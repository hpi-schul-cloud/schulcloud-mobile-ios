//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData

public class CoreDataObserver {

    public static let shared = CoreDataObserver()

    public func startObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: CoreDataHelper.viewContext)
    }

    public func stopObserving() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: CoreDataHelper.viewContext)
    }

    @objc public func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        var courseChanges: [String: [(id: String, name: String)]] = [:]

        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty {
            if CalendarEventHelper.EventKitSettings.current.shouldSynchonize {
                let insertedEvents = inserts.compactMap { $0 as? EventData }
                if !insertedEvents.isEmpty {
                    CalendarEventHelper.requestCalendarPermission().onComplete { _ in
                        if let calendar = CalendarEventHelper.fetchCalendar() ?? CalendarEventHelper.createCalendar() {
                            try? CalendarEventHelper.push(events: insertedEvents.map { $0.calendarEvent }, to: calendar)
                        }
                    }
                }
            }

            let courses = inserts.compactMap { $0 as? Course }
            if !courses.isEmpty {
                courseChanges[NSInsertedObjectsKey] = courses.map { (id: $0.id, name: $0.name) }
            }
        }

        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updates.isEmpty {
            if CalendarEventHelper.EventKitSettings.current.shouldSynchonize {
                let updatedEvents = updates.compactMap { $0 as? EventData }
                if !updatedEvents.isEmpty {
                    CalendarEventHelper.requestCalendarPermission().onComplete { _ in
                        if let calendar = CalendarEventHelper.fetchCalendar() ?? CalendarEventHelper.createCalendar() {
                            try? CalendarEventHelper.push(events: updatedEvents.map { $0.calendarEvent }, to: calendar)
                        }
                    }
                }
            }

            let courses = updates.compactMap { $0 as? Course }
            if !courses.isEmpty {
                courseChanges[NSUpdatedObjectsKey] = courses.map { (id: $0.id, name: $0.name) }
            }
        }

        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletes.isEmpty {
            if CalendarEventHelper.EventKitSettings.current.shouldSynchonize {
                let deletedEvents = deletes.compactMap { $0 as? EventData }
                if !deletedEvents.isEmpty {
                    CalendarEventHelper.requestCalendarPermission().onComplete { _ in
                        try? CalendarEventHelper.remove(events: deletedEvents.map { $0.calendarEvent })
                    }
                }
            }

            let courses = deletes.compactMap { $0 as? Course }
            if !courses.isEmpty {
                courseChanges[NSDeletedObjectsKey] = courses.map { (id: $0.id, name: $0.name) }
            }
        }

        if let refreshed = userInfo[NSRefreshedObjectsKey] as? Set<NSManagedObject>, !refreshed.isEmpty {
            if CalendarEventHelper.EventKitSettings.current.shouldSynchonize {
                let refreshedEvents = refreshed.compactMap { $0 as? EventData }
                if !refreshedEvents.isEmpty {
                    CalendarEventHelper.requestCalendarPermission().onComplete { _ in
                        if let calendar = CalendarEventHelper.fetchCalendar() ?? CalendarEventHelper.createCalendar() {
                            try? CalendarEventHelper.push(events: refreshedEvents.map { $0.calendarEvent }, to: calendar)
                        }
                    }
                }
            }

            let courses = refreshed.compactMap { $0 as? Course }
            if !courses.isEmpty {
                courseChanges[NSRefreshedObjectsKey] = courses.map { (id: $0.id, name: $0.name) }
            }
        }

        if !courseChanges.isEmpty {
            FileHelper.processCourseUpdates(changes: courseChanges)
        }
    }

}
