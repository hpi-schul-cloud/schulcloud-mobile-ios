//
//  CalendarEventHelperTests.swift
//  schulcloudTests
//
//  Created by Florian Morel on 15.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

@testable import Schul_Cloud
import XCTest


extension CalendarEvent {
    init(start: Date, end: Date, rule: RecurrenceRule?) {
        self.init(id: "ID",
                  title: "TITLE",
                  description: "DESC",
                  location: "LOCATION",
                  startDate: start,
                  endDate: end,
                  rule: rule)
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
    
    func testThatInitializingCalendarEventAdaptDateBaseOnDayOfWeek() {
        let (start, end) = makeDatePair("28.08.2017 15:00", "28.08.2017 16:00") //these dates are aligned on monday, like the backend would send
        
        var rule = CalendarEvent.RecurrenceRule(frequency: .monthly, dayOfTheWeek: .tuesday, endDate: nil, interval: 10)
        var event = CalendarEvent(start: start, end: end, rule: rule)

        var startCompo = Calendar.current.dateComponents([.day], from: start, to: event.start)
        var endCompo = Calendar.current.dateComponents([.day], from: end, to: event.end)
        
        XCTAssertEqual(startCompo.day, 1)
        XCTAssertEqual(endCompo.day, 1)
        
        rule = CalendarEvent.RecurrenceRule(frequency: .monthly, dayOfTheWeek: .thursday, endDate: nil, interval: 10)
        event = CalendarEvent(start: start, end: end, rule: rule)
        
        startCompo = Calendar.current.dateComponents([.day], from: start, to: event.start)
        endCompo = Calendar.current.dateComponents([.day], from: end, to: event.end)
        
        XCTAssertEqual(startCompo.day, 3)
        XCTAssertEqual(endCompo.day, 3)
    }
    
    // MARK: Recurrence rule tests
    func testThatItGetOnlyOneDatePairWhenNoRecurrenceRule() {
        let (start, end) = makeDatePair("01.10.2017 15:00", "01.10.2017 16:00")

        let event = CalendarEvent(start: start, end: end, rule: nil)
        
        var dateCount = 0
        for (calculatedStart, calculatedEnd) in event.dates {
            XCTAssertEqual(start, calculatedStart)
            XCTAssertEqual(end, calculatedEnd)
            dateCount += 1
        }
        
        XCTAssertEqual(dateCount, 1)
    }
    
    func testThatItGeneratesDateUntilEndRecurringRule() {

        let (start, end) = makeDatePair("01.10.2017 15:00", "01.10.2017 16:00")
        let rule = CalendarEvent.RecurrenceRule(frequency: .daily, dayOfTheWeek: .monday, endDate: nil, interval: Int.max)
        
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
        let (start, end) = makeDatePair("01.10.2017 15:00","01.10.2017 16:00")
        let interval = 5
        
        let rule = CalendarEvent.RecurrenceRule(frequency: .daily, dayOfTheWeek: .monday, endDate: nil, interval: interval)
        
        let event = CalendarEvent(start: start, end: end, rule: rule)
        
        
        var dateCount = 0
        for (_, _) in event.dates {
            dateCount += 1
        }
        
        XCTAssertEqual(dateCount, interval)
    }
    
    func testThatDatesHaveCorrectFrequenciesForDailyEvent() {
        
        let (start, end) = makeDatePair("01.10.2017 15:00", "01.10.2017 16:00")

        let dailyRule = CalendarEvent.RecurrenceRule(frequency: .daily, dayOfTheWeek: .monday, endDate: nil, interval: Int.max)
        let dailyEvent = CalendarEvent(start: start, end: end, rule: dailyRule)
        
        var dailyEventIterator = dailyEvent.dates.makeIterator()
        let firstDate = dailyEventIterator.next()!.0
        let secondDate = dailyEventIterator.next()!.0
        
        let component = Calendar.current.dateComponents([.day], from: firstDate, to: secondDate)
        XCTAssertEqual(1, component.day)
    }
    func testThatDatesHaveCorrectFrequenciesForWeeklyEvent() {
        
        let (start, end) = makeDatePair("01.10.2017 15:00","01.10.2017 16:00")
        
        let weeklyRule = CalendarEvent.RecurrenceRule(frequency: .weekly, dayOfTheWeek: .monday, endDate: nil, interval: Int.max)
        let weeklyEvent = CalendarEvent(start: start, end: end, rule: weeklyRule)
        
        var weeklyEventIterator = weeklyEvent.dates.makeIterator()
        let firstDate = weeklyEventIterator.next()!.0
        let secondDate = weeklyEventIterator.next()!.0
        
        let component = Calendar.current.dateComponents([.weekOfYear], from: firstDate, to: secondDate)
        XCTAssertEqual(1, component.weekOfYear)

    }
    func testThatDatesHaveCorrectFrequenciesForMonthlyEvent() {
        
        let (start, end) = makeDatePair("01.10.2017 15:00","01.10.2017 16:00")
        
        let monthlyRule = CalendarEvent.RecurrenceRule(frequency: .monthly, dayOfTheWeek: .monday, endDate: nil, interval: Int.max)
        let monthlyEvent = CalendarEvent(start: start, end: end, rule: monthlyRule)
        
        var monthlyEventIterator = monthlyEvent.dates.makeIterator()
        let firstDate = monthlyEventIterator.next()!.0
        let secondDate = monthlyEventIterator.next()!.0
        
        let component = Calendar.current.dateComponents([.month], from: firstDate, to: secondDate)
        XCTAssertEqual(1, component.month)
    }
    
    func testThatDatesHaveCorrectFrequenciesForYearlyEvent() {

        let (start, end) = makeDatePair("01.10.2017 15:00","01.10.2017 16:00")
        
        let yearlyRule = CalendarEvent.RecurrenceRule(frequency: .yearly, dayOfTheWeek: .monday, endDate: nil, interval: Int.max)
        let yearlyEvent = CalendarEvent(start: start, end: end, rule: yearlyRule)
        
        var yearlyEventIterator = yearlyEvent.dates.makeIterator()
        let firstDate = yearlyEventIterator.next()!.0
        let secondDate = yearlyEventIterator.next()!.0
        
        let component = Calendar.current.dateComponents([.year], from: firstDate, to: secondDate)
        XCTAssertEqual(1, component.year)
    }
}
