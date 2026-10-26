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
    static func hideFullScreenCommands(in menu: NSMenu) {
        for item in menu.items {
            if item.action == #selector(NSWindow.toggleFullScreen(_:)), !item.isHidden {
                item.isHidden = true
            }
            if let submenu = item.submenu { hideFullScreenCommands(in: submenu) }
        }
    }

    func makeNSView(context: Context) -> WindowPolicyView { WindowPolicyView() }

    func updateNSView(_ nsView: WindowPolicyView, context: Context) {
        nsView.applyWindowPolicy()
    }

    final class WindowPolicyView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyWindowPolicy()
        }

        func applyWindowPolicy() {
            guard let window else { return }
            window.tabbingMode = .disallowed
            var behavior = window.collectionBehavior
            behavior.subtract([.fullScreenPrimary, .fullScreenAuxiliary, .fullScreenAllowsTiling])
            behavior.formUnion([.fullScreenNone, .fullScreenDisallowsTiling])
            window.collectionBehavior = behavior
        }
    }
}
