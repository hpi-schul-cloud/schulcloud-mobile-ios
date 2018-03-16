//
//  UIAlertController+Permission.swift
//  schulcloud
//
//  Created by Florian Morel on 16.03.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

extension UIAlertController {
    convenience init(forMissingPermission missingPermission: UserPermissions) {
        self.init(title: "Missing Permission", message: "You do not have the permission required: \(missingPermission.description)", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        self.addAction(dismissAction)
    }
}
