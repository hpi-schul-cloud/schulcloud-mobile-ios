//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
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

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
        ]
        let attributedString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil)
        return attributedString?.trimmedAttributedString(set: .whitespacesAndNewlines)
    }
}
