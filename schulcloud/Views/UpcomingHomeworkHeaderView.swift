//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class UpcomingHomeworkHeaderView: UITableViewHeaderFooterView {

    @IBOutlet private weak var dotView: UIView!
    @IBOutlet private weak var label: UILabel!

    func configure(title: String, withColor color: UIColor? = nil) {
        if let dotColor = color {
            self.dotView.backgroundColor = dotColor
            self.dotView.layer.cornerRadius = dotView.width / 2.0
            self.dotView.isHidden = false
        } else {
            self.dotView.isHidden = true
        }

        self.label.text = title
    }
}
