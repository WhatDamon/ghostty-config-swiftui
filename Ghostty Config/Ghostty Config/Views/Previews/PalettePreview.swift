// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Palette Preview

struct PalettePreview: View {
    @Environment(\.configService) private var configService

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 16)

    var body: some View {
        let palette = configService.effectivePalette
        VStack(alignment: .leading, spacing: 8) {
            Text("Palette Preview (first 16 colors)")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<16, id: \.self) { index in
                    let hex = index < palette.count ? palette[index] : ""
                    RoundedRectangle(cornerRadius: 4)
                        .fill(hexToColor(hex))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor).opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func hexToColor(_ hex: String) -> Color {
        guard !hex.isEmpty else { return Color(.textBackgroundColor) }
        let hexStr = hex.hasPrefix("#") ? hex : "#\(hex)"
        return ColorValue(hex: hexStr)?.nsColor ?? Color(.textBackgroundColor)
    }
}
