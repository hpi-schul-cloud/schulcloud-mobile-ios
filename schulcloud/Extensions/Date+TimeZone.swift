//
//  Date+TimeZone.swift
//  schulcloud
//
//  Created by Max Bothe on 08.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import DateToolsSwift

extension Date {

    func dateInCurrentTimeZone() -> Date  {
        return self.subtract(self.utcOffset())
    }

    func dateInUTCTimeZone() -> Date {
        return self.add(self.utcOffset())
    }

    private func utcOffset() -> TimeChunk {
        let utcOffset = TimeZone.autoupdatingCurrent.secondsFromGMT(for: self)
        return TimeChunk(seconds: utcOffset, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, years: 0)
    }

}
