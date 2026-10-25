// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

struct ColorSettingView: View {
    let configKey: ConfigKey
    @Environment(\.configService) private var configService
    @State private var draft = ""
    @State private var invalidInput = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField("Default", text: $draft)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit { commit() }
                .onChange(of: isFocused) { _, focused in if !focused { commit() } }
                .onChange(of: configService.effectiveString(for: configKey), initial: true) { _, value in
                    draft = value
                    invalidInput = false
                }
                .overlay(alignment: .trailing) {
                    if invalidInput { Image(systemName: "exclamationmark.circle").foregroundStyle(.red).padding(.trailing, 4) }
                }
                .accessibilityLabel("\(configKey.rawValue) color")
            ColorPicker(configKey.rawValue, selection: Binding(
                get: { ColorValue(hex: configService.resolvedColor(for: configKey))?.nsColor ?? .gray },
                set: { color in
                    guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return }
                    let value = ColorValue(red: UInt8((rgb.redComponent * 255).rounded()), green: UInt8((rgb.greenComponent * 255).rounded()), blue: UInt8((rgb.blueComponent * 255).rounded()))
                    configService.setString(value.hexString, for: configKey)
                }
            ), supportsOpacity: false)
            .labelsHidden()
            .accessibilityLabel("Choose \(configKey.rawValue)")
        }
        .help(invalidInput ? "Enter a hex color, a color name, cell-foreground, cell-background, or leave empty for the default." : "Leave empty to use Ghostty’s default color.")
    }

    private func commit() {
        let value = draft.trimmingCharacters(in: .whitespaces)
        guard value != configService.effectiveString(for: configKey) else { return }
        if value.isEmpty {
            configService.resetSetting(configKey)
            draft = configService.effectiveString(for: configKey)
        } else if let color = ColorValue(hex: value) {
            configService.setString(color.hexString, for: configKey)
        } else if value == "cell-foreground" || value == "cell-background" || value.range(of: "^[A-Za-z][A-Za-z0-9 ]*$", options: .regularExpression) != nil {
            // Ghostty accepts X11 color names; preserve them for Ghostty to
            // resolve rather than restricting them to AppKit asset names.
            configService.setString(value, for: configKey)
        } else {
            invalidInput = true
            return
        }
        invalidInput = false
    }
}
