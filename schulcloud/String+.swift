//
//  String+.swift
//  schulcloud
//
//  Created by Florian Morel on 09.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

// MARK: Localization convenience
extension String {
    var localized : String {
        return NSLocalizedString(self, comment: "")
    }
}

// MARK: HTML convenience
extension String {
    func htmlWrapped(style: String?) -> String {
        let text = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return "<html><head>\(style ?? "")</head><body>\(text)</body></html>"
    }
    
    var standardStyledHtml : String {
        return self.htmlWrapped(style: Constants.textStyleHtml)
    }

    var convertedHTML: NSAttributedString? {
        guard let data = self.standardStyledHtml.data(using: .utf8) else {
            return nil
        }

        let options: [String: Any] = [
            NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue),
        ]
        let attributedString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil)
        return attributedString?.trimmedAttributedString(set: .whitespacesAndNewlines)
    }
}
