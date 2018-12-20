//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class DashboardCollectionViewControllerCell: UICollectionViewCell {
    func configure(for viewController: DynamicHeightViewController) {
        self.contentView.removeConstraints(self.contentView.constraints)
        self.contentView.subviews.first?.removeFromSuperview()

        self.contentView.addSubview(viewController.view)

        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            viewController.view.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            viewController.view.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
        ])
    }
}
