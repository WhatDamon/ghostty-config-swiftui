// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

struct DropdownSettingView: View {
    let configKey: ConfigKey
    let options: [DropdownOption]
    let allowEmpty: Bool
    var emptyLabel = "Default"
    @Environment(\.configService) private var configService

    var body: some View {
        let current = configService.string(for: configKey)
        Picker(configKey.rawValue, selection: Binding(
            get: { configService.string(for: configKey) },
            set: { configService.setString($0, for: configKey) }
        )) {
            if allowEmpty && !options.contains(where: { $0.value.isEmpty }) { Text(emptyLabel).tag("") }
            if !options.contains(where: { $0.value == current }) && !(allowEmpty && current.isEmpty) {
                Text(current.isEmpty ? "Default" : current).tag(current)
            }
            ForEach(options) { option in Text(option.name).tag(option.value) }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .accessibilityLabel(configKey.rawValue)
    }
}
