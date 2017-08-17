import UIKit
import EventKit
import CalendarKit
import DateToolsSwift

enum SelectedStyle {
    case Dark
    case Light
}

class CalendarViewController: DayViewController {

    private static let calendarIdentifierKey = "or.schul-cloud.calendar.identifier"
    private static let calendarTitle = "Schul-Cloud"
    
//    var data = [["Breakfast at Tiffany's",
//                 "New York, 5th avenue"],
//
//                ["Workout",
//                 "Tufteparken"],
//
//                ["Meeting with Alex",
//                 "Home",
//                 "Oslo, Tjuvholmen"],
//
//                ["Beach Volleyball",
//                 "Ipanema Beach",
//                 "Rio De Janeiro"],
//
//                ["WWDC",
//                 "Moscone West Convention Center",
//                 "747 Howard St"],
//
//                ["Google I/O",
//                 "Shoreline Amphitheatre",
//                 "One Amphitheatre Parkway"],
//
//                ["✈️️ to Svalbard ❄️️❄️️❄️️❤️️",
//                 "Oslo Gardermoen"],
//
//                ["💻📲 Developing CalendarKit",
//                 "🌍 Worldwide"],
//
//                ["Software Development Lecture",
//                 "Mikpoli MB310",
//                 "Craig Federighi"],
//
//                ]
//
//    var colors = [UIColor.blue,
//                  UIColor.yellow,
//                  UIColor.black,
//                  UIColor.green,
//                  UIColor.red]

    var currentStyle = SelectedStyle.Light

    var eventStore: EKEventStore = {
        return EKEventStore()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false



        // TODO: check auth status EKEventStore.authorizationStatus(for:.event)
        self.eventStore.requestAccess(to: EKEntityType.event) { (granted, error) in
            guard granted && error == nil, let calendar = self.schulcloudCalendar else {
                let alert = UIAlertController(title: "Kalenderfehler", message: "Der Schul-Cloud-Kalender konnte nicht geladen werden.", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return
            }

            // TODO: sync data here
            self.syncCalendarEvents(with: calendar)
            DispatchQueue.main.async {
                self.reloadData()
            }
        }

        // scroll to current time
        let date = Date()
        let cal = Calendar.current
        let hour = Float(cal.component(.hour, from: date))
        let minute = Float(cal.component(.minute, from: date)) / 60
        self.dayView.scrollTo(hour24: hour - 1 + minute)

    }

    private var schulcloudCalendar: EKCalendar? {
        let userDefaults = UserDefaults.standard

        if let calendarIdentifier = userDefaults.string(forKey: CalendarViewController.calendarIdentifierKey) {
            // Schul-Cloud calendar was created before
            if let calendar = self.eventStore.calendar(withIdentifier: calendarIdentifier) {
                return calendar
            } else {
                // calendar identifier is invalid
                userDefaults.removeObject(forKey: CalendarViewController.calendarIdentifierKey)
                userDefaults.synchronize()

                // Let's try to retrieve the calendar by title
                guard let calendar = self.retrieveSchulCloudCalendarByTitle() else {
                    // Schul-Cloud calendar was deleted manually
                    return self.createSchulCloudCalendar()
                }

                // store new calendar identifier
                userDefaults.set(calendar.calendarIdentifier, forKey: CalendarViewController.calendarIdentifierKey)
                userDefaults.synchronize()

                return calendar
            }
        } else {
            // Let's try to retrieve the calendar by title
            guard let calendar = self.retrieveSchulCloudCalendarByTitle() else {
                // Schul-Cloud calendar has to be created
                return self.createSchulCloudCalendar()
            }

            // Schul-Cloud app was deleted before, but the calendar was not. So update the calendar identifier
            userDefaults.set(calendar.calendarIdentifier, forKey: CalendarViewController.calendarIdentifierKey)
            userDefaults.synchronize()

            return calendar
        }
    }

    private func retrieveSchulCloudCalendarByTitle() -> EKCalendar? {
        let calendars = self.eventStore.calendars(for: .event).filter { (calendar) -> Bool in
            return calendar.title == CalendarViewController.calendarTitle
        }
        return calendars.first
    }

    private func createSchulCloudCalendar() -> EKCalendar? {
        let subscribedSources = self.eventStore.sources.filter { (source: EKSource) -> Bool in
            return source.sourceType == EKSourceType.subscribed
        }

        guard let source = subscribedSources.first else {
            return nil
        }

        let calendar = EKCalendar(for: .event, eventStore: self.eventStore)
        calendar.title = CalendarViewController.calendarTitle
        calendar.source = source

        do {
            try self.eventStore.saveCalendar(calendar, commit: true)
        } catch {
            return nil
        }

        UserDefaults.standard.set(calendar.calendarIdentifier, forKey: CalendarViewController.calendarIdentifierKey)
        UserDefaults.standard.synchronize()

        return calendar
    }

    private func syncCalendarEvents(with calendar: EKCalendar) {
        CalendarHelper.fetchEventsFromServer().onSuccess { serverEvents in
            print(serverEvents)
            for serverEvent in serverEvents {
                let event = CalendarHelper.event(for: serverEvent, in: self.eventStore)
                event.calendar = calendar

                do {
                    try self.eventStore.save(event, span: .thisEvent, commit: true)
                } catch {
                    print("error saving event")
                }

                // create in app mapping here
            }
        }.onFailure { error in
            print("Failed to fetch calendar event - with error: \(error)")
        }
    }
    
        // MARK: DayViewDataSource
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
//        var date = date.add(TimeChunk(seconds: 0,
//                                      minutes: 0,
//                                      hours: Int(arc4random_uniform(10) + 5),
//                                      days: 0,
//                                      weeks: 0,
//                                      months: 0,
//                                      years: 0))
//        var events = [Event]()
//
//        for i in 0...5 {
//            let event = Event()
//            let duration = Int(arc4random_uniform(160) + 60)
//            let datePeriod = TimePeriod(beginning: date,
//                                        chunk: TimeChunk(seconds: 0,
//                                                         minutes: duration,
//                                                         hours: 0,
//                                                         days: 0,
//                                                         weeks: 0,
//                                                         months: 0,
//                                                         years: 0))
//
//            event.datePeriod = datePeriod
//            var info = data[Int(arc4random_uniform(UInt32(data.count)))]
//            info.append("\(datePeriod.beginning!.format(with: "HH:mm")) - \(datePeriod.end!.format(with: "HH:mm"))")
//            event.text = info.reduce("", {$0 + $1 + "\n"})
//            event.color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
//            events.append(event)
//
//            let nextOffset = Int(arc4random_uniform(250) + 40)
//            date = date.add(TimeChunk(seconds: 0,
//                                      minutes: nextOffset,
//                                      hours: 0,
//                                      days: 0,
//                                      weeks: 0,
//                                      months: 0,
//                                      years: 0))
//            event.userInfo = String(i)
//        }
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return [] }

        guard let calendar = self.schulcloudCalendar else { return [] }

        let startDate = Date(year: date.year, month: date.month, day: date.day)
        let oneDayLater = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1, weeks: 0, months: 0, years: 0)
        let endDate = startDate + oneDayLater
        let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
        return self.eventStore.events(matching: predicate).map { event in event.calendarEvent }
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
