//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CalendarKit
import Common
import DateToolsSwift
import EventKit
import UIKit

class CalendarViewController: DayViewController {

    var calendarEvents: [CalendarEvent] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Kalender"
        if #available(iOS 11, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        self.customizeCalendarView()

        // scroll to current time
        let date = Date()
        let cal = Calendar.current
        let hour = Float(cal.component(.hour, from: date))
        let minute = Float(cal.component(.minute, from: date)) / 60
        self.dayView.scrollTo(hour24: hour - 1 + minute)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.syncEvents()
    }

    private func customizeCalendarView() {
        let offWhite = UIColor(white: 0.98, alpha: 1.0)

        let style = CalendarStyle()
        style.header.backgroundColor = Brand.default.colors.primary
        style.header.daySymbols.weekDayColor = offWhite
        style.header.daySymbols.weekendColor = Brand.default.colors.primary.blend(with: offWhite)
        style.header.swipeLabel.textColor = offWhite
        style.header.daySelector.activeTextColor = Brand.default.colors.primary
        style.header.daySelector.selectedBackgroundColor = Brand.default.colors.primary.blend(with: offWhite, intensity: 0.75)
        style.header.daySelector.weekendTextColor = Brand.default.colors.primary.blend(with: offWhite)
        style.header.daySelector.inactiveTextColor = offWhite
        style.header.daySelector.todayInactiveTextColor = .darkText
        style.header.daySelector.todayActiveBackgroundColor = Brand.default.colors.primary.blend(with: offWhite, intensity: 0.9)
        self.dayView.updateStyle(style)
    }

    private func syncEvents() {
        // Assumes event where already fetched
        switch CalendarEventHelper.fetchCalendarEvents(inContext: CoreDataHelper.viewContext) {
        case let .success(events):
            self.calendarEvents = events
            self.reloadData()
        case let .failure(error):
            log.error("Fetching calendar events failed", error: error)
        }
    }

    private func showCalendarPermissionErrorAlert() {
        let alert = UIAlertController(title: "Kalenderfehler",
                                      message: "Der Schul-Cloud-Kalender konnte nicht geladen werden.",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }

    // MARK: DayViewDataSource
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        let startDate = Date(year: date.year, month: date.month, day: date.day)
        let oneDayLater = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1, weeks: 0, months: 0, years: 0)
        let endDate = startDate + oneDayLater
        let interval = DateInterval(start: startDate, end: endDate)

        return self.calendarEvents.filter(inInterval: interval).map { $0.calendarKitEvent }
    }
}

extension CalendarEvent {
    var calendarKitEvent: Event {
        let event = Event()
        event.startDate = self.start
        event.endDate = self.end
        var eventText = "\(self.title ?? "Unknown")"
        if let location = self.location {
            eventText += " - \(location)"
        }

        event.text = eventText
        event.color = self.eventColor ?? Brand.default.colors.primary
        return event
    }
}
