//
//  NotificationCell.swift
//  schulcloud
//
//  Created by Max Bothe on 25.08.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

    var notification: SCNotification? {
        didSet {
            self.titleLabel.text = self.notification?.title
            self.detailLabel.text = self.notification?.body
        }
    }

}
