//
//  MissingPermissionView.swift
//  schulcloud
//
//  Created by Florian Morel on 28.03.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

final class MissingPermissionView : UIView {
    @IBOutlet var label : UILabel!
    var missingPermission : UserPermissions = UserPermissions.none {
        didSet {
            if label != nil {
                label.text = "Fehlende Berechtigung \(missingPermission.description)"
                self.layoutSubviews()
            }
        }
    }
}

extension MissingPermissionView : ViewHeightDataSource {
    var height : CGFloat {
        return 100.0
    }
}
