//
//  UIView+shake.swift
//  schulcloud
//
//  Created by Max Bothe on 30.08.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

extension UIView {

    func shake() {
        let deltaX = 5.0 as CGFloat
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - deltaX, y: center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + deltaX, y: center.y))
        layer.add(animation, forKey: "position")
    }

}
