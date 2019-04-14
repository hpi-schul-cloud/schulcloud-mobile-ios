//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class MissingPermissionView: UIView {

    @IBOutlet private var label: UILabel!

    var missingPermission = UserPermissions.none {
        didSet {
            if label != nil {
                label.text = "Fehlende Berechtigung \(missingPermission)"
                self.layoutSubviews()
            }
        }
    }
}

extension MissingPermissionView: ViewHeightDataSource {
    var height: CGFloat {
        return 100.0
    }
}
