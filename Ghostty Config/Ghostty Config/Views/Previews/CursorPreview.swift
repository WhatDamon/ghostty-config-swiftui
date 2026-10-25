// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Combine
import SwiftUI

// MARK: - Cursor Preview

struct CursorPreview: View {
    @Environment(\.configService) private var configService
    @State private var cursorVisible = true

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let cursorStyle: String = configService.string(for: .cursorStyle)
        let cursorColor: String = configService.resolvedColor(for: .cursorColor)
        let bgColor: String = configService.resolvedColor(for: .background)
        let fgColor: String = configService.resolvedColor(for: .foreground)

        let bg = ColorValue(hex: bgColor.hasPrefix("#") ? bgColor : "#\(bgColor)")?.nsColor ?? Color(red: 0.157, green: 0.173, blue: 0.204)
        let fg = ColorValue(hex: fgColor.hasPrefix("#") ? fgColor : "#\(fgColor)")?.nsColor ?? Color.white
        let cursorFill = cursorColor.isEmpty ? fg : (ColorValue(hex: cursorColor.hasPrefix("#") ? cursorColor : "#\(cursorColor)")?.nsColor ?? fg)

        VStack(alignment: .leading, spacing: 8) {
            Text("Cursor Preview")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text("~ $ ")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(fg)

                cursorShape(style: cursorStyle, color: cursorFill)
                    .opacity((configService.string(for: .cursorStyleBlink) == "false" || cursorVisible) ? configService.double(for: .cursorOpacity) : 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                cursorVisible.toggle()
            }
        }
    }

    @ViewBuilder
    private func cursorShape(style: String, color: Color) -> some View {
        switch style {
        case "bar":
            Rectangle()
                .fill(color)
                .frame(width: 2, height: 18)
        case "underline":
            Rectangle()
                .fill(color)
                .frame(width: 10, height: 3)
                .offset(y: 8)
        case "block_hollow":
            RoundedRectangle(cornerRadius: 2)
                .stroke(color, lineWidth: 2)
                .frame(width: 10, height: 18)
        default: // block
            Text("A")
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(ColorValue(hex: configService.resolvedColor(for: .cursorText))?.nsColor ?? ColorValue(hex: configService.resolvedColor(for: .background))?.nsColor ?? .black)
                .frame(width: 10, height: 18)
                .background(color)
        }
    }
}
