// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import AppKit
import SwiftUI

/// Window tabbing and toolbar appearance are independent policies. Keep a real
/// native toolbar while explicitly opting every app window out of tab groups.
struct AppWindowConfiguration: NSViewRepresentable {
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
            window?.tabbingMode = .disallowed
        }
    }
}
