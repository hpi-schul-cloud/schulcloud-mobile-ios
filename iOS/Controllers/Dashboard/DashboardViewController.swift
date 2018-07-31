//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

protocol ViewHeightDataSource: class {
    var height: CGFloat { get }
}

typealias DynamicHeightViewController = UIViewController & ViewHeightDataSource

extension User {
    var canDisplayNotification: Bool {
        return  self.permissions.contains(.notificationView)
    }
}

public final class DashboardViewController: UICollectionViewController {

    enum Design {
        case reduced
        case extended
    }

    @IBOutlet private var notificationBarItem: UIBarButtonItem!

    lazy var calendarOverview: CalendarOverviewViewController = self.initialViewControllerOfStoryboard(named: "CalendarOverview")
    lazy var homeworkOverview: HomeworkOverviewViewController = self.initialViewControllerOfStoryboard(named: "HomeworkOverview")
    lazy var notificationOverview = self.buildNotificationOverviewFromStroyboard()
    lazy var newsOverview = self.buildNewsOverviewFromStoryboard()

    var viewControllers: [DynamicHeightViewController] = []

    var currentDesign: Design {
        return collectionView?.traitCollection.horizontalSizeClass == .regular ? .extended : .reduced
    }

    func addViewControllers() {
        guard let currentUser = Globals.currentUser else { return }

        func makeNoPermissionController(missingPermission: UserPermissions) -> DashboardNoPermissionViewController {
            let viewController: DashboardNoPermissionViewController = self.initialViewControllerOfStoryboard(named: "MissingPermission")
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChildViewController(viewController)
            viewController.missingPermission = missingPermission
            return viewController
        }

        func makePermissionController<T: PermissionAbleViewController>(for wrappedViewController: T) -> PermissionManagmentViewController<T> {
            let viewController = PermissionManagmentViewController<T>()
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            viewController.configure(for: wrappedViewController)
            return viewController
        }

        if !currentUser.permissions.contains(.dashboardView) {
            let missingViewController = makeNoPermissionController(missingPermission: .dashboardView)
            self.viewControllers.append(missingViewController)
            return
        }

        self.viewControllers.append(makePermissionController(for: self.calendarOverview))
        let homeworkWrappedViewController = makePermissionController(for: self.homeworkOverview)
        homeworkWrappedViewController.containedViewController?.delegate = self
        self.viewControllers.append(homeworkWrappedViewController)
        let newsWrappedViewController = makePermissionController(for: self.newsOverview)
        newsWrappedViewController.containedViewController?.delegate = self
        self.viewControllers.append(newsWrappedViewController)
        let notificationWrappedViewController = makePermissionController(for: notificationOverview)
        notificationWrappedViewController.containedViewController?.delegate = self
        self.viewControllers.append(notificationWrappedViewController)

    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let layout = collectionView?.collectionViewLayout as? DashboardLayout else { return }
        self.addViewControllers()
        layout.dataSource = self
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let itemIsVisible = self.currentDesign == .reduced && Globals.currentUser!.canDisplayNotification
        self.navigationItem.rightBarButtonItem = itemIsVisible ? self.notificationBarItem : nil
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    private func initialViewControllerOfStoryboard<T>(named storyboardName: String) -> T {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)

        guard let viewController = storyboard.instantiateInitialViewController() as? T else {
            fatalError("Initial view controller of storyboard '\(storyboardName)' is not of type '\(T.self)'")
        }

        return viewController
    }

    private func buildNotificationOverviewFromStroyboard() -> NotificationOverviewViewController {
        let notificationOverview: NotificationOverviewViewController = self.initialViewControllerOfStoryboard(named: "NotificationOverview")
        notificationOverview.delegate = self
        return notificationOverview
    }

    private func buildNewsOverviewFromStoryboard() -> NewsOverviewViewController {
        let viewController: NewsOverviewViewController = self.initialViewControllerOfStoryboard(named: "NewsOverview")
        viewController.delegate = self
        return viewController
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNewsDetail" {
            guard let detailNewsViewController = segue.destination as? NewsDetailViewController,
                  let newsArticle = sender as? NewsArticle else { return }
            detailNewsViewController.newsArticle = newsArticle
        }
    }

    @IBAction func tappedOnNotificationButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showNotifications", sender: self)
    }

}

extension DashboardViewController {
    public override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.currentDesign == .extended ? viewControllers.count : viewControllers.filter { viewController -> Bool in
            guard let viewController = viewController as? PermissionManagmentViewController<NotificationOverviewViewController> else { return true }
            return viewController.hasPermission
        }.count
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let viewController = self.viewControllers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DashboardCollectionCell", for: indexPath) as! DashboardCollectionViewControllerCell
        cell.configure(for: viewController)
        viewController.didMove(toParentViewController: self)

        if cell.bounds.width < collectionView.bounds.width {
            cell.contentView.layer.cornerRadius = 5.0
            cell.contentView.layer.masksToBounds = true
        } else {
            cell.contentView.layer.cornerRadius = 0.0
        }

        cell.layoutSubviews()
        return cell
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let viewController = (viewControllers[indexPath.row])
        if let viewController = viewController as? PermissionManagmentViewController<CalendarOverviewViewController>,
               viewController.hasPermission {
            self.performSegue(withIdentifier: "showCalendar", sender: nil)
        } else if let viewController = viewController as? PermissionManagmentViewController<NotificationOverviewViewController>,
                      viewController.hasPermission {
            self.performSegue(withIdentifier: "showNotifications", sender: nil)
        } else if let viewController = viewController as? PermissionManagmentViewController<HomeworkOverviewViewController>,
                      viewController.hasPermission {
            self.performSegue(withIdentifier: "showHomework", sender: nil)
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
        return self.viewControllers[indexPath.row].height
    }
}

extension DashboardViewController: NewsOverviewViewControllerDelegate {
    func heightDidChange(_ height: CGFloat) {
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    func didSelect(news: NewsArticle) {
        self.performSegue(withIdentifier: "showNewsDetail", sender: news)
    }

    func showMorePressed() {
        self.performSegue(withIdentifier: "showNewsList", sender: self)
    }
}

extension DashboardViewController: HomeworkOverviewDelegate {
    func heightDidChange(height: CGFloat) {
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }
}
