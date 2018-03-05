//
//  SchulcloudTabBarController.swift
//  schulcloud
//
//  Created by Florian Morel on 02.03.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

final class SchulcloudTabBarController : UITabBarController {


    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        self.delegate = AppDelegate.instance
    }
}
