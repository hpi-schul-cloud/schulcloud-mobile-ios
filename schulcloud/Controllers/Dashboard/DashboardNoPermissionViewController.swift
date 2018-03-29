//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class DashboardNoPermissionViewController: UIViewController, ViewControllerHeightDataSource {

    @IBOutlet var label: UILabel!

    var missingPermission: UserPermissions = UserPermissions.none {
        didSet {
            self.label?.text?.append("\n(\(missingPermission.description))")
        }
    }

    var height: CGFloat {
        return 200.0
    }

}
