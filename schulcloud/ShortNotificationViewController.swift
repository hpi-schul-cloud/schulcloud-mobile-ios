//
//  ShortNotificationViewController.swift
//  schulcloud
//
//  Created by Max Bothe on 28.08.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class ShortNotificationViewController: UITableViewController {

    static let numberOfShownCells = 3

    var delegate: ShortNotificationViewControllerDelegate?
    var notifications: [SCNotification] = [] {
        didSet {
            let moreCellsToShow = self.notifications.count > ShortNotificationViewController.numberOfShownCells
            self.tableView.tableFooterView?.isHidden = !moreCellsToShow
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView?.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.tableView.layoutIfNeeded()
        var viewHeight = self.tableView.contentSize.height
        if let footer = self.tableView.tableFooterView, footer.isHidden {
            let bottomPadding: CGFloat = 16.0
            viewHeight -= footer.frame.size.height - bottomPadding
        }
        self.delegate?.viewHeightDidChange(to: viewHeight)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.notifications.count == 0 {
            return 1
        }
        return min(self.notifications.count, ShortNotificationViewController.numberOfShownCells)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = self.notifications.count == 0 ? "emptyListCell" : "notificationCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        if let notificationCell = cell as? NotificationCell {
            notificationCell.notification = self.notifications[indexPath.row]
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    @IBAction func tappedViewMore() {
        self.delegate?.didPressViewMoreButton()
    }
}


protocol ShortNotificationViewControllerDelegate {

    func viewHeightDidChange(to: CGFloat)
    func didPressViewMoreButton()

}
