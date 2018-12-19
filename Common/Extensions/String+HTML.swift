//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import HTMLStyler

fileprivate let parser: Parser = {
    var parser = Parser()
    parser.styleCollection = DefaultStyleCollection(tintColor: Brand.default.colors.primary)
    return parser
}()

// MARK: HTML convenience
extension String {
    var standardStyledHtml: String {
        return parser.string(for: self)
    }

    public var convertedHTML: NSAttributedString? {
        return parser.attributedString(for: self)
    }
}
