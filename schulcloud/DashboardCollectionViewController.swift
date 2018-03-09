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

extension CalendarOverviewViewController : ViewControllerHeightDataSource {
    var height: CGFloat { return 200 }
}

extension HomeworkOverviewViewController : ViewControllerHeightDataSource {
    var height: CGFloat { return 200 }
}

extension ShortNotificationViewController : ViewControllerHeightDataSource {
    var height: CGFloat { return 400 }
}

final class DashboardCollectionViewControllerCell: UICollectionViewCell {


    func configure(for viewController: HeightViewController) {
        contentView.removeConstraints(contentView.constraints)
        contentView.subviews.first?.removeFromSuperview()

        contentView.addSubview(viewController.view)

        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=0)-[vc]-(>=0)-|",
                                                                 options: .alignAllCenterX,
                                                                 metrics: nil,
                                                                 views: ["vc" : viewController.view])
        contentView.addConstraints(verticalConstraints)

        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=0)-[vc]-(>=0)-|",
                                                        options: .alignAllCenterY,
                                                        metrics: nil,
                                                        views: ["vc" : viewController.view])
        contentView.addConstraints(horizontalConstraints)
    }
}

final class DashboardCollectionViewController : UICollectionViewController {

    lazy var calendarOverview : CalendarOverviewViewController = self.buildFromStoryboard(withIdentifier: "CalendarOverview")
    lazy var homeworkOverview : HomeworkOverviewViewController = self.buildFromStoryboard(withIdentifier: "HomeworkOverview")
    lazy var notificationOverview = self.buildNotificationOverviewFromStroyboard()

    lazy var viewControllers : [HeightViewController] = {
        return [calendarOverview, homeworkOverview, notificationOverview]
    }()

    lazy var heights : [CGFloat] = {
        var result = [CGFloat](repeating:0, count: viewControllers.count)
        for i in 0..<result.count {
            result[i] = viewControllers[i].height
        }
        return result
    }()

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
        return UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let vc = viewControllers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DashboardCollectionCell", for: indexPath) as! DashboardCollectionViewControllerCell
        cell.configure(for: vc)
        vc.didMove(toParentViewController: self)
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
        heights[2] = height
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    func didPressViewMoreButton() {
        self.performSegue(withIdentifier: "showNotifications", sender: self)
    }
}

extension DashboardCollectionViewController : DashboardLayoutDataSource {
    func contentHeightForItem(at indexPath: IndexPath) -> CGFloat {
        return heights[indexPath.row]
    }
}

protocol DashboardLayoutDataSource: class {
    func contentHeightForItem(at indexPath: IndexPath) -> CGFloat
}

final class DashboardLayout : UICollectionViewLayout {

    weak var dataSource : DashboardLayoutDataSource?

    let topInset : CGFloat = 5.0

    var contentHeight : CGFloat = 0
    var contentWidth : CGFloat {
        guard let collectionView = collectionView else { return 0 }

        let collectionViewInset : UIEdgeInsets
        if #available(iOS 11.0, *) {
            collectionViewInset = collectionView.adjustedContentInset
        } else {
            collectionViewInset = collectionView.contentInset
        }
        return collectionView.bounds.size.width - (collectionViewInset.left + collectionViewInset.right)
    }

    var cache = [UICollectionViewLayoutAttributes]()

    override func prepare() {
        guard let collectionView = collectionView else { return }
        guard let dataSource = self.dataSource else { return }

        let columnCount : Int
        if collectionView.traitCollection.horizontalSizeClass == .regular {
            columnCount = collectionView.bounds.width > 960 ? 3 : 2
        } else {
            columnCount = 1
        }

        let columnWidth = contentWidth / CGFloat(columnCount)
        var xOffsets = [CGFloat](repeating: 0.0, count: columnCount)
        for i in 0..<columnCount {
            xOffsets[i] = CGFloat(i) * columnWidth
        }
        var yOffsets = [CGFloat](repeating: 0.0, count: columnCount)

        for i in 0 ..< collectionView.numberOfItems(inSection: 0) {

            let indexPath = IndexPath(row: i, section: 0)
            let itemHeight = dataSource.contentHeightForItem(at: indexPath)

            let (column, yOffset) = yOffsets.enumerated().min(by: { (i, j) -> Bool in
                return i.element < j.element
            })!
            let xOffset = xOffsets[column]

            let itemFrame = CGRect(x: xOffset, y: yOffset, width: columnWidth, height: itemHeight)
            let finalFrame = itemFrame.insetBy(dx: 5, dy: topInset)

            let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            layoutAttributes.frame = finalFrame

            yOffsets[column] += itemHeight
            cache.append(layoutAttributes)

            contentHeight = max(contentHeight, itemFrame.maxY)
        }
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard !cache.isEmpty else { return nil }
        var result = [UICollectionViewLayoutAttributes]()

        for layout in cache {
            if rect.intersects(layout.frame) { result.append(layout) }
        }

        return result
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.row]
    }

    override func invalidateLayout() {
        contentHeight = 0
        cache.removeAll()

        super.invalidateLayout()
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let shouldInvalidate = super.shouldInvalidateLayout(forBoundsChange: newBounds)
        let invalidationContext = self.invalidationContext(forBoundsChange: newBounds)
        self.invalidateLayout(with: invalidationContext)
        return shouldInvalidate || collectionView?.bounds.width != newBounds.width
    }
}
