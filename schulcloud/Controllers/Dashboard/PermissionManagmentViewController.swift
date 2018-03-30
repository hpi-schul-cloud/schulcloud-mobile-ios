//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

protocol PermissionInfoDataSource {

    static var requiredPermission: UserPermissions { get }
    static var missingPermissionView: UIView & ViewHeightDataSource { get }

}

extension PermissionInfoDataSource where Self: UIViewController {

    static var requiredPermission: UserPermissions {
        return UserPermissions.none // if no permissiong required, show all the time
    }

    static var missingPermissionView: UIView & ViewHeightDataSource {
        return UINib(nibName: "MissingPermissionView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! MissingPermissionView
    }

}

typealias PermissionAbleViewController = UIViewController & ViewHeightDataSource & PermissionInfoDataSource

final class PermissionManagmentViewController<T: PermissionAbleViewController>: UIViewController, ViewHeightDataSource {
    var height: CGFloat {
        return viewHeightDataSource?.height ?? 0.0
    }

    var containedViewController: T?
    weak var viewHeightDataSource: ViewHeightDataSource?

    var hasPermission: Bool {
        return Globals.currentUser!.permissions.contains(T.requiredPermission)
    }

    func configure(for wrappedVC: T) {
        let view: UIView
        if hasPermission {
            if containedViewController == nil {
                containedViewController = wrappedVC
            }

            view = wrappedVC.view
            viewHeightDataSource = wrappedVC
        } else {
            let missingPermissionView = T.missingPermissionView as! MissingPermissionView
            missingPermissionView.missingPermission = T.requiredPermission
            viewHeightDataSource = missingPermissionView
            view = missingPermissionView
        }

        self.view.removeConstraints(self.view.constraints)
        self.view.subviews.forEach { $0.removeFromSuperview() }

        self.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[view]-(0)-|", options: [], metrics: nil, views: ["view": view])
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[view]-(0)-|", options: [], metrics: nil, views: ["view": view])
        self.view.addConstraints(hConstraints + vConstraints)

        if let containedViewController = containedViewController {
            containedViewController.didMove(toParentViewController: self)
        }
    }
}
