//
//  schulcloudUITests.swift
//  schulcloudUITests
//
//  Created by Carl Gödecken on 05.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import XCTest

class schulcloudUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLaunch() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        snapshot("0Launch")
    }

    func testSnapshots() {
        guard let filePath = Bundle(for: type(of: self)).path(forResource: "Secrets", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: filePath),
            let username = plist["UI_TEST_USERNAME"] as? String,
            let password = plist["UI_TEST_PASSWORD"] as? String else {
            XCTFail("No username and password provided!")
            return
        }

        let alertDismissals: [String: String] = [
            // english
            "“Schul-Cloud” Would Like to Access Your Calendar": "OK",
            "“Schul-Cloud” Would Like to Send You Notifications": "Don’t Allow",

            // german
            "“Schul-Cloud” möchte auf deinen Kalendar zugreifen": "OK",
            "Ein lokaler Schul-Cloud Kalendar existiert bereits.": "Verwerfen",
        ]
        for (labelText, buttonTitle) in alertDismissals {
            addUIInterruptionMonitor(withDescription: description) { (alert) -> Bool in
                if alert.label == labelText {
                    alert.buttons[buttonTitle].tap()
                    return true
                }
                return false
            }
        }

        let app = XCUIApplication()
        let emailAdresseOderNutzernameTextField = app.textFields["Email-Adresse oder Nutzername"]
        emailAdresseOderNutzernameTextField.tap()
        let deleteText = (emailAdresseOderNutzernameTextField.value as? String ?? "").characters.map { _ in XCUIKeyboardKeyDelete }.joined(separator: "")
        emailAdresseOderNutzernameTextField.typeText(deleteText)
        emailAdresseOderNutzernameTextField.typeText(username)

        let passwortSecureTextField = app.secureTextFields["Passwort"]
        passwortSecureTextField.tap()
        passwortSecureTextField.typeText(password)

        let anmeldenButton = app.buttons["Anmelden"]
        anmeldenButton.tap()

        let foundText = app.staticTexts["offene Aufgaben"].waitForExistence(timeout:10)
        XCTAssertTrue(foundText)

        while app.alerts.count > 0 {
            app.navigationBars.firstMatch.tap()
        }

        snapshot("1Dashboard")

        app.tabBars.buttons["Einstellungen"].tap()
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Ausloggen"]/*[[".cells.staticTexts[\"Ausloggen\"]",".staticTexts[\"Ausloggen\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let foundLoginBotton = app.buttons["Anmelden"].waitForExistence(timeout:10)
        XCTAssertTrue(foundLoginBotton)
    }
    
}
