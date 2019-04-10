//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public extension Optional {
    func require(hint msg: String) -> Wrapped {
        guard let result = self else {
            fatalError(msg)
        }

        return result
    }
}
