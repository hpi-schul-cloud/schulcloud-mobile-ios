//
//  RemoteEvent.swift
//  schulcloud
//
//  Created by Max Bothe on 24.08.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation

import EventKit

import Marshal
import DateToolsSwift

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

        let recurringRuleData = included?.first { json in
            return (json["type"] as? String) == "rrule" && (json["id"] as? String) == "\(id)-rrule"
        }

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
