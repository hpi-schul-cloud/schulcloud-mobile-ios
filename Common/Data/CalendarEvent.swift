//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation

extension EventData {
    var calendarEvent: CalendarEvent {
        return CalendarEvent(eventData: self)
    }
}

public struct CalendarEvent {

    static var didFinishedProcessingEventName = "CalendarEventDidFinishProcessingEventName"

    public let id: String
    public let title: String?
    public let description: String?
    public let location: String?
    public let start: Date
    public let end: Date
    public let recurrenceRule: RecurrenceRule?
    public let eventColor: UIColor?

    let coreDataID: NSManagedObjectID?

    var eventKitID: String? {
        didSet {
            if let objectID = self.coreDataID, let event = CoreDataHelper.viewContext.object(with: objectID) as? EventData {
                event.ekIdentifier = self.eventKitID
            }
        }
    }

    public struct RecurrenceRule {

        public let frequency: Frequency
        public let dayOfTheWeek: DayOfTheWeek
        public let endDate: Date?
        public let interval: Int

        public enum Frequency: String { // swiftlint:disable:this nesting
            case daily = "DAILY"
            case weekly = "WEEKLY"
            case monthly = "MONTHLY"
            case yearly = "YEARLY"
        }

        public enum DayOfTheWeek: String { // swiftlint:disable:this nesting
            case monday = "MO"
            case tuesday = "TU"
            case wednesday = "WE"
            case thursday = "TH"
            case friday = "FR"
            case saturday = "SA"
            case sunday = "SU"
        }
    }

    init(id: String,
         title: String?,
         description: String?,
         location: String?,
         startDate: Date,
         endDate: Date,
         rule: RecurrenceRule?,
         color: UIColor?,
         coreDataID: NSManagedObjectID?,
         ekEventID: String?) {
        self.id = id
        self.title = title
        self.description = description
        self.location = location
        self.start = startDate
        self.end = endDate
        self.recurrenceRule = rule
        self.eventColor = color
        self.coreDataID = coreDataID
        eventKitID = ekEventID
    }

    init(eventData: EventData) {
        var rule: RecurrenceRule?

        var startDate = eventData.start as Date
        var endDate = eventData.end as Date

        if  let rfrequency = eventData.rrFrequency,
            let frequency = RecurrenceRule.Frequency(rawValue: rfrequency),
            let rdayOfWeek = eventData.rrDayOfWeek,
            let dayOfWeek = RecurrenceRule.DayOfTheWeek(rawValue: rdayOfWeek) {

            rule = RecurrenceRule(frequency: frequency,
                                  dayOfTheWeek: dayOfWeek,
                                  endDate: eventData.rrEndDate as Date?,
                                  interval: Int(eventData.rrInterval))

            // We receive date that starts at the beginning of the week when a recurring rule is specified
            // with the dayOfTheWeek property set to tell us which day the event occur
            // e.g. Start date set to monday 28.08.2017 with dayOfTheWeek == Tuesday, the event effectively starting Tuesday 29.08.2017
            //
            // For convenience, when a recurring rule is given, we align the start date to be the actual starting date of the event
            let internalEventWeekDay = Calendar.current.dateComponents([.weekday], from: startDate).weekday ?? 0

            // we manually assign weekday indexes for each day, sunday being exception because in a german week sunday is the last day and not the first
            // to make things easy we simply assign sunday 8 (1 + 7days)

            var dayOfWeekIndex: Int = {
                switch rule!.dayOfTheWeek {
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
            // we always move to the next day with dayOfWeek (never go back in time to create event
            if dayOfWeekIndex < internalEventWeekDay { dayOfWeekIndex += 7 }
            dateComponent.day = dayOfWeekIndex - internalEventWeekDay // calculate how many days to move foward the dates

            startDate = Calendar.current.date(byAdding: dateComponent, to: startDate)!
            endDate = Calendar.current.date(byAdding: dateComponent, to: endDate)!
        }

        self.init(id: eventData.id,
                  title: eventData.title,
                  description: eventData.detail,
                  location: eventData.location,
                  startDate: startDate,
                  endDate: endDate,
                  rule: rule,
                  color: UIColor(hexString: eventData.course?.colorString ?? ""),
                  coreDataID: eventData.objectID,
                  ekEventID: eventData.ekIdentifier)
    }
}

// MARK: Date sequence for event
extension CalendarEvent {

    var dates: EventSequence {
        return EventSequence(calendarEvent: self, calculatedDate: [])
    }

    /**
     Correspond to a list of all of occurrences of an event, based on its recurence rules.
     */
    struct EventSequence: Sequence {

        var calendarEvent: CalendarEvent
        var calculatedDate: [CalendarEvent]

        func makeIterator() -> EventDateIterator {
            return EventDateIterator(self)
        }
    }

    /**
     Iterator for EventSequence
     */
    struct EventDateIterator: IteratorProtocol {
        var sequence: EventSequence
        var iteration: Int = 0 // work as an index, to avoid recalculating all intermediate date

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

            var dateComponents = DateComponents()

            if let recurrenceRule = event.recurrenceRule {

                let addedValue = Int(recurrenceRule.interval) * self.iteration

                switch recurrenceRule.frequency {
                case .daily:
                    dateComponents.day = addedValue
                case .weekly:
                    dateComponents.weekOfYear = addedValue
                case .monthly:
                    dateComponents.month = addedValue
                case .yearly:
                    dateComponents.year = addedValue
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
                                       color: event.eventColor,
                                       coreDataID: event.coreDataID,
                                       ekEventID: event.eventKitID)

            sequence.calculatedDate.append(result)

            self.iteration += 1
            return result
        }
    }
}

extension Array where Array.Element == CalendarEvent {

    /// Return the all occurences of a certain event given an interval.
    /// - Parameter interval: the open-ended interval
    /// - Returns: The list of occurences of an event in the open-ended interval.
    public func filter(inInterval interval: DateInterval) -> [CalendarEvent] {
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
        }.compactMap { $0 }.sorted { event1, event2 -> Bool in
            event1.start < event2.start
        }
    }
}
