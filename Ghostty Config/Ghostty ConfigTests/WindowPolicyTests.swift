import AppKit
import XCTest
@testable import Ghostty_Config

@MainActor
final class WindowPolicyTests: XCTestCase {
    func testFullScreenCommandIsHiddenWithoutHidingZoomOrOtherCommands() {
        let menu = NSMenu()
        let viewItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        viewItem.submenu = submenu
        menu.addItem(viewItem)
        let fullScreen = NSMenuItem(title: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        let zoom = NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        submenu.addItem(fullScreen)
        submenu.addItem(zoom)

        AppWindowConfiguration.hideFullScreenCommands(in: menu)
        AppWindowConfiguration.hideFullScreenCommands(in: menu)

        XCTAssertTrue(fullScreen.isHidden)
        XCTAssertFalse(viewItem.isHidden)
        XCTAssertFalse(zoom.isHidden)
    }

    func testAttachingWindowPolicyDisallowsTabsWithoutRemovingNativeToolbar() throws {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        let toolbar = NSToolbar(identifier: "window-policy-test")
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.tabbingMode = .preferred
        window.collectionBehavior = [.managed, .fullScreenPrimary, .fullScreenAllowsTiling]

        window.contentView = AppWindowConfiguration.WindowPolicyView()

        XCTAssertEqual(window.tabbingMode, .disallowed)
        XCTAssertTrue(window.toolbar === toolbar)
        XCTAssertEqual(window.toolbarStyle, .unified)
        XCTAssertTrue(window.collectionBehavior.contains(.managed))
        XCTAssertTrue(window.collectionBehavior.contains(.fullScreenNone))
        XCTAssertTrue(window.collectionBehavior.contains(.fullScreenDisallowsTiling))
        XCTAssertTrue(window.collectionBehavior.isDisjoint(with: [.fullScreenPrimary, .fullScreenAuxiliary, .fullScreenAllowsTiling]))
        XCTAssertTrue(window.styleMask.contains(.resizable))
        XCTAssertTrue(try XCTUnwrap(window.standardWindowButton(.zoomButton)).isEnabled)
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
        second.collectionBehavior = [.fullScreenAuxiliary]
        second.contentView = policyView
        XCTAssertEqual(second.tabbingMode, .disallowed)
        XCTAssertTrue(second.collectionBehavior.contains(.fullScreenNone))
        XCTAssertFalse(second.collectionBehavior.contains(.fullScreenAuxiliary))
        first.close()
        second.close()
    }
}
