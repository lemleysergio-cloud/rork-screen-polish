//
//  BankrollBoardUITests.swift
//  BankrollBoardUITests
//
//  Created by Rork on September 15, 2026.
//

import XCTest

final class BankrollBoardUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testJourneyScrollsToFooterAndBack() throws {
        let app = XCUIApplication()
        app.launch()
        let scroll = app.scrollViews["journey.page"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        let picker = app.buttons["journey.statePicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertTrue(picker.isHittable, "State picker must be visible before scrolling.")
        let footer = app.buttons["Help resources"]
        for _ in 0..<24 {
            if footer.exists && footer.isHittable { break }
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.78))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.2)))
        }
        XCTAssertTrue(footer.isHittable, "The complete offer trail must remain scrollable to its footer.")

        for _ in 0..<24 {
            if picker.exists && picker.isHittable { break }
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.25))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.8)))
        }
        XCTAssertTrue(picker.isHittable, "Scrolling back must reach the header. Picker: \(picker.frame), scroll: \(scroll.frame). Visible text: \(app.staticTexts.allElementsBoundByIndex.filter { $0.isHittable }.map(\.label))")
        picker.tap()
        XCTAssertTrue(app.buttons["New Jersey"].waitForExistence(timeout: 5), "Controls must still respond after scrolling.")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
