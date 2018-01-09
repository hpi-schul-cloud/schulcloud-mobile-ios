//
//  TimeHelper.swift
//  schulcloud
//
//  Created by Florian Morel on 09.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation

struct TimeHelper {
    
    static func timeSince(_ date: Date) -> String {
        
        func localizedTime(_ localized_format: String, value: Int) -> String {
            let result_format = String.localizedStringWithFormat(localized_format, value)
            return String(format: "time.past".localized, result_format)
        }
        
        let component = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date, to: Date())
        if let year = component.year,
            year > 0 {
            
            return localizedTime("number_of_year".localized, value: year)
        } else if let month = component.month,
            month > 0 {
            
            return localizedTime("number_of_month".localized, value: month)
        } else if let day = component.day,
            day > 0 {
            
            return localizedTime("number_of_day".localized, value: day)
        } else if let hour = component.hour,
            hour > 0 {
            
            return localizedTime("number_of_hour".localized, value: hour)
        } else if let minute = component.minute,
            minute > 0 {
            
            return localizedTime("number_of_minute".localized, value: minute)
        } else if let second = component.second,
            second > 0 {
            
            return localizedTime("number_of_second".localized, value: second)
        }
        
        return ""
    }
}
