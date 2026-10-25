// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Switch Setting View

struct SwitchSettingView: View {
    let configKey: ConfigKey
    @Environment(\.configService) private var configService

    var body: some View {
        Toggle(isOn: Binding(
            get: { configService.bool(for: configKey) },
            set: { configService.setBool($0, for: configKey) }
        )) {
            Text(configKey.rawValue)
        }
        .toggleStyle(.switch)
        .labelsHidden()
        .accessibilityLabel(configKey.rawValue)
    }
}
