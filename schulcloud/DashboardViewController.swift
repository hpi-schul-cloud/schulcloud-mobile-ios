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

    enum Design {
        case reduced
        case everything
    }

    var displayedDesign: Design?

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var reducedStackView: UIStackView!
    @IBOutlet weak var everythingStackView: UIStackView!
    @IBOutlet var notificationBarButton: UIBarButtonItem!

    var notifications: [SCNotification] = []
    var notificationContainerHeight: NSLayoutConstraint?

    lazy var calendarOverview: CalendarOverviewViewController = self.buildFromStoryboard(withIdentifier: "CalendarOverview")
    lazy var homeworkOverview: HomeworkOverviewViewController = self.buildFromStoryboard(withIdentifier: "HomeworkOverview")
    lazy var notificationOverview: ShortNotificationViewController = self.buildNotificationOverviewFromStroyboard()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.addContentViewController(self.calendarOverview, to: self.reducedStackView)
        self.addContentViewController(self.homeworkOverview, to: self.reducedStackView)
        self.addContentViewController(self.notificationOverview, to: self.everythingStackView)

        let heightConstraint = NSLayoutConstraint(item: self.notificationOverview.view,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: 0)
        self.notificationOverview.view.addConstraint(heightConstraint)
        self.notificationContainerHeight = heightConstraint

        self.calendarOverview.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showCalendar)))
        self.homeworkOverview.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showTasks)))

        self.updateNotificationBarButton()
        self.fetchNotifications()
    }

    override func viewWillLayoutSubviews() {
        let size = self.view.bounds.size
        let newDesign = self.decideDesign(basedOn: size)

        if self.displayedDesign != newDesign {
            self.applyDesign(newDesign)
            self.displayedDesign = newDesign
        }

    }

    // MARK: segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showNotifications"?:
            guard let navigationViewController = segue.destination as? UINavigationController else { return }
            guard let notificationViewController = navigationViewController.topViewController as? NotificationViewController else { return }
            notificationViewController.notifications = self.notifications
        default:
            super.prepare(for: segue, sender: sender)
        }
    }

    @objc func showNotifications() {
        self.performSegue(withIdentifier: "showNotifications", sender: self)
    }

    @objc private func showCalendar() {
        self.performSegue(withIdentifier: "showCalendar", sender: self)
    }

    @objc private func showTasks() {
        self.performSegue(withIdentifier: "showTasks", sender: self)
    }

    // MARK: view setup

    private func buildFromStoryboard<T>(withIdentifier identifier: String) -> T {
        let storyboard = UIStoryboard(name: "TabDashboard", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
            fatalError("Missing \(identifier) in Storyboard")
        }
        return viewController
    }

    private func buildNotificationOverviewFromStroyboard() -> ShortNotificationViewController {
        let notificationOverview: ShortNotificationViewController = self.buildFromStoryboard(withIdentifier: "NotificationOverview")
        notificationOverview.delegate = self
        return notificationOverview
    }

    private func addContentViewController(_ viewController: UIViewController, to stackView: UIStackView) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(viewController)
        stackView.addArrangedSubview(viewController.view)
        viewController.didMove(toParentViewController: self)
    }

    // MARK: design

    private func decideDesign(basedOn size: CGSize) -> Design {
        return UIDevice.current.userInterfaceIdiom == .pad ? .everything : .reduced
    }

    private func applyDesign(_ newDesign: Design) {
        // set notification button in navigation item
        self.navigationItem.rightBarButtonItem = newDesign == .reduced ? self.notificationBarButton : nil

        // hide right colum
        self.everythingStackView.isHidden = newDesign == .reduced

        // set corner radius
        let contentViews = [self.calendarOverview.view, self.homeworkOverview.view, self.notificationOverview.view]
        let cornerRadius: CGFloat = newDesign == .reduced ? 0.0 : 4.0
        for contentView in contentViews {
            contentView?.layer.cornerRadius = cornerRadius
            contentView?.layer.masksToBounds = true
        }
    }

    // MARK: notifications

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
//        let request: Future<[SCNotification], SCError> = ApiHelper.request("notification?$limit=50").deserialize(keyPath: "data")
//        request.onSuccess { notifications in
//            self.notifications = notifications
//            self.notificationOverview.notifications = self.notifications
//            self.updateNotificationBarButton()
//        }
    }

}

extension DashboardViewController: ShortNotificationViewControllerDelegate {

    func viewHeightDidChange(to height: CGFloat) {
        self.notificationContainerHeight?.constant = height
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
