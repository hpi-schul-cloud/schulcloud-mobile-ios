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


public class CalendarHelper {

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

    static func event(for serverEvent: RemoteEvent, in eventStore: EKEventStore) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = serverEvent.title
        event.notes = serverEvent.description.isEmpty ? nil : serverEvent.description
        event.location = serverEvent.location
        event.startDate = serverEvent.start
        event.endDate = serverEvent.end
        return event
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

    init(object: MarshaledObject) throws {
        let attributes = try object.value(for: "attributes") as JSONObject
        self.id = try object.value(for: "id")
        self.title = try attributes.value(for: "summary")
        self.description = try attributes.value(for: "description")
        self.location = try attributes.value(for: "location")
        self.start = RemoteEvent.dateInCurrentTimeZone(for: try attributes.value(for: "dtstart"))
        self.end = RemoteEvent.dateInCurrentTimeZone(for: try attributes.value(for: "dtend"))
        self.courseId = try attributes.value(for: "x-sc-courseId")
    }

    private static func dateInCurrentTimeZone(for date: Date) -> Date {
        let utcOffset = TimeZone.autoupdatingCurrent.secondsFromGMT(for: date)
        let utcOffsetChunk = TimeChunk(seconds: utcOffset, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
        return date.subtract(utcOffsetChunk)
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
