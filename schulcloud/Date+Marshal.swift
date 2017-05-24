//
//  Date+Marshal.swift
//  schulcloud
//
//  Created by Carl Gödecken on 24.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Marshal

extension NSDate : ValueType {
    public static func value(from object: Any) throws -> NSDate {
        guard let dateString = object as? String else {
            throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
        }
        // assuming you have a Date.fromISO8601String implemented...
        guard let date = NSDate.fromISO8601String(dateString) else {
            throw MarshalError.typeMismatch(expected: "ISO8601 date string", actual: dateString)
        }
        return date
    }
}

extension NSDate {
    static func fromISO8601String(_ dateString:String) -> NSDate? {
        return NSDate.iso8601Formatter.date(from: dateString) as NSDate?
    }
    
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate,
                                   .withTime,
                                   .withDashSeparatorInDate,
                                   .withColonSeparatorInTime]
        return formatter
    }()
}
