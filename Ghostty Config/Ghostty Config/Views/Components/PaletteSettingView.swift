// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Palette Setting View

struct PaletteSettingView: View {
    let configKey: ConfigKey
    @Environment(\.configService) private var configService

    private let columns = Array(repeating: GridItem(.flexible(minimum: 24), spacing: 4), count: 16)

    var body: some View {
        let palette = configService.effectivePalette
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<palette.count, id: \.self) { index in
                let hex = palette[index]
                PaletteSwatch(index: index, hex: hex) { newHex in
                    configService.setPalette(newHex, at: index)
                }
                .contextMenu {
                    if configService.paletteOverrides[index] != nil {
                        Button("Follow theme or default") { configService.resetPalette(at: index) }
                    }
                }
                .help(sourceDescription(index))
            }
        }
        .padding(.vertical, 8)
    }
    private func sourceDescription(_ index: Int) -> String {
        switch configService.paletteSource(at: index) {
        case .override: "Color \(index): custom override. Right-click to follow theme."
        case .theme(let name): "Color \(index): inherited from \(name)"
        case .default: "Color \(index): default"
        }
    }
}

// MARK: - Palette Swatch

struct PaletteSwatch: View {
    let index: Int
    let hex: String
    let onUpdate: (String) -> Void
    @State private var showEditor = false
    @State private var editHex: String = ""

    var body: some View {
        Button {
            editHex = hex
            showEditor.toggle()
        } label: {
            RoundedRectangle(cornerRadius: 3)
            .fill(swatchColor)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Text("\(index)")
                    .font(.system(size: 8))
                    .foregroundStyle(readableTextColor)
            )
        }
            .buttonStyle(.plain)
            .help("Palette \(index): \(hex)")
            .popover(isPresented: $showEditor) {
                VStack(spacing: 8) {
                    Text("Color \(index)")
                        .font(.headline)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(swatchColor)
                        .frame(height: 40)
                    HStack {
                        TextField("#RRGGBB", text: $editHex)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Hex value")
                        Button("Apply") {
                            var hexVal = editHex.trimmingCharacters(in: .whitespaces)
                            if !hexVal.hasPrefix("#") { hexVal = "#\(hexVal)" }
                            if let color = ColorValue(hex: hexVal) {
                                onUpdate(color.hexString)
                                showEditor = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .frame(width: 200)
            }
            .accessibilityLabel("Palette color \(index)")
    }

    private var swatchColor: Color {
        guard !hex.isEmpty, ColorValue(hex: hex) != nil else {
            return Color(.textBackgroundColor)
        }
        return ColorValue(hex: hex)?.nsColor ?? Color(.textBackgroundColor)
    }

    private var readableTextColor: Color {
        ColorValue(hex: hex)?.readableTextColor ?? .white
    }
}
