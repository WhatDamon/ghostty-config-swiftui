// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import AppKit
import SwiftUI

struct AppWindowInteractionPolicy: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            // Let SwiftUI configure its own window and menus consistently with
            // the AppKit fallback; otherwise it can re-enable full screen later.
            content.windowFullScreenBehavior(.disabled)
        } else {
            content
        }
    }
}

/// Keep a native resizable window and toolbar, with zoom instead of full screen
/// and no participation in tab groups.
struct AppWindowConfiguration: NSViewRepresentable {
    var localConfigService: LocalConfigService? = nil
    var hasUnsavedChanges = false
    static func hideFullScreenCommands(in menu: NSMenu) {
        for item in menu.items {
            if item.action == #selector(NSWindow.toggleFullScreen(_:)), !item.isHidden {
                item.isHidden = true
            }
            if let submenu = item.submenu { hideFullScreenCommands(in: submenu) }
        }
    }

    func makeNSView(context: Context) -> WindowPolicyView { WindowPolicyView() }

    static func dismantleNSView(_ nsView: WindowPolicyView, coordinator: ()) {
        nsView.removeClosePolicy()
    }

    func updateNSView(_ nsView: WindowPolicyView, context: Context) {
        nsView.localConfigService = localConfigService
        nsView.applyWindowPolicy()
        // SwiftUI installs its window delegate after the representable attaches.
        // Wrap that delegate only once the current update has completed.
        DispatchQueue.main.async { [weak nsView] in nsView?.applyWindowPolicy() }
    }

    final class WindowPolicyView: NSView {
        nonisolated deinit {}
        weak var localConfigService: LocalConfigService? {
            didSet { installClosePolicy() }
        }
        private var closePolicy: ClosePolicy?
        private var activationObserver: NSObjectProtocol?

        func removeClosePolicy() {
            if let activationObserver { NotificationCenter.default.removeObserver(activationObserver) }
            activationObserver = nil
            if let window, let closePolicy, window.delegate === closePolicy { window.delegate = closePolicy.original }
            closePolicy = nil
        }

        private func installClosePolicy() {
            guard let window, let localConfigService else { return }
            if closePolicy == nil { closePolicy = ClosePolicy() }
            guard let closePolicy else { return }
            closePolicy.localConfigService = localConfigService
            if window.delegate !== closePolicy {
                closePolicy.original = window.delegate
                window.delegate = closePolicy
            }
            window.isDocumentEdited = localConfigService.hasUnsavedChanges
        }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let activationObserver { NotificationCenter.default.removeObserver(activationObserver) }
            activationObserver = nil
            if let window {
                activationObserver = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.applyWindowPolicy() }
                }
            }
            applyWindowPolicy()
            installClosePolicy()
        }

        func applyWindowPolicy() {
            guard let window else { return }
            window.tabbingMode = .disallowed
            var behavior = window.collectionBehavior
            behavior.subtract([.fullScreenPrimary, .fullScreenAuxiliary, .fullScreenAllowsTiling])
            behavior.formUnion([.fullScreenNone, .fullScreenDisallowsTiling])
            window.collectionBehavior = behavior
            installClosePolicy()
        }
    }

    final class ClosePolicy: NSObject, NSWindowDelegate {
        nonisolated(unsafe) weak var original: (any NSWindowDelegate)?
        weak var localConfigService: LocalConfigService?

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            if let localConfigService, localConfigService.hasUnsavedChanges {
                localConfigService.withDiscardConfirmation(in: sender) { [weak sender] in
                    // Wait until AppKit has detached the confirmation sheet.
                    DispatchQueue.main.async { sender?.performClose(nil) }
                }
                return false
            }
            return original?.windowShouldClose?(sender) ?? true
        }

        nonisolated override func responds(to aSelector: Selector!) -> Bool {
            super.responds(to: aSelector) || original?.responds(to: aSelector) == true
        }

        nonisolated override func forwardingTarget(for aSelector: Selector!) -> Any? {
            if original?.responds(to: aSelector) == true { return original }
            return super.forwardingTarget(for: aSelector)
        }
    }
}
