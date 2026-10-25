import XCTest

@MainActor
final class Ghostty_ConfigUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testSearchNavigatesToSpecificSetting() {
        let app = XCUIApplication()
        app.launch()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.click()
        search.typeText("option alt\n")
        XCTAssertTrue(app.popUpButtons["macos-option-as-alt"].waitForExistence(timeout: 5))
        XCTAssertEqual(search.value as? String, "")
        // The original system suggestions crashed when the result list changed.
        search.click()
        search.typeText("font size")
        search.typeText(XCUIKeyboardKey.escape.rawValue)
        XCTAssertTrue(app.popUpButtons["macos-option-as-alt"].exists)
    }

    func testImportReportsInvalidLinesAndExportsTypedValues() {
        let app = XCUIApplication()
        app.launch()
        app.outlines.staticTexts["Import & Export"].firstMatch.click()
        app.buttons["Paste Text or Link…"].click()
        let editor = app.textViews["Configuration to import"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.click()
        editor.typeText("mouse-hide-while-typing = true\nwindow-padding-x = 4\npalette = 1=#123456\nfont-size = 14.5\ninvalid line")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "4 valid entries", "4 valid entries")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts["import-diagnostics"].waitForExistence(timeout: 3))
        app.buttons["Import Config"].click()
        let output = app.staticTexts["config-preview"]
        XCTAssertTrue(output.waitForExistence(timeout: 5))
        let exported = (output.value as? String) ?? output.label
        XCTAssertTrue(exported.contains("font-size = 14.5"))
        XCTAssertTrue(exported.contains("mouse-hide-while-typing = true"))
        XCTAssertTrue(exported.contains("palette = 1=#123456"))
        XCTAssertTrue(app.buttons["Save File…"].isEnabled)
    }
}
