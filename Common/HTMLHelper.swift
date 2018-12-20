//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import HTMLStyler

public struct HTMLHelper {
    public static let `default` = HTMLHelper()

    private var parser = Parser()
    init(style: StyleCollection = DefaultStyleCollection(tintColor: Brand.default.colors.primary)) {
        parser.styleCollection = style
    }

    /**
     * This func removes the HTML markups from the string, keeping only the content.
     */
    public func stringContent(of html: String) -> String {
        return parser.string(for: html)
    }

    /**
     * This func renders the HTML as a NSAttributedString
     */
    public func attributedString(for html: String) -> NSAttributedString {
        return parser.attributedString(for:html)
    }
}
