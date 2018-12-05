//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

extension UIAlertController {

    convenience init(forMissingPermission missingPermission: UserPermissions) {
        self.init(title: "Fehlende Berechtigung",
                  message: "Folgende Berechtigung ist erforderlich: \(missingPermission)",
                  preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        self.addAction(dismissAction)
    }

}
