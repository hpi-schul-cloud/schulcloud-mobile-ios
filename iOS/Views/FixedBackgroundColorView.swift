//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

class FixedBackgroundColorView: UIView {
    override var backgroundColor: UIColor? {
        didSet {
            if self.backgroundColor?.cgColor.alpha == 0 {
                self.backgroundColor = oldValue
            }
        }
    }
}
