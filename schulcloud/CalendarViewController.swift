import UIKit
import EventKit
import CalendarKit
import DateToolsSwift

enum SelectedStyle {
    case Dark
    case Light
}

class CalendarViewController: DayViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false

        // TODO: check auth status EKEventStore.authorizationStatus(for:.event)
        CalendarHelper.eventStore.requestAccess(to: EKEntityType.event) { (granted, error) in
            guard granted && error == nil else {
                let alert = UIAlertController(title: "Kalenderfehler", message: "Der Schul-Cloud-Kalender konnte nicht geladen werden.", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return
            }

            // init calendar here
            CalendarHelper.initializeCalendar(on: self) { someCalendar in
                guard let calendar = someCalendar else { return }
                CalendarHelper.syncEvents(in: calendar).onSuccess {
                    self.reloadData()
                }
            }
        }

        // scroll to current time
        let date = Date()
        let cal = Calendar.current
        let hour = Float(cal.component(.hour, from: date))
        let minute = Float(cal.component(.minute, from: date)) / 60
        self.dayView.scrollTo(hour24: hour - 1 + minute)

    }

    private func syncCalendarEvents() {
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return }

        CalendarHelper.initializeCalendar(on: self) { someCalendar in
            guard let calendar = someCalendar else { return }
            CalendarHelper.syncEvents(in: calendar).onSuccess {
                self.reloadData()
            }
        }
    }
    
    // MARK: DayViewDataSource
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return [] }
        guard let calendar = CalendarHelper.schulcloudCalendar else { return [] }

        let startDate = Date(year: date.year, month: date.month, day: date.day)
        let oneDayLater = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1, weeks: 0, months: 0, years: 0)
        let endDate = startDate + oneDayLater
        let predicate = CalendarHelper.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
        return CalendarHelper.eventStore.events(matching: predicate).map { event in event.calendarEvent }
    }
    
    // MARK: DayViewDelegate
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        print("Event has been selected: \(descriptor) \(String(describing: descriptor.userInfo))")
    }
    
    override func dayViewDidLongPressEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        print("Event has been longPressed: \(descriptor) \(String(describing: descriptor.userInfo))")
    }
    
    override func dayView(dayView: DayView, willMoveTo date: Date) {
        //    print("DayView = \(dayView) will move to: \(date)")
    }
    
    override func dayView(dayView: DayView, didMoveTo date: Date) {
        //    print("DayView = \(dayView) did move to: \(date)")
    }
}
