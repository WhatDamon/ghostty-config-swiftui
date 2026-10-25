// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

struct NumberSettingView: View {
    let configKey: ConfigKey
    let minValue: Double?
    let maxValue: Double?
    var step: Double = 1
    @Environment(\.configService) private var configService
    @State private var textValue = ""
    @State private var invalidInput = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 4) {
            TextField("Default", text: $textValue)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .focused($isFocused)
                .onSubmit { commitValue() }
                .onChange(of: isFocused) { _, focused in if !focused { commitValue() } }
                .onChange(of: configService.config[configKey.camelCase], initial: true) { _, _ in
                    syncTextFromConfig()
                }
                .overlay(alignment: .trailing) {
                    if invalidInput { Image(systemName: "exclamationmark.circle").foregroundStyle(.red).padding(.trailing, 4) }
                }
                .accessibilityLabel("\(configKey.rawValue) value")
            Stepper("Adjust \(configKey.rawValue)", onIncrement: { adjust(by: step) }, onDecrement: { adjust(by: -step) })
                .labelsHidden()
                .fixedSize()
        }
        .help(invalidInput ? "Enter a finite number within the allowed range." : "")
    }

    private func syncTextFromConfig() {
        textValue = configService.string(for: configKey)
        invalidInput = false
    }

    private func commitValue() {
        let trimmed = textValue.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            configService.resetSetting(configKey)
            syncTextFromConfig()
            return
        }
        guard let value = Double(trimmed), value.isFinite,
              PanelRegistry.settings[configKey].map({ SettingCodecs.validationError(trimmed, setting: $0) == nil }) ?? true else {
            invalidInput = true
            return
        }
        configService.setDouble(clamp(value), for: configKey)
        syncTextFromConfig()
    }

    private func clamp(_ value: Double) -> Double {
        Swift.min(maxValue ?? .greatestFiniteMagnitude, Swift.max(minValue ?? -.greatestFiniteMagnitude, value))
    }

    private func adjust(by delta: Double) {
        let value = configService.double(for: configKey) + delta
        guard value.isFinite else { return }
        configService.setDouble(clamp(value), for: configKey)
        syncTextFromConfig()
    }
}
