//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

protocol ViewHeightDataSource: AnyObject {
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

    lazy var calendarOverview = R.storyboard.calendarOverview.calendarOverview()!
    lazy var homeworkOverview = R.storyboard.homeworkOverview.homeworkOverview()!
    lazy var notificationOverview: NotificationOverviewViewController = {
        let notificationOverview: NotificationOverviewViewController = R.storyboard.notificationOverview.notificationOverview()!
        notificationOverview.delegate = self
        return notificationOverview
    }()

    lazy var newsOverview: NewsOverviewViewController = {
        let viewController: NewsOverviewViewController = R.storyboard.newsOverview.newsOverview()!
        viewController.delegate = self
        return viewController
    }()

    var viewControllers: [DynamicHeightViewController] = []

    var currentDesign: Design {
        return collectionView?.traitCollection.horizontalSizeClass == .regular ? .extended : .reduced
    }

    func addViewControllers() {
        guard let currentUser = Globals.currentUser else { return }

        func makeNoPermissionController(missingPermission: UserPermissions) -> DashboardNoPermissionViewController {
            let viewController = R.storyboard.missingPermission.noPermissionViewController()!
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChild(viewController)
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

    private var observer: NSObjectProtocol?

    override public func viewDidLoad() {
        super.viewDidLoad()
        guard let layout = collectionView?.collectionViewLayout as? DashboardLayout else { return }
        self.addViewControllers()
        layout.dataSource = self
        self.observer = NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [unowned self] _ in
            self.collectionViewLayout.invalidateLayout()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self.observer as Any)
        super.viewWillDisappear(animated)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let itemIsVisible = self.currentDesign == .reduced && Globals.currentUser!.canDisplayNotification
        self.navigationItem.rightBarButtonItem = itemIsVisible ? self.notificationBarItem : nil
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueInfo = R.segue.dashboardViewController.showNewsDetail(segue: segue) {
            segueInfo.destination.newsArticle = sender as? NewsArticle
        }
    }

    @IBAction private func tappedOnNotificationButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: R.segue.dashboardViewController.showNotifications, sender: self)
    }
}

extension DashboardViewController {
    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.currentDesign == .extended ? viewControllers.count : viewControllers.filter { viewController -> Bool in
            guard let viewController = viewController as? PermissionManagmentViewController<NotificationOverviewViewController> else { return true }
            return viewController.hasPermission
        }.count
    }

    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let viewController = self.viewControllers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.dashboardCollectionCell, for: indexPath)!
        cell.configure(for: viewController)
        viewController.didMove(toParent: self)

        if cell.bounds.width < collectionView.bounds.width {
            cell.contentView.layer.cornerRadius = 5.0
            cell.contentView.layer.masksToBounds = true
        } else {
            cell.contentView.layer.cornerRadius = 0.0
        }

        cell.layoutSubviews()
        return cell
    }

    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let viewController = (viewControllers[indexPath.row])
        if let viewController = viewController as? PermissionManagmentViewController<CalendarOverviewViewController>,
               viewController.hasPermission {
            self.performSegue(withIdentifier: R.segue.dashboardViewController.showCalendar, sender: nil)
        } else if let viewController = viewController as? PermissionManagmentViewController<NotificationOverviewViewController>,
                      viewController.hasPermission {
            self.performSegue(withIdentifier: R.segue.dashboardViewController.showNotifications, sender: nil)
        } else if let viewController = viewController as? PermissionManagmentViewController<HomeworkOverviewViewController>,
                      viewController.hasPermission {
            self.performSegue(withIdentifier: R.segue.dashboardViewController.showHomework, sender: nil)
        }
    }
}

extension DashboardViewController: ShortNotificationViewControllerDelegate {
    func viewHeightDidChange(to newHeight: CGFloat) {
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    func didPressViewMoreButton() {
        self.performSegue(withIdentifier: R.segue.dashboardViewController.showNotifications, sender: self)
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
        self.performSegue(withIdentifier: R.segue.dashboardViewController.showNewsDetail, sender: news)
    }

    func showMorePressed() {
        self.performSegue(withIdentifier: R.segue.dashboardViewController.showNewsList, sender: self)
    }
}

extension DashboardViewController: HomeworkOverviewDelegate {
    func heightDidChange(height: CGFloat) {
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }
}
