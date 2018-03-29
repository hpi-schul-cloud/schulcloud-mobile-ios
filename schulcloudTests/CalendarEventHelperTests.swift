//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

@testable import schulcloud
import XCTest

extension CalendarEvent {
    init(start: Date, end: Date, rule: RecurrenceRule?) {
        self.init(id: "ID",
                  title: "TITLE",
                  description: "DESC",
                  location: "LOCATION",
                  startDate: start,
                  endDate: end,
                  rule: rule,
                  coreDataID: nil,
                  ekEventID: nil)
    }
}

class CalendarEventHelperTests: XCTestCase {

    var formatter: DateFormatter!

    override func setUp() {
        super.setUp()

        self.formatter = DateFormatter()
        self.formatter.dateFormat = "dd.MM.yyyy HH:mm"
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: convenience
    func makeDatePair(_ startStr: String, _ endStr: String) -> (Date, Date) {
        return ( self.formatter.date(from: startStr)!, self.formatter.date(from: endStr)! )
    }

    // MARK: Calendar Event initialisation tests

    func testThatInitializingCalendarEventDoesNotModifyStartAndEndDate() {
        let (start, end) = makeDatePair("28.08.2017 15:00", "28.08.2017 16:00")

        let event = CalendarEvent(start: start, end: end, rule: nil)

        XCTAssertEqual(start, event.start)
        XCTAssertEqual(end, event.end)
    }

    // MARK: Recurrence rule tests
    func testThatItGetOnlyOneDatePairWhenNoRecurrenceRule() {
        let (start, end) = makeDatePair("02.10.2017 15:00", "02.10.2017 16:00")

        let event = CalendarEvent(start: start, end: end, rule: nil)

        var dateCount = 0
        for calendarEvent in event.dates {
            XCTAssertEqual(start, calendarEvent.start)
            XCTAssertEqual(end, calendarEvent.end)
            dateCount += 1
        }

        XCTAssertEqual(dateCount, 1)
    }

    func testThatItGeneratesDateUntilEndRecurringRule() {

        let (start, end) = makeDatePair("02.10.2017 15:00", "02.10.2017 16:00")
        let rule = CalendarEvent.RecurrenceRule(frequency: .daily, dayOfTheWeek: .monday, endDate: nil, interval: 1)

        let event = CalendarEvent(start: start, end: end, rule: rule)

        var dateIterator = event.dates.makeIterator()
        for _ in 0..<10 {
            XCTAssertNotNil(dateIterator.next())
        }

        dateIterator = event.dates.makeIterator()
        for _ in 0..<100 {
            XCTAssertNotNil(dateIterator.next())
        }
    }

    func testThatItGeneratesForTheGiventInterval() {
        let (start, end) = makeDatePair("02.10.2017 15:00","02.10.2017 16:00")
        let interval = 4

        let rule = CalendarEvent.RecurrenceRule(frequency: .daily, dayOfTheWeek: .monday, endDate: nil, interval: interval)
        let event = CalendarEvent(start: start, end: end, rule: rule)

        let sequence = event.dates
        var iterator = sequence.makeIterator()

        guard let firstEvent = iterator.next(),
              let secondEvent = iterator.next() else {
            XCTFail()
            return;
        }

        let component = Calendar.current.dateComponents([.day], from: firstEvent.start, to: secondEvent.start)

        XCTAssertEqual(interval, component.day)
    }

    func testThatDatesHaveCorrectFrequenciesForDailyEvent() {
        let (start, end) = makeDatePair("02.10.2017 15:00", "02.10.2017 16:00")

        let dailyRule = CalendarEvent.RecurrenceRule(frequency: .daily, dayOfTheWeek: .monday, endDate: nil, interval: 1)
        let dailyEvent = CalendarEvent(start: start, end: end, rule: dailyRule)

        var dailyEventIterator = dailyEvent.dates.makeIterator()
        let firstDate = dailyEventIterator.next()!.start
        let secondDate = dailyEventIterator.next()!.start

        let component = Calendar.current.dateComponents([.day], from: firstDate, to: secondDate)
        XCTAssertEqual(1, component.day)
    }

    func testThatDatesHaveCorrectFrequenciesForWeeklyEvent() {
        let (start, end) = makeDatePair("02.10.2017 15:00","02.10.2017 16:00")

        let weeklyRule = CalendarEvent.RecurrenceRule(frequency: .weekly, dayOfTheWeek: .monday, endDate: nil, interval: 1)
        let weeklyEvent = CalendarEvent(start: start, end: end, rule: weeklyRule)

        var weeklyEventIterator = weeklyEvent.dates.makeIterator()
        let firstDate = weeklyEventIterator.next()!.start
        let secondDate = weeklyEventIterator.next()!.start

        let component = Calendar.current.dateComponents([.weekOfYear], from: firstDate, to: secondDate)
        XCTAssertEqual(1, component.weekOfYear)
    }

    func testThatDatesHaveCorrectFrequenciesForMonthlyEvent() {
        let (start, end) = makeDatePair("02.10.2017 15:00","02.10.2017 16:00")

        let monthlyRule = CalendarEvent.RecurrenceRule(frequency: .monthly, dayOfTheWeek: .monday, endDate: nil, interval: 1)
        let monthlyEvent = CalendarEvent(start: start, end: end, rule: monthlyRule)

        var monthlyEventIterator = monthlyEvent.dates.makeIterator()
        let firstDate = monthlyEventIterator.next()!.start
        let secondDate = monthlyEventIterator.next()!.start

        let component = Calendar.current.dateComponents([.month], from: firstDate, to: secondDate)
        XCTAssertEqual(1, component.month)
    }

    func testThatDatesHaveCorrectFrequenciesForYearlyEvent() {
        let (start, end) = makeDatePair("02.10.2017 15:00","02.10.2017 16:00")

        let yearlyRule = CalendarEvent.RecurrenceRule(frequency: .yearly, dayOfTheWeek: .monday, endDate: nil, interval: 1)
        let yearlyEvent = CalendarEvent(start: start, end: end, rule: yearlyRule)

        var yearlyEventIterator = yearlyEvent.dates.makeIterator()
        let firstDate = yearlyEventIterator.next()!.start
        let secondDate = yearlyEventIterator.next()!.start

        let component = Calendar.current.dateComponents([.year], from: firstDate, to: secondDate)
        XCTAssertEqual(1, component.year)
    }

}
