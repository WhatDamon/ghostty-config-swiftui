// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Base Color Preview

struct BaseColorPreview: View {
    @Environment(\.configService) private var configService

    var body: some View {
        let bg = configService.resolvedColor(for: .background)
        let fg = configService.resolvedColor(for: .foreground)
        let selBg = configService.resolvedColor(for: .selectionBackground)
        let selFg = configService.resolvedColor(for: .selectionForeground)

        let bgColor = ColorValue(hex: bg.hasPrefix("#") ? bg : "#\(bg)")?.nsColor ?? Color(red: 0.157, green: 0.173, blue: 0.204)
        let fgColor = ColorValue(hex: fg.hasPrefix("#") ? fg : "#\(fg)")?.nsColor ?? Color.white
        let selBgColor = ColorValue(hex: selBg.hasPrefix("#") ? selBg : "#\(selBg)")?.nsColor ?? fgColor
        let selFgColor = ColorValue(hex: selFg.hasPrefix("#") ? selFg : "#\(selFg)")?.nsColor ?? bgColor

        VStack(alignment: .leading, spacing: 0) {
            Text("Terminal Preview")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text("~ $ echo \"Hello, Ghostty!\"")
                    .font(.system(size: 13, design: .monospaced))
                Text("Hello, Ghostty!")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(fgColor)

                HStack(spacing: 0) {
                    Text("Hello, ")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(selFgColor)
                        .background(selBgColor)
                    Text(" Ghostty!")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(fgColor)
                }

                Text("~ $ ▊")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(fgColor)
            }
            .foregroundStyle(fgColor)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
