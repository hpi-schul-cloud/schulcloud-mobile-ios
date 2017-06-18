//
//  SplitViewController.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 18.06.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // https://stackoverflow.com/questions/26205838/adaptive-show-detail-segue-transformed-to-modal-instead-of-push-on-iphone-when-m
    override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        if (self.traitCollection.horizontalSizeClass == .compact) {
            if let tabBarController = self.viewControllers[0] as? UITabBarController {
                if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                    let unwrappedVc = (vc as? UINavigationController)?.viewControllers.first ?? vc
                    navigationController.show(unwrappedVc, sender: sender)
                    return
                }
            }
        }
        
        super.showDetailViewController(vc, sender: sender)
    }

}
