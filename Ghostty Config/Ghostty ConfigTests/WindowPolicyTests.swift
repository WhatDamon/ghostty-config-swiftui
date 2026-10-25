import AppKit
import XCTest
@testable import Ghostty_Config

@MainActor
final class WindowPolicyTests: XCTestCase {
    func testAttachingWindowPolicyDisallowsTabsWithoutRemovingNativeToolbar() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        let toolbar = NSToolbar(identifier: "window-policy-test")
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.tabbingMode = .preferred

        window.contentView = AppWindowConfiguration.WindowPolicyView()

        XCTAssertEqual(window.tabbingMode, .disallowed)
        XCTAssertTrue(window.toolbar === toolbar)
        XCTAssertEqual(window.toolbarStyle, .unified)
        window.close()
    }

    func testPolicyAlsoAppliesWhenViewMovesToAnotherWindow() {
        let first = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: true)
        let second = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: true)
        first.isReleasedWhenClosed = false
        second.isReleasedWhenClosed = false
        let policyView = AppWindowConfiguration.WindowPolicyView()
        first.contentView = policyView
        XCTAssertEqual(first.tabbingMode, .disallowed)

        second.tabbingMode = .preferred
        second.contentView = policyView
        XCTAssertEqual(second.tabbingMode, .disallowed)
        first.close()
        second.close()
    }
}
