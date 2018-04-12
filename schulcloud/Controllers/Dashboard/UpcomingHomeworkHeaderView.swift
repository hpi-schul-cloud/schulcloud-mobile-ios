//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class UpcomingHomeworkHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var dotView: UIView!
    @IBOutlet private weak var label: UILabel!

    func configure(title: String, backgroundColor: UIColor) {

        if backgroundView == nil {
            backgroundView = UIView()
            backgroundView!.backgroundColor = UIColor.white
        }
        dotView.backgroundColor = backgroundColor
        dotView.layer.cornerRadius = dotView.width / 2.0
        label.text = title
    }
}
