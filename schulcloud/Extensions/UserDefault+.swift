//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

extension UserDefaults {
    static var shared: UserDefaults? {
        return UserDefaults(suiteName: "group.org.schulcloud")
    }
}
