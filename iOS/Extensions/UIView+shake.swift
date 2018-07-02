//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

extension UIView {

    func shake() {
        let deltaX = 5.0 as CGFloat
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: center.x - deltaX, y: center.y)
        animation.toValue = CGPoint(x: center.x + deltaX, y: center.y)
        self.layer.add(animation, forKey: "position")
    }

}
