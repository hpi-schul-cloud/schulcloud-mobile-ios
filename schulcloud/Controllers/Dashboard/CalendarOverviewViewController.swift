//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import DateToolsSwift
import EventKit
import UIKit

class CalendarOverviewViewController: UIViewController {

    enum State {
        case events(CalendarEvent, CalendarEvent?)
        case noEvents(String)
    }

    @IBOutlet private weak var currentEventName: UILabel!
    @IBOutlet private weak var currentEventLocation: UILabel!
    @IBOutlet private weak var currentEventDate: UILabel!
    @IBOutlet private weak var nextEventName: UILabel!
    @IBOutlet private weak var nextEventLocation: UILabel!
    @IBOutlet private weak var nextEventDate: UILabel!
    @IBOutlet private weak var nextEventDetails: UIStackView!
    @IBOutlet private weak var currentEventProgress: UIProgressView!

    @IBOutlet private weak var eventsOverview: UIStackView!
    @IBOutlet private weak var noEventsView: UILabel!

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateEvents()
        self.syncEvents()
    }

    var todayInterval: DateInterval {
        let now = Date()
        let today = Date(year: now.year, month: now.month, day: now.day)
        let oneDayChunk = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1, weeks: 0, months: 0, years: 0)
        let tomorrow = today + oneDayChunk
        return DateInterval(start: now, end: tomorrow)
    }

    private func syncEvents() {
        CalendarEventHelper.syncEvents().onSuccess { _ in
            self.updateEvents()
        }.onFailure { error in
            log.error("Failed to synchronize events: \(error.description)")
        }
    }

    private func updateStateWith(events: [CalendarEvent]) {
        if events.isEmpty {
            self.state = .noEvents(CalendarOverviewViewController.noEventsMessage)
        } else {
            let firstEvent = events[0]
            let secondEvent = events.count > 1 ? events[1] : nil
            self.state = .events(firstEvent, secondEvent)
        }
    }

    private func updateEvents() {
        switch CalendarEventHelper.fetchCalendarEvents(inContext: CoreDataHelper.viewContext) {
        case let .success(events):
            let filteredEvents = events.filter(inInterval: self.todayInterval)
            self.updateStateWith(events: filteredEvents)
        case let .failure(error):
            self.state = .noEvents(error.localizedDescription)
        }
    }

    func updateUIForCurrentState() {
        switch self.state {
        case let .events(currentEvent, someNextEvent):
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.autoupdatingCurrent
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short

            // set current event labels
            self.currentEventName.text = currentEvent.title
            self.currentEventDate.text = dateFormatter.string(from: currentEvent.start)
            self.currentEventLocation.text = currentEvent.location

            // set progress bar
            let now = Date()
            let progress = now.timeIntervalSince(currentEvent.start) / currentEvent.end.timeIntervalSince(currentEvent.start)
            self.currentEventProgress.progress = Float(progress)

            // set next event labels
            if let nextEvent = someNextEvent {
                self.nextEventName.text = nextEvent.title
                self.nextEventDate.text = dateFormatter.string(from: nextEvent.start)
                self.nextEventLocation.text = nextEvent.location
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

extension CalendarOverviewViewController: ViewHeightDataSource {
    var height: CGFloat { return 200 }
}

extension CalendarOverviewViewController: PermissionInfoDataSource {
    static let requiredPermission = UserPermissions.calendarView
}
