//
//  NSAttributedString+HTML.swift
//  schulcloud
//
//  Created by Carl Gödecken on 29.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    
    internal convenience init?(html: String) {
        let modifiedFont = Constants.textStyleHtml + html    // TODO: fix bold and italic not working with custom font
        guard let data = modifiedFont.data(using: String.Encoding.utf16, allowLossyConversion: false) else {
            return nil
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
        ]
        guard let attributedString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }
        
        self.init(attributedString: attributedString)
    }
    
    var trailingNewlineChopped: NSAttributedString {
        if self.string.hasSuffix("\n") {
            return self.attributedSubstring(from: NSMakeRange(0, length - 1))
        } else {
            return self
        }
    }
}
