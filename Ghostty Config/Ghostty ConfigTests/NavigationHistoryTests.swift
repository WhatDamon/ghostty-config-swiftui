import XCTest
@testable import Ghostty_Config

@MainActor
final class NavigationHistoryTests: XCTestCase {
    func testInitialLocationAndTraversalAtBothBoundaries() {
        var history = NavigationHistory()
        XCTAssertEqual(history.current, .home)
        XCTAssertFalse(history.canGoBack)
        XCTAssertFalse(history.canGoForward)
        history.goBack()
        history.goForward()
        XCTAssertEqual(history.entries, [.home])
        XCTAssertEqual(history.index, 0)
    }

    func testBackAndForwardTraverseWithoutAppendingVisits() {
        var history = NavigationHistory()
        let colors = NavigationDestination(panelID: "colors")
        let fonts = NavigationDestination(panelID: "fonts")
        history.visit(colors)
        history.visit(fonts)
        XCTAssertTrue(history.canGoBack)
        XCTAssertFalse(history.canGoForward)
        history.goBack()
        XCTAssertEqual(history.current, colors)
        XCTAssertTrue(history.canGoForward)
        history.goBack()
        history.goBack()
        XCTAssertEqual(history.current, .home)
        XCTAssertFalse(history.canGoBack)
        history.goForward()
        history.goForward()
        history.goForward()
        XCTAssertEqual(history.current, fonts)
        XCTAssertEqual(history.entries, [.home, colors, fonts])
        XCTAssertFalse(history.canGoForward)
    }

    func testNewVisitAfterBackReplacesForwardBranch() {
        var history = NavigationHistory()
        history.visit(NavigationDestination(panelID: "colors"))
        history.visit(NavigationDestination(panelID: "fonts"))
        history.goBack()
        let terminal = NavigationDestination(panelID: "terminal")
        history.visit(terminal)
        XCTAssertEqual(history.entries.map(\.panelID), ["home", "colors", "terminal"])
        XCTAssertEqual(history.current, terminal)
        XCTAssertFalse(history.canGoForward)
    }

    func testVisitingCurrentDestinationDoesNotDiscardForwardBranch() {
        var history = NavigationHistory()
        let colors = NavigationDestination(panelID: "colors")
        history.visit(colors)
        history.visit(NavigationDestination(panelID: "fonts"))
        history.goBack()
        history.visit(colors)
        XCTAssertEqual(history.entries.count, 3)
        XCTAssertEqual(history.current, colors)
        XCTAssertTrue(history.canGoForward)
    }

    func testSearchLocationsWithinOneCategoryAreDistinctAndRestorable() {
        var history = NavigationHistory()
        let family = NavigationDestination(panelID: "fonts", settingKey: .fontFamily)
        let metrics = NavigationDestination(panelID: "fonts", settingKey: .adjustCellWidth)
        history.visit(family)
        history.visit(metrics)
        history.goBack()
        XCTAssertEqual(history.current, family)
        history.goForward()
        XCTAssertEqual(history.current, metrics)
        history.visit(metrics)
        XCTAssertEqual(history.entries.count, 3)
    }

    func testShareDestinationParticipatesInHistory() {
        var history = NavigationHistory()
        let search = NavigationDestination(panelID: "macos", settingKey: .macosOptionAsAlt)
        history.visit(search)
        history.visit(NavigationDestination(panelID: "import-export"))
        history.goBack()
        XCTAssertEqual(history.current, search)
        history.goForward()
        XCTAssertEqual(history.current.panelID, "import-export")
    }

    func testEachWindowOwnsIndependentHistory() {
        var first = NavigationHistory()
        let second = NavigationHistory()
        first.visit(NavigationDestination(panelID: "colors"))
        XCTAssertEqual(second.current, .home)
        XCTAssertFalse(second.canGoBack)
    }
}
