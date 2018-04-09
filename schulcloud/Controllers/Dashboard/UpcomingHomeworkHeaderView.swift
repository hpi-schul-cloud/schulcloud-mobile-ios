//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class UpcomingHomeworkHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var label: UILabel!

    func configure(title: String, backgroundColor: UIColor) {
        if self.backgroundView == nil {
            self.backgroundView = UIView()
        }

        self.backgroundView?.backgroundColor = backgroundColor
        label.text = title
    }
}
