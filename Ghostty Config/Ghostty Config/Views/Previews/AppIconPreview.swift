// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

struct AppIconPreview: View {
    @Environment(\.configService) private var configService
    private let builtInIcons = ["official", "blueprint", "chalkboard", "microchip", "glass", "holographic", "paper", "retro", "xray"]

    var body: some View {
        let style = configService.string(for: .macosIcon)
        VStack(spacing: 8) {
            Group {
                if style == "custom-style" {
                    ZStack {
                        asset("frame-" + configService.string(for: .macosIconFrame))
                        tint(configService.string(for: .macosIconScreenColor), fallback: "#4F5A6F", mask: "screen-mask")
                        tint(configService.string(for: .macosIconGhostColor), fallback: "#F6F7FB", mask: "ghost-mask")
                        asset("crt")
                        asset("gloss")
                    }
                } else if style == "custom", let image = NSImage(contentsOfFile: configService.string(for: .macosCustomIcon)) {
                    Image(nsImage: image).resizable().scaledToFit()
                } else {
                    asset(builtInIcons.contains(style) ? style : "official")
                }
            }
            .frame(width: 128, height: 128)
            .accessibilityLabel("Ghostty \(style) icon preview")
            Text(style == "custom-style" ? "Custom style" : style.capitalized).font(.caption).foregroundStyle(.secondary)
            if style == "custom-style" && (configService.string(for: .macosIconGhostColor).isEmpty || configService.string(for: .macosIconScreenColor).isEmpty) {
                Text("Set both ghost and screen colors to use this custom style.").font(.caption).foregroundStyle(.secondary)
            } else if style == "custom" {
                Text("Custom files must be accessible to this app for preview.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func asset(_ name: String) -> some View { Image("Ghostty-" + name).resizable().scaledToFit() }

    private func tint(_ hex: String, fallback: String, mask: String) -> some View {
        (ColorValue(hex: hex)?.nsColor ?? ColorValue(hex: fallback)!.nsColor)
            .mask { asset(mask) }
    }
}
