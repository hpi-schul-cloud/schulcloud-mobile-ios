//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import DateToolsSwift
import Foundation

extension Date {

    func dateInCurrentTimeZone() -> Date {
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
