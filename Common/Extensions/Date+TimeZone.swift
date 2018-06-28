//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

extension Date {

    func dateInCurrentTimeZone() -> Date {
        let utcOffset = TimeZone.autoupdatingCurrent.secondsFromGMT(for: self)
        var dateComponent = DateComponents()
        dateComponent.second = -utcOffset
        return Calendar.current.date(byAdding: dateComponent, to: self)!
    }

    func dateInUTCTimeZone() -> Date {
        let utcOffset = TimeZone.autoupdatingCurrent.secondsFromGMT(for: self)
        var dateComponent = DateComponents()
        dateComponent.second = utcOffset
        return Calendar.current.date(byAdding: dateComponent, to: self)!
    }
}
