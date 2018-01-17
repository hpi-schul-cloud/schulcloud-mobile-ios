//
//  CalendarOverviewViewController.swift
//  schulcloud
//
//  Created by Max Bothe on 07.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import EventKit
import DateToolsSwift

protocol DisplayEvent {
    var displayTitle: String { get }
    var displayLocation  : String { get }
    var displayStartDate : Date { get }
    var displayEndDate   : Date { get }
}

extension EKEvent : DisplayEvent {
    
    var displayTitle: String {
        return self.title
    }
    var displayLocation  : String {
        return self.location!
    }
    var displayStartDate : Date {
        return self.startDate
    }
    var displayEndDate   : Date {
        return self.endDate
    }
}

extension CalendarEvent : DisplayEvent {
    
    var displayTitle : String {
        return self.title
    }
    
    var displayLocation : String {
        return self.location
    }
    
    var displayStartDate : Date {
        return self.start
    }
    
    var displayEndDate : Date {
        return self.end
    }
}

class CalendarOverviewViewController: UIViewController {
    

    enum State {
        case events(DisplayEvent, DisplayEvent?)
        case noEvents(String)
    }

    @IBOutlet weak var currentEventName: UILabel!
    @IBOutlet weak var currentEventLocation: UILabel!
    @IBOutlet weak var currentEventDate: UILabel!
    @IBOutlet weak var nextEventName: UILabel!
    @IBOutlet weak var nextEventLocation: UILabel!
    @IBOutlet weak var nextEventDate: UILabel!
    @IBOutlet weak var nextEventDetails: UIStackView!
    @IBOutlet weak var currentEventProgress: UIProgressView!

    @IBOutlet weak var eventsOverview: UIStackView!
    @IBOutlet weak var noEventsView: UILabel!

    static let noEventsMessage = "Für heute gibt es keine weiteren Termine."
    static let noPermissionMessage = "Fehlende Kalenderberechtigung"
    static let loadingMessage = "Lädt ..."

    var state: CalendarOverviewViewController.State = .noEvents(CalendarOverviewViewController.loadingMessage) {
        didSet {
            self.updateUIForCurrentState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.state = .noEvents(CalendarOverviewViewController.loadingMessage)

        self.syncEvents()
        /*
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            CalendarHelper.requestCalendarPermission().onSuccess {
                self.syncEvents()
            }.onFailure { error in
                self.state = .noEvents(CalendarOverviewViewController.noPermissionMessage)
            }
        case .authorized:
            self.syncEvents()
        case .restricted, .denied:
            self.state = .noEvents(CalendarOverviewViewController.noPermissionMessage)
        }
        */
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateEvents()
    }

    private func syncEvents() {
        
        CalendarEventHelper.synchronizeEvent()
        .map { events -> [CalendarEvent] in
        
            // filter all event left coming up today
            let now = Date()
            let today = Date(year:now.year, month: now.month, day: now.day)
            let oneDayChunk = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1, weeks: 0, months: 0, years: 0)
            let tomorrow = today + oneDayChunk
            
            let interval = DateInterval(start: now, end: tomorrow)

            return events.filter { event in
                var dateIterator = event.dates.makeIterator()
                while let (startEventDate, _) = dateIterator.next(),
                    startEventDate < tomorrow {
                        if interval.contains(startEventDate) {
                            return true
                        }
                }
                return false
            }
        }
        .onSuccess { self.updateStartWith(events: $0) }
        .onFailure { error in
            print("Failed to synchronize events: \(error.description)")
        }
        
        /*
        let syncEvents: (EKCalendar?) -> Void = { someCalendar in
            guard let calendar = someCalendar else {
                log.error("Failed to retrieve Schul-Cloud calendar")
                return
            }
            CalendarHelper.syncEvents(in: calendar).onSuccess {
                self.updateEvents()
            }.onFailure { error in
                log.error(error)
            }
        }

        if CalendarHelper.schulCloudCalendarWasInitialized {
            syncEvents(CalendarHelper.schulCloudCalendar)
        } else {
            CalendarHelper.initializeCalendar(on: self, completion: syncEvents)
        }
        */
    }

    private func updateStartWith(events: [CalendarEvent]) {
        if events.isEmpty {
            self.state = .noEvents(CalendarOverviewViewController.noEventsMessage)
        } else {
            let firstEvent = events[0]
            let secondEvent = events.count > 1 ? events[1] : nil
            self.state = .events(firstEvent, secondEvent)
        }
    }

    private func updateEvents() {
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return }

        let fetchEvents: (EKCalendar?) -> Void = { someCalendar in
            guard EKEventStore.authorizationStatus(for: .event) == .authorized else {
                self.state = .noEvents(CalendarOverviewViewController.noPermissionMessage)
                return
            }
            guard let calendar = someCalendar else { return }

            let now = Date()
            let today = Date(year: now.year, month: now.month, day: now.day)
            let oneDayLater = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1, weeks: 0, months: 0, years: 0)
            let endDate = today + oneDayLater
            let predicate = CalendarHelper.eventStore.predicateForEvents(withStart: now, end: endDate, calendars: [calendar])
            let events = CalendarHelper.eventStore.events(matching: predicate)  // fetches also event at current time

            if let currentEvent = events.first {
                let nextEvent: EKEvent? = events.count > 1 ? events[1] : nil
                self.state = .events(currentEvent, nextEvent)
            } else {
                self.state = .noEvents(CalendarOverviewViewController.noEventsMessage)
            }
        }

        if CalendarHelper.schulCloudCalendarWasInitialized {
            fetchEvents(CalendarHelper.schulCloudCalendar)
        } else {
            CalendarHelper.initializeCalendar(on: self, completion: fetchEvents)
        }
    }

    func updateUIForCurrentState() {
        switch self.state {
        case .events(let currentEvent, let someNextEvent):
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.autoupdatingCurrent
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short

            // set current event labels
            self.currentEventName.text = currentEvent.displayTitle
            self.currentEventDate.text = dateFormatter.string(from: currentEvent.displayStartDate)
            self.currentEventLocation.text = currentEvent.displayLocation

            // set progress bar
            let now = Date().dateInUTCTimeZone()
            let progress = now.timeIntervalSince(currentEvent.displayStartDate) / currentEvent.displayEndDate.timeIntervalSince(currentEvent.displayStartDate)
            self.currentEventProgress.progress = Float(progress)

            // set next event labels
            if let nextEvent = someNextEvent {
                self.nextEventName.text = nextEvent.displayTitle
                self.nextEventDate.text = dateFormatter.string(from: nextEvent.displayStartDate.dateInCurrentTimeZone())
                self.nextEventLocation.text = nextEvent.displayLocation
                self.nextEventDetails.isHidden = false
            } else {
                self.nextEventName.text = "keine weiteren Termine"
                self.nextEventDetails.isHidden = true
            }

            self.eventsOverview.isHidden = false
            self.noEventsView.isHidden = true
        case .noEvents(let message):
            self.noEventsView.text = message
            self.eventsOverview.isHidden = true
            self.noEventsView.isHidden = false
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}
