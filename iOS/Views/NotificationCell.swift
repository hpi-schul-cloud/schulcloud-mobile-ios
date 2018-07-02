//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!

    var notification: SCNotification? {
        didSet {
            self.titleLabel.text = self.notification?.title
            self.detailLabel.text = self.notification?.body
        }
    }

}
