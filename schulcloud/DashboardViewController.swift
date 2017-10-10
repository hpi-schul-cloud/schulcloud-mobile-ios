//
//  DashboardViewController.swift
//  schulcloud
//
//  Created by jan on 22/05/2017.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//


import UIKit

import Alamofire
import BrightFutures
import Marshal

class DashboardViewController: UIViewController {
    @IBOutlet var notificationBarButton: UIBarButtonItem!
    @IBOutlet var dashboardCells: [UIView]!

    @IBOutlet weak var notificationContainerHeight: NSLayoutConstraint!

    var notifications: [SCNotification] = []
    var notificationViewController: ShortNotificationViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateNotificationBarButton()
        self.fetchNotifications()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            self.updateUIAfterTraitCollectionChange()
        }
    }

    private func updateUIAfterTraitCollectionChange() {
        // update notification button in navigation bar
        if self.traitCollection.horizontalSizeClass == .regular {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.navigationItem.rightBarButtonItem = self.notificationBarButton
        }

        // update corner radius of dashboard cells
        let cornerRadius: CGFloat = self.traitCollection.horizontalSizeClass == .regular ? 4.0 : 0.0
        for cell in dashboardCells {
            cell.layer.cornerRadius = cornerRadius
            cell.layer.masksToBounds = true
        }
    }

    @IBAction func tappedCalendarCell(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "showCalendar", sender: sender)
    }

    @IBAction func tappedTasksCell(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "showTasks", sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showNotifications"?:
            guard let navigationViewController = segue.destination as? UINavigationController else { return }
            guard let notificationViewController = navigationViewController.topViewController as? NotificationViewController else { return }
            notificationViewController.notifications = self.notifications
        case "showNotificationsEmbedded"?:
            guard let shortNotificationViewController = segue.destination as? ShortNotificationViewController else { return }
            self.notificationViewController = shortNotificationViewController
            shortNotificationViewController.delegate = self
        case "showCalendarOverviewEmbedded"?:
            segue.destination.view.translatesAutoresizingMaskIntoConstraints = false
        default:
            super.prepare(for: segue, sender: sender)
        }
    }

    private func updateNotificationView() {
        self.notificationViewController?.notifications = self.notifications
    }

    private func updateNotificationBarButton() {
        let title = self.notifications.isEmpty ? nil : String(self.notifications.count)
        let imageName = self.notifications.isEmpty ? "bell" : "bell-filled"
        let image = UIImage(named: imageName)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.setTitle(title, for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(DashboardViewController.showNotifications), for: .touchUpInside)
        self.notificationBarButton.customView = button
    }

    func fetchNotifications() {
        let request: Future<[SCNotification], SCError> = ApiHelper.request("notification?$limit=50").deserialize(keyPath: "data")
        request.onSuccess { notifications in
            self.notifications = notifications
            self.updateNotificationView()
            self.updateNotificationBarButton()
        }
    }

    func showNotifications() {
        self.performSegue(withIdentifier: "showNotifications", sender: self)
    }

}

extension DashboardViewController: ShortNotificationViewControllerDelegate {

    func viewHeightDidChange(to height: CGFloat) {
        self.notificationContainerHeight.constant = height
    }

    func didPressViewMoreButton() {
        self.performSegue(withIdentifier: "showNotifications", sender: self)
    }

}

struct SCNotification: Unmarshaling {
    let body: String
    let title: String?
    let action: URL?

    init(object: MarshaledObject) throws {
        let message = try object.value(for: "message") as JSONObject
        body = try message.value(for: "body")
        title = try? message.value(for: "title")
        action = try? message.value(for: "action")
    }
}
