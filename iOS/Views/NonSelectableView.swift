//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

class NonSelectableView: UIView {
	override var backgroundColor: UIColor? {
		didSet {
			if backgroundColor != nil && backgroundColor!.cgColor.alpha == 0 {
				backgroundColor = oldValue
			}
		}
	}
}
