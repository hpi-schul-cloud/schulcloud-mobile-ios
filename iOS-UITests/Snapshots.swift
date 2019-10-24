//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import XCTest

class Snapshots: XCTestCase {

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        XCUIDevice.shared.orientation = UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait
    }

    func testLaunch() {
        let app = XCUIApplication()
        let emailAdresseOderNutzernameTextField = app.textFields["Email-Adresse oder Nutzername"]
        emailAdresseOderNutzernameTextField.clear()

        app.otherElements.containing(.image, identifier: "logo-text").element.tap()

        snapshot("0Launch")
    }

    func testSnapshots() {
        let alertDismissals: [String: String] = [
            // english
            "“HPI Schul-Cloud” Would Like to Access Your Calendar": "OK",
            "“HPI Schul-Cloud” Would Like to Send You Notifications": "Don’t Allow",

            // german
            "“HPI Schul-Cloud” möchte auf deinen Kalendar zugreifen": "OK",
            "Ein lokaler HPI Schul-Cloud Kalendar existiert bereits.": "Verwerfen",
        ]

        for (labelText, buttonTitle) in alertDismissals {
            addUIInterruptionMonitor(withDescription: description) { alert -> Bool in
                if alert.label == labelText {
                    alert.buttons[buttonTitle].tap()
                    return true
                }

                return false
            }
        }

        let app = XCUIApplication()

        let anmeldenButton = app.buttons["Als Schüler einloggen"]
        anmeldenButton.tap()

        let foundText = app.staticTexts["offene Aufgaben"].waitForExistence(timeout: 120)
        XCTAssertTrue(foundText, "Unable to find text 'offenen Aufgaben'")

        while app.alerts.count > 0 { // swiftlint:disable:this empty_count
            app.navigationBars.firstMatch.tap()
        }

        snapshot("1Dashboard")

        app.tabBars.buttons["Einstellungen"].tap()
        app.tables.staticTexts["Ausloggen"].tap()

        let foundLoginBotton = app.buttons["Anmelden"].waitForExistence(timeout: 120)
        XCTAssertTrue(foundLoginBotton, "Unable to find login button")
    }

}
