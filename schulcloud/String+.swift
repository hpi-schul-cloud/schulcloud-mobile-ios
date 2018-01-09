//
//  String+.swift
//  schulcloud
//
//  Created by Florian Morel on 09.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation

// MARK: Localization convenience
extension String {
    var localized : String {
        return NSLocalizedString(self, comment: "")
    }
}

// MARK: HTML convenience
extension String {
    func htmlWrapped(style: String?) -> String {
        return "<html><head>\(style ?? "")</head><body>\(self)</body></html>"
    }
    
    var standardStyledHtml : String {
        return htmlWrapped(style: Constants.textStyleHtml)
    }
}
