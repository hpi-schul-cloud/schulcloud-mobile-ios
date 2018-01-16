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
    init(start: Date, end: Date, rule: RecurenceRule?) {
        self.id = "ID"
        self.title = "TITLE"
        self.description = "DESC"
        self.location = "LOCATION"
        self.start = start
        self.end = end
        self.recurenceRule = rule
    }
}

class CalendarEventHelperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatItGetOnlyOneDatePairWhenNoRecurrenceRule() {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        let start = formatter.date(from: "01.10.2017 15:00")!
        let end = formatter.date(from: "01.10.2017 16:00")!

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
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        let start = formatter.date(from: "01.10.2017 15:00")!
        let end = formatter.date(from: "01.10.2017 16:00")!
        
        let rule = CalendarEvent.RecurenceRule(frequency: .daily, dayOfTheWeek: .monday, endDate: nil, interval: Int.max)
        
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
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        let start = formatter.date(from: "01.10.2017 15:00")!
        let end = formatter.date(from: "01.10.2017 16:00")!
        
        let interval = 5
        
        let rule = CalendarEvent.RecurenceRule(frequency: .daily, dayOfTheWeek: .monday, endDate: nil, interval: interval)
        
        let event = CalendarEvent(start: start, end: end, rule: rule)
        
        
        var dateCount = 0
        for (_, _) in event.dates {
            dateCount += 1
        }
        
        XCTAssertEqual(dateCount, interval)
    }

}
