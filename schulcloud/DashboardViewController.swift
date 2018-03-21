//
//  DashboardCollectionViewController.swift
//  schulcloud
//
//  Created by Florian Morel on 06.03.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData

protocol ViewControllerHeightDataSource: class {
    var height : CGFloat { get }
}
typealias DynamicHeightViewController = UIViewController & ViewControllerHeightDataSource

extension User {
    var canDisplayNotification : Bool {
        return  self.permissions.contains(.notificationView)
    }
}

final class DashboardViewController : UICollectionViewController {

    enum Design {
        case reduced
        case extended
    }

    private enum Sections : Int {
        case dashboard = 0
        case newsList = 1
    }

    @IBOutlet var notificationBarItem : UIBarButtonItem!

    lazy var noPermissionViewController : DashboardNoPermissionViewController = self.buildFromStoryboard(withIdentifier: "NoPermissionViewController")

    lazy var calendarOverview : CalendarOverviewViewController = self.buildFromStoryboard(withIdentifier: "CalendarOverview")
    lazy var homeworkOverview : HomeworkOverviewViewController = self.buildFromStoryboard(withIdentifier: "HomeworkOverview")
    lazy var notificationOverview = self.buildNotificationOverviewFromStroyboard()

    var viewControllers : [DynamicHeightViewController] = []

    var newsArticleFetchedController : NSFetchedResultsController<NewsArticle> = {
        let fetchRequest : NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayAt", ascending: false)]

        let resultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataHelper.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return resultController
    }()

    var currentDesign : Design {
        return collectionView?.traitCollection.horizontalSizeClass == .regular ? .extended : .reduced
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        commonInit()
    }

    func commonInit() {
        guard let currentUser = Globals.currentUser else { return }

        func makeNoPermissionController(missingPermission: UserPermissions) -> DashboardNoPermissionViewController {
            let vc : DashboardNoPermissionViewController = self.buildFromStoryboard(withIdentifier: "NoPermissionViewController")
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

        if currentUser.canDisplayNotification {
            viewControllers.append(notificationOverview)
            notificationOverview.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChildViewController(notificationOverview)
        } else {
            let missingVc = makeNoPermissionController(missingPermission: .notificationView)
            viewControllers.append(missingVc)
        }
    }

    // Scroll to top when releading, so make sure things are layed out properly
    func reloadCollectionView() {
        self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: 0), at: UICollectionViewScrollPosition.top, animated: false);
        self.collectionView?.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let layout = collectionView?.collectionViewLayout as? DashboardLayout else { return }
        layout.dataSource = self
        try! newsArticleFetchedController.performFetch()
        NewsArticleHelper.syncNewsArticles()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let itemIsVisible = self.currentDesign == .reduced && Globals.currentUser!.canDisplayNotification
        self.navigationItem.rightBarButtonItem = itemIsVisible ? self.notificationBarItem : nil
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.reloadCollectionView()
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

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Globals.currentUser!.permissions.contains(.newsView) ? 2 : 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sectionType = Sections(rawValue: section) else { return 0 }

        switch sectionType {
        case .dashboard:
            return self.currentDesign == .extended ? viewControllers.count : viewControllers.filter({ (vc) -> Bool in
                guard let vc = vc as? DashboardNoPermissionViewController else { return true }
                return vc.missingPermission != .notificationView
            }).count
        case .newsList:
            return self.newsArticleFetchedController.fetchedObjects?.count ?? 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = Sections(rawValue: indexPath.section)!
        let cell : UICollectionViewCell

        switch sectionType {
        case .dashboard:
            let vc = viewControllers[indexPath.row]
            let dashboardCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DashboardCollectionCell", for: indexPath) as! DashboardCollectionViewControllerCell
            dashboardCell.configure(for: vc)
            vc.didMove(toParentViewController: self)
            cell = dashboardCell
        case .newsList:

            let newsArticle = self.newsArticleFetchedController.object(at: IndexPath(row: indexPath.row, section: 0))
            let newsCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DashboardNewsCell", for: indexPath) as! DashboardNewsCell
            newsCell.title.text = newsArticle.title
            newsCell.date.text = DashboardNewsCell.dateFormatter.string(from: newsArticle.displayAt)
            newsCell.content.attributedText = newsArticle.content.convertedHTML
            newsCell.content.isUserInteractionEnabled = false

            cell = newsCell
        }

        if cell.bounds.width < collectionView.bounds.width {
            cell.layer.cornerRadius = 5.0
            cell.layer.masksToBounds = true
        } else {
            cell.layer.cornerRadius = 0.0
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = Sections(rawValue: indexPath.section)!
        switch sectionType {
        case .dashboard:
            let vc = viewControllers[indexPath.row]
            if vc == calendarOverview {
                self.performSegue(withIdentifier: "showCalendar", sender: nil)
            } else if vc == homeworkOverview {
                self.performSegue(withIdentifier: "showHomework", sender: nil)
            } else if vc == notificationOverview {
                self.performSegue(withIdentifier: "showNotifications", sender: nil)
            }
        case .newsList:
            return
        }
    }
}

extension DashboardViewController : NSFetchedResultsControllerDelegate {
    private func controllerDidChangeContent(_ controller: NSFetchedResultsController<NewsArticle>) {
        self.reloadCollectionView()
    }
}

extension DashboardViewController: ShortNotificationViewControllerDelegate {
    func viewHeightDidChange(to height: CGFloat) {
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    func didPressViewMoreButton() {
        self.performSegue(withIdentifier: "showNotifications", sender: self)
    }
}

extension DashboardViewController : DashboardLayoutDataSource {
    func contentHeightForItem(at indexPath: IndexPath, boundingWidth: CGFloat) -> CGFloat {
        let sectionType = Sections(rawValue: indexPath.section)!
        switch sectionType {
        case .dashboard:
            return viewControllers[indexPath.row].height
        case .newsList:
            let newsArticle = self.newsArticleFetchedController.object(at: IndexPath(row:indexPath.row, section: 0))
            return DashboardNewsCell.height(for: newsArticle, boundingWidth: boundingWidth)
        }
    }
}
