//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class DashboardNoPermissionViewController: UIViewController, ViewHeightDataSource {

    @IBOutlet private var label: UILabel!

    var missingPermission = UserPermissions.none {
        didSet {
            self.label?.text?.append("\n(\(missingPermission))")
        }
    }

    var height: CGFloat {
        return self.label.yMax
    }
}
