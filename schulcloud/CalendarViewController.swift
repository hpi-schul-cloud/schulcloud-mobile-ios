import UIKit
import EventKit
import CalendarKit
import DateToolsSwift


class CalendarViewController: DayViewController {
    
    var calendarEvents : [CalendarEvent] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false

        self.syncEvents()

        // scroll to current time
        let date = Date()
        let cal = Calendar.current
        let hour = Float(cal.component(.hour, from: date))
        let minute = Float(cal.component(.minute, from: date)) / 60
        self.dayView.scrollTo(hour24: hour - 1 + minute)
    }

    private func syncEvents() {
        // Assumes event where already fetched
        CalendarEventHelper.fetchCalendarEvent(inContext: managedObjectContext)
        .onSuccess { events in
            self.calendarEvents = events
            self.reloadData()
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

        return self.calendarEvents.filteredEvents(inInterval: interval).map { $0.calendarKitEvent }
    }
}

extension CalendarEvent {
    var calendarKitEvent : Event {
        let event = Event()
        event.datePeriod = TimePeriod(beginning: self.start, end: self.end)
        event.text = self.title
        event.color = UIColor.red
        return event
    }
}
