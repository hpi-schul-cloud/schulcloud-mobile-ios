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
typealias HeightViewController = UIViewController & ViewControllerHeightDataSource

final class DashboardCollectionViewControllerCell: UICollectionViewCell {

    func configure(for viewController: HeightViewController) {
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

final class DashboardCollectionViewController : UICollectionViewController {

    enum Design {
        case reduced
        case extended
    }

    @IBOutlet var notificationBarItem : UIBarButtonItem!

    lazy var calendarOverview : CalendarOverviewViewController = self.buildFromStoryboard(withIdentifier: "CalendarOverview")
    lazy var homeworkOverview : HomeworkOverviewViewController = self.buildFromStoryboard(withIdentifier: "HomeworkOverview")
    lazy var notificationOverview = self.buildNotificationOverviewFromStroyboard()

    lazy var viewControllers : [HeightViewController] = {
        return [calendarOverview, homeworkOverview, notificationOverview]
    }()


    var currentDesign : Design {
        return collectionView?.traitCollection.horizontalSizeClass == .regular ? .extended : .reduced
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let layout = collectionView?.collectionViewLayout as? DashboardLayout else { return }
        layout.dataSource = self

        calendarOverview.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(calendarOverview)
        homeworkOverview.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(homeworkOverview)
        notificationOverview.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(notificationOverview)

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.navigationItem.rightBarButtonItem = self.currentDesign == .extended ? nil : self.notificationBarItem
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        collectionView?.collectionViewLayout.invalidateLayout()
        collectionView?.reloadData()
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
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.currentDesign == .extended ? 3 : 2
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let vc = viewControllers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DashboardCollectionCell", for: indexPath) as! DashboardCollectionViewControllerCell
        cell.configure(for: vc)
        vc.didMove(toParentViewController: self)
        if self.currentDesign == .extended {
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

extension DashboardCollectionViewController: ShortNotificationViewControllerDelegate {
    func viewHeightDidChange(to height: CGFloat) {
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    func didPressViewMoreButton() {
        self.performSegue(withIdentifier: "showNotifications", sender: self)
    }
}

extension DashboardCollectionViewController : DashboardLayoutDataSource {
    func contentHeightForItem(at indexPath: IndexPath) -> CGFloat {
        return viewControllers[indexPath.row].height
    }
}

