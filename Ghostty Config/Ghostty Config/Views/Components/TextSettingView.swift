// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Text Setting View

struct TextSettingView: View {
    let configKey: ConfigKey
    let placeholder: String?
    @Environment(\.configService) private var configService

    var body: some View {
        TextField(placeholder ?? configKey.camelCase, text: Binding(
            get: { configService.string(for: configKey) },
            set: { configService.setString($0, for: configKey) }
        ), axis: .vertical)
        .lineLimit(1...5)
        .textFieldStyle(.roundedBorder)
        .accessibilityLabel(configKey.rawValue)
    }
}
