//
//  NSMutableAttributedString+trim.swift
//  schulcloud
//
//  Created by Max Bothe on 12.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//
//  Credit goes to https://stackoverflow.com/a/41300031/7414898
//

import Foundation

extension NSMutableAttributedString {

    func trimmedAttributedString(set: CharacterSet) -> NSMutableAttributedString {

        let invertedSet = set.inverted

        var range = (string as NSString).rangeOfCharacter(from: invertedSet)
        let loc = range.length > 0 ? range.location : 0

        range = (string as NSString).rangeOfCharacter(from: invertedSet, options: .backwards)
        let len = (range.length > 0 ? NSMaxRange(range) : string.count) - loc

        let r = self.attributedSubstring(from: NSMakeRange(loc, len))
        return NSMutableAttributedString(attributedString: r)
    }

}
