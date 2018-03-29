//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

protocol ViewControllerHeightDataSource: class {
    var height: CGFloat { get }
}

typealias DynamicHeightViewController = UIViewController & ViewControllerHeightDataSource

extension User {
    var canDisplayNotification: Bool {
        return  self.permissions.contains(.notificationView)
    }
}

final class DashboardViewController: UICollectionViewController {

    enum Design {
        case reduced
        case extended
    }

    @IBOutlet private var notificationBarItem: UIBarButtonItem!

    lazy var noPermissionViewController: DashboardNoPermissionViewController = self.buildFromStoryboard(withIdentifier: "NoPermissionViewController")

    lazy var calendarOverview: CalendarOverviewViewController = self.buildFromStoryboard(withIdentifier: "CalendarOverview")
    lazy var homeworkOverview: HomeworkOverviewViewController = self.buildFromStoryboard(withIdentifier: "HomeworkOverview")
    lazy var notificationOverview = self.buildNotificationOverviewFromStroyboard()
    lazy var newsOverview  = self.buildNewsOverviewFromStoryboard()

    var viewControllers: [DynamicHeightViewController] = []

    var currentDesign: Design {
        return collectionView?.traitCollection.horizontalSizeClass == .regular ? .extended : .reduced
    }

    func addViewControllers() {
        guard let currentUser = Globals.currentUser else { return }

        func makeNoPermissionController(missingPermission: UserPermissions) -> DashboardNoPermissionViewController {
            let vc: DashboardNoPermissionViewController = self.buildFromStoryboard(withIdentifier: "NoPermissionViewController")
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChildViewController(vc)
            vc.missingPermission = missingPermission
            return vc
        }

        if !currentUser.permissions.contains(.dashboardView) {
            let missingVc = makeNoPermissionController(missingPermission: .dashboardView)
            viewControllers.append(missingVc)
            return
        }

        if currentUser.permissions.contains(.calendarView) {
            viewControllers.append(calendarOverview)
            calendarOverview.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChildViewController(calendarOverview)
        } else {
            let missingVc = makeNoPermissionController(missingPermission: .calendarView)
            viewControllers.append(missingVc)
        }

        if currentUser.permissions.contains(.homeworkView) {
            viewControllers.append(homeworkOverview)
            homeworkOverview.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChildViewController(homeworkOverview)
        } else {
            let missingVc = makeNoPermissionController(missingPermission: .homeworkView)
            viewControllers.append( missingVc)
        }

        if currentUser.permissions.contains(.newsView) {
            viewControllers.append(newsOverview)
            newsOverview.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChildViewController(newsOverview)
        } else {
            let missingVc = makeNoPermissionController(missingPermission: .newsView)
            viewControllers.append( missingVc)
        }

        if currentUser.canDisplayNotification {
            viewControllers.append(notificationOverview)
            notificationOverview.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChildViewController(notificationOverview)
        } else {
            let missingVc = makeNoPermissionController(missingPermission: .notificationView)
            viewControllers.append(missingVc)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let layout = collectionView?.collectionViewLayout as? DashboardLayout else { return }
        self.addViewControllers()
        layout.dataSource = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let itemIsVisible = self.currentDesign == .reduced && Globals.currentUser!.canDisplayNotification
        self.navigationItem.rightBarButtonItem = itemIsVisible ? self.notificationBarItem : nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

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

    private func buildNewsOverviewFromStoryboard() -> NewsOverviewViewController {
        let vc: NewsOverviewViewController = self.buildFromStoryboard(withIdentifier: "NewsOverview")
        vc.delegate = self
        return vc
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailNews" {
            guard let detailNewsVC = segue.destination as? NewsDetailViewController,
                  let newsArticle = sender as? NewsArticle else { return }
            detailNewsVC.newsArticle = newsArticle
        }
    }
}

extension DashboardViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.currentDesign == .extended ? viewControllers.count : viewControllers.filter({ viewController -> Bool in
            guard let viewController = viewController as? DashboardNoPermissionViewController else { return true }
            return viewController.missingPermission != .notificationView
        }).count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let vc = viewControllers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DashboardCollectionCell", for: indexPath) as! DashboardCollectionViewControllerCell
        cell.configure(for: vc)
        vc.didMove(toParentViewController: self)
        if cell.bounds.width < collectionView.bounds.width {
            cell.contentView.layer.cornerRadius = 5.0
            cell.contentView.layer.masksToBounds = true
        } else {
            cell.contentView.layer.cornerRadius = 0.0
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = viewControllers[indexPath.row]
        if vc == calendarOverview {
            self.performSegue(withIdentifier: "showCalendar", sender: nil)
        } else if vc == homeworkOverview {
            self.performSegue(withIdentifier: "showHomework", sender: nil)
        } else if vc == notificationOverview {
            self.performSegue(withIdentifier: "showNotifications", sender: nil)
        }
    }
}

extension DashboardViewController: ShortNotificationViewControllerDelegate {
    func viewHeightDidChange(to newHeight: CGFloat) {
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    func didPressViewMoreButton() {
        self.performSegue(withIdentifier: "showNotifications", sender: self)
    }
}

extension DashboardViewController: DashboardLayoutDataSource {
    func contentHeightForItem(at indexPath: IndexPath) -> CGFloat {
        return viewControllers[indexPath.row].height
    }
}

extension DashboardViewController: NewsOverviewViewControllerDelegate {

    func heightDidChange(_ height: CGFloat) {
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    func didSelect(news: NewsArticle) {
        self.performSegue(withIdentifier: "showDetailNews", sender: news)
    }

    func showMorePressed() {
        self.performSegue(withIdentifier: "showNewsList", sender: self)
    }
}
