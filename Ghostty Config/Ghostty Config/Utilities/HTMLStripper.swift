// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

// MARK: - HTML Stripper (Single source of truth)

enum HTMLStripper {
    static func strip(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
