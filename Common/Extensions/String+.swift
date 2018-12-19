//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

// MARK: Localization convenience
extension String {
    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}


extension String {
    public func removeCharacters(set: CharacterSet) -> String {
        let result = self.unicodeScalars.filter { !set.contains($0) }
        return String(result)
    }
}
