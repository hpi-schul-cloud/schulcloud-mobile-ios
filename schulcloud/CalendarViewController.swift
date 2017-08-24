import UIKit
import EventKit
import CalendarKit
import DateToolsSwift


class CalendarViewController: DayViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false

        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            CalendarHelper.requestCalendarPermission().onSuccess {
                self.syncEvents()
            }.onFailure { error in
                self.showCalendarPermissionErrorAlert()
            }
        case .authorized:
            self.syncEvents()
        case .restricted: fallthrough
        case .denied:
            self.showCalendarPermissionErrorAlert()
        }

        // scroll to current time
        let date = Date()
        let cal = Calendar.current
        let hour = Float(cal.component(.hour, from: date))
        let minute = Float(cal.component(.minute, from: date)) / 60
        self.dayView.scrollTo(hour24: hour - 1 + minute)
    }

    private func syncEvents() {
        let syncEvents: (EKCalendar?) -> Void = { someCalendar in
            guard let calendar = someCalendar else { return }
            CalendarHelper.syncEvents(in: calendar).onSuccess {
                DispatchQueue.main.async {
                    self.reloadData()
                }
            }
        }

        if CalendarHelper.schulCloudCalendarWasInitialized {
            syncEvents(CalendarHelper.schulCloudCalendar)
        } else {
            CalendarHelper.initializeCalendar(on: self, completion: syncEvents)
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
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return [] }
        guard let calendar = CalendarHelper.schulCloudCalendar else { return [] }

        let startDate = Date(year: date.year, month: date.month, day: date.day)
        let oneDayLater = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1, weeks: 0, months: 0, years: 0)
        let endDate = startDate + oneDayLater
        let predicate = CalendarHelper.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
        return CalendarHelper.eventStore.events(matching: predicate).map { event in event.calendarEvent }
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
