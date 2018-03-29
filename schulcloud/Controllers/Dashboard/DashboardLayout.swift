//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

protocol DashboardLayoutDataSource: class {
    func contentHeightForItem(at indexPath: IndexPath) -> CGFloat
}

final class DashboardLayout: UICollectionViewLayout {

    weak var dataSource: DashboardLayoutDataSource?

    var contentHeight: CGFloat = 0
    var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }

        var rect: CGRect
        if #available(iOS 11.0, *) {
            rect = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.safeAreaInsets)
        } else {
            rect = collectionView.bounds
        }
        return rect.width
    }

    var cache = [UICollectionViewLayoutAttributes]()

    override func prepare() {
        guard cache.isEmpty else { return }
        guard let collectionView = collectionView else { return }
        guard let dataSource = self.dataSource else { return }

        var localCache = [UICollectionViewLayoutAttributes]()

        let columnCount = collectionView.traitCollection.horizontalSizeClass == .regular ? 2 : 1
        let isSingleColumn = columnCount == 1

        let areaInset: UIEdgeInsets
        if #available(iOS 11.0, *) {
            areaInset = collectionView.safeAreaInsets
        } else {
            areaInset = UIEdgeInsets()
        }

        let readableFrame = collectionView.readableContentGuide.layoutFrame
        let xOffsetBase = isSingleColumn ? areaInset.left : readableFrame.origin.x
        let horizontalInset: CGFloat = isSingleColumn ? 0.0 : 8.0
        let yOffsetBase: CGFloat = 8.0
        let verticalInset: CGFloat = 8.0

        let layoutWidth = isSingleColumn ? contentWidth : readableFrame.width
        let columnWidth = layoutWidth / CGFloat(columnCount)
        let xOffsets = (0..<columnCount).map { i -> CGFloat in
            return (CGFloat(i) * columnWidth) + xOffsetBase
        }
        var yOffsets = [CGFloat](repeating: yOffsetBase, count: columnCount)

        for i in 0 ..< collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(row: i, section: 0)
            let itemHeight = dataSource.contentHeightForItem(at: indexPath)
            let (column, yOffset) = yOffsets.enumerated().min(by: { (i, j) -> Bool in
                return i.element < j.element
            })!
            let xOffset = xOffsets[column]
            let itemFrame = CGRect(x: xOffset, y: yOffset, width: columnWidth, height: itemHeight)
            yOffsets[column] = itemFrame.maxY
            contentHeight = max(contentHeight, itemFrame.maxY)

            let isFirstColumn = column == 0
            let isLastColumn = column == (columnCount - 1)
            let leftInset: CGFloat = isFirstColumn ? 0.0 : horizontalInset
            let rightInset: CGFloat  = isLastColumn ? 0.0 : horizontalInset
            let edgeInset = UIEdgeInsets(top: verticalInset, left: leftInset, bottom: verticalInset, right: rightInset)
            let finalFrame = UIEdgeInsetsInsetRect(itemFrame, edgeInset)

            let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            layoutAttributes.frame = finalFrame
            localCache.append(layoutAttributes)
        }
        contentHeight += yOffsetBase
        cache = localCache
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: collectionView!.bounds.width, height: contentHeight)
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
