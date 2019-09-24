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
        self.navigationItem.largeTitleDisplayMode = .never

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

    override func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let eventDescriptor = eventView.descriptor as? Event else { return }
        guard let userInfo = eventDescriptor.userInfo as? [String: String] else { return }
        guard let id = userInfo["objectID"] else { return }
        guard let event = self.calendarEvents.first(where: { $0.id == id }) else {
            return
        }

        guard let popupEvent = R.storyboard.calendar.popupEvent() else { return }
        let preferedHeight = popupEvent.preferredContentHeight(width: 500, for: event.description ?? "")
        let height = min(preferedHeight, 500)
        popupEvent.preferredContentSize = CGSize(width: 500, height: height)
        popupEvent.event = event
        popupEvent.modalPresentationStyle = .popover

        self.present(popupEvent, animated: true)

        let popup = popupEvent.popoverPresentationController
        popup?.permittedArrowDirections = [.left, .down, .up]
        popup?.sourceView = self.view
        popup?.delegate = self

        var rect = eventView.convert(eventView.bounds, to: self.view)
        rect.size.width = 200 // makes the popover show on top of the event, since so much horizontal space
        popup?.sourceRect = rect
    }
}

extension CalendarViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .popover
    }
}

extension CalendarEvent {
    var calendarKitEvent: Event {
        let event = Event()
        event.startDate = self.start
        event.endDate = self.end
        var eventText = "\(self.title ?? "Unknown")"
        if let location = self.location, !location.isEmpty {
            eventText += " - \(location)"
        }

        event.text = eventText
        event.color = self.eventColor ?? Brand.default.colors.primary
        event.userInfo = ["objectID": self.id]
        return event
    }
}
