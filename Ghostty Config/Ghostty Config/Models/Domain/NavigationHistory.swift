// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

/// One visited location. Search destinations retain their setting so history can
/// restore the highlighted row as well as the containing category.
struct NavigationDestination: Equatable {
    let panelID: String
    var settingKey: ConfigKey? = nil

    static let home = NavigationDestination(panelID: "home")
}

/// A window-local browser-style history. Traversal only moves the cursor; it does
/// not append another visit. Visiting the current location preserves forward history.
struct NavigationHistory {
    private(set) var entries: [NavigationDestination]
    private(set) var index = 0

    init(initial: NavigationDestination = .home) { entries = [initial] }

    var current: NavigationDestination { entries[index] }
    var canGoBack: Bool { index > 0 }
    var canGoForward: Bool { index + 1 < entries.count }

    mutating func visit(_ destination: NavigationDestination) {
        guard destination != current else { return }
        entries.removeSubrange((index + 1)..<entries.count)
        entries.append(destination)
        index = entries.count - 1
    }

    mutating func goBack() {
        guard canGoBack else { return }
        index -= 1
    }

    mutating func goForward() {
        guard canGoForward else { return }
        index += 1
    }
}
