//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public class Constants {
    public static var textStyleHtml: String {
        var style: String = "<style>"
        style += "body { font: -apple-system-body; }"
        style += "h1 { font: -apple-system-title1; }"
        style += "a {color: #b10438; text-decoration: none}"
        style += "img {display: block; max-width: 100%; width: auto !important; height: auto !important;}"
        style += """
        .not-supported {border: 1px solid #aaa;
            background-color: #ddd;
            border-radius: 2px;
            padding: 8px 4px;
            display: block;
            max-width: 100%;
            width: auto !important;
            text-align: center}
        """
        style += "</style>"
        return style
    }

}
