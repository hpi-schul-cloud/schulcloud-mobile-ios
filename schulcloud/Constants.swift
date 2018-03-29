//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

class Constants {
    enum Servers: String {
        case staging = "https://schul.tech:3030/"
        case production = "https://schul-cloud.org:8080/"
        case web = "https://schul-cloud.org/"

        var url: URL {
            return URL(string: self.rawValue)!
        }
    }

    static let backend = Servers.production

    static var textStyleHtml: String {
        var style: String = "<style>"
        style += "body { font: -apple-system-body; }"
        style += "h1 { font: -apple-system-title1; }"
        style += "a {color: #b10438; text-decoration: none}"
        style += "img {display: block; max-width: 100%; width: auto !important; height: auto !important;}"
        style += ".not-supported {border: 1px solid #aaa; background-color: #ddd; border-radius: 2px; padding: 8px 4px; display: block; max-width: 100%; width: auto !important; text-align: center}"
        style += "</style>"
        return style
    }

}
