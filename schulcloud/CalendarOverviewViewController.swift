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

class CalendarOverviewViewController: UIViewController {
    enum State {
        case events(EKEvent, EKEvent?)
        case noEvents(String)
    }

    @IBOutlet weak var currentEventName: UILabel!
    @IBOutlet weak var currentEventLocation: UILabel!
    @IBOutlet weak var currentEventDate: UILabel!
    @IBOutlet weak var nextEventName: UILabel!
    @IBOutlet weak var nextEventLocation: UILabel!
    @IBOutlet weak var nextEventDate: UILabel!
    @IBOutlet weak var currentEventProgress: UIProgressView!

    @IBOutlet weak var eventsOverview: UIStackView!
    @IBOutlet weak var noEventsView: UILabel!

    static let noEventsMessage = "Für heute gibt es keine weiteren Termine."
    static let noPermissionMessage = "Fehlende Kalenderberechtigung"

    var state: CalendarOverviewViewController.State = .noEvents(CalendarOverviewViewController.noEventsMessage) {
        didSet {
            self.updateUIForCurrentState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            CalendarHelper.requestCalendarPermission().onSuccess {
                self.syncEvents()
            }.onFailure { error in
                self.state = .noEvents(CalendarOverviewViewController.noPermissionMessage)
            }
        case .authorized:
            self.syncEvents()
        case .restricted: fallthrough
        case .denied:
            self.state = .noEvents(CalendarOverviewViewController.noPermissionMessage)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateEvents()
    }

    private func syncEvents() {
        let syncEvents: (EKCalendar?) -> Void = { someCalendar in
            guard let calendar = someCalendar else { return }
            CalendarHelper.syncEvents(in: calendar).onSuccess {
                self.updateEvents()
            }
        }

        if CalendarHelper.schulCloudCalendarWasInitialized {
            syncEvents(CalendarHelper.schulCloudCalendar)
        } else {
            CalendarHelper.initializeCalendar(on: self, completion: syncEvents)
        }
    }

    private func updateEvents() {
        let fetchEvents: (EKCalendar?) -> Void = { someCalendar in
            guard EKEventStore.authorizationStatus(for: .event) == .authorized else {
                self.state = .noEvents(CalendarOverviewViewController.noPermissionMessage)
                return
            }
            guard let calendar = someCalendar else { return }

            let now = Date().dateInUTCTimeZone()
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
            self.currentEventName.text = currentEvent.title
            self.currentEventDate.text = dateFormatter.string(from: currentEvent.startDate)
            self.currentEventLocation.text = currentEvent.location

            // set progress bar
            let now = Date().dateInUTCTimeZone()
            let progress = now.timeIntervalSince(currentEvent.startDate) / currentEvent.endDate.timeIntervalSince(currentEvent.startDate)
            self.currentEventProgress.progress = Float(progress)

            // set next event labels
            if let nextEvent = someNextEvent {
                self.nextEventName.text = nextEvent.title
                self.nextEventDate.text = dateFormatter.string(from: nextEvent.startDate.dateInCurrentTimeZone())
                self.nextEventLocation.text = nextEvent.location
                self.nextEventDate.isHidden = false
                self.nextEventLocation.isHidden = false
            } else {
                self.nextEventName.text = "keine weiteren Termine"
                self.nextEventDate.isHidden = true
                self.nextEventLocation.isHidden = true
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
