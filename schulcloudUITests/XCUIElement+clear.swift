//
//  XCUIElement+clear.swift
//  schulcloudUITests
//
//  Created by Max Bothe on 27.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import XCTest

extension XCUIElement {
    /**
     Removes any current text in the field
     */
    func clear() {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count) // stringValue.map { _ in "\u{8}" }.joined(separator: "")
        self.typeText(deleteString)
    }

    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func clearAndEnter(text: String) {
        self.clear()
        self.tap()
        self.typeText(text)
    }

}
