//
//  DashboardViewControllerCell.swift
//  schulcloud
//
//  Created by Florian Morel on 13.03.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

final class DashboardCollectionViewControllerCell: UICollectionViewCell {
    func configure(for viewController: DynamicHeightViewController) {
        contentView.removeConstraints(contentView.constraints)
        contentView.subviews.first?.removeFromSuperview()

        contentView.addSubview(viewController.view)

        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[vc]|",
                                                                 options: .alignAllCenterY,
                                                                 metrics: nil,
                                                                 views: ["vc" : viewController.view])
        contentView.addConstraints(verticalConstraints)

        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[vc]|",
                                                                   options: .alignAllCenterX,
                                                                   metrics: nil,
                                                                   views: ["vc" : viewController.view])
        contentView.addConstraints(horizontalConstraints)
    }
}
