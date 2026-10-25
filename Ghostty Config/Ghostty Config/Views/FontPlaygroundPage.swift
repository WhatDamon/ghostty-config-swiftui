// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Font Playground Page

struct FontPlaygroundPage: View {
    @Environment(\.configService) private var configService
    @State private var testText = "The quick brown fox jumps over the lazy dog. 0123456789"
    @State private var boldTest = false
    @State private var italicTest = false
    @State private var customFontName = ""

    @State private var fontSize: Double = 13
    private var bgHex: String { configService.resolvedColor(for: .background).nilIfEmpty ?? "#282c34" }
    private var fgHex: String { configService.resolvedColor(for: .foreground).nilIfEmpty ?? "#c5c8c6" }
    private var palette: [String] { configService.effectivePalette }
    private var nsFontName: String {
        let fontFamily = configService.array(for: .fontFamily).first ?? ""
        let override = customFontName.trimmingCharacters(in: .whitespaces)
        return override.isEmpty ? (fontFamily.isEmpty ? "JetBrainsMono NF" : fontFamily) : override
    }

    var body: some View {
        PageView(title: "Font Playground") {
            VStack(spacing: 20) {
                Text("Try locally installed fonts. Changes on this page do not modify your configuration.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                terminalPreviewSection
                fontPreviewSection
                controlsSection
                testTextSection
            }
            .padding()
        }
    }

    // MARK: - Terminal Preview

    private var terminalPreviewSection: some View {
        let bg = ColorValue(hex: bgHex)?.nsColor ?? Color(.textBackgroundColor)
        let fg = ColorValue(hex: fgHex)?.nsColor ?? .gray
        let selBg = ColorValue(hex: configService.resolvedColor(for: .selectionBackground).nilIfEmpty ?? fgHex)?.nsColor ?? fg
        let selFg = ColorValue(hex: configService.resolvedColor(for: .selectionForeground).nilIfEmpty ?? bgHex)?.nsColor ?? bg

        return GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                promptLine(fg: fg)
                    .font(.custom(nsFontName, size: fontSize - 1))

                VStack(alignment: .leading, spacing: 3) {
                    dirRow()
                    fileRow()
                    symlinkRow()
                }
                .font(.custom(nsFontName, size: fontSize - 1))

                Divider().padding(.vertical, 2)

                HStack(spacing: 0) {
                    Text("Selected text appears ")
                    Text("like this")
                        .foregroundStyle(selFg)
                        .background(selBg)
                    Text(" in the terminal.")
                }
                .font(.custom(nsFontName, size: fontSize - 1))
                .foregroundStyle(fg)

                HStack(spacing: 4) {
                    Text("Icons: ")
                        .foregroundStyle(swatchColor(6))
                    Text("\u{f5c0} \u{e0b0} \u{f16f} \u{f1f8}")
                        .font(.custom(nsFontName, size: fontSize))
                        .foregroundStyle(swatchColor(2))
                    Text("Powerline")
                        .foregroundStyle(swatchColor(0))
                        .background(swatchColor(1))
                }
                .font(.custom(nsFontName, size: fontSize - 1))
                .foregroundStyle(fg)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        } label: {
            Text("Terminal Preview")
                .font(.headline)
        }
    }

    // MARK: - Font Preview

    private var fontPreviewSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(testText)
                    .font(.custom(nsFontName, size: fontSize))
                    .fontWeight(boldTest ? .bold : .regular)
                    .italic(italicTest)
                Text("ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz")
                    .font(.custom(nsFontName, size: fontSize))
                    .fontWeight(boldTest ? .bold : .regular)
                    .italic(italicTest)
                Text("!@#$%^&*()_+-=[]{}|;':\",./<>?~`")
                    .font(.custom(nsFontName, size: fontSize))
                    .fontWeight(boldTest ? .bold : .regular)
                    .italic(italicTest)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.textBackgroundColor).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } label: {
            Text("Font Preview")
                .font(.headline)
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Text("Font:")
                    TextField("Font name (e.g. JetBrainsMono NF)", text: $customFontName)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 16) {
                    Toggle("Bold", isOn: $boldTest)
                    Toggle("Italic", isOn: $italicTest)
                }

                HStack {
                    Text("Size: \(String(format: "%.1f", fontSize))pt")
                        .frame(width: 80, alignment: .leading)
                    Slider(value: Binding(
                        get: { fontSize },
                        set: { fontSize = $0 }
                    ), in: 4...60, step: 0.5)
                }
            }
        } label: {
            Text("Controls")
                .font(.headline)
        }
    }

    // MARK: - Test Text

    private var testTextSection: some View {
        GroupBox {
            TextEditor(text: $testText)
                .font(.body)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                )
        } label: {
            Text("Test Text")
                .font(.headline)
        }
    }

    // MARK: - Helpers

    private func swatchColor(_ index: Int) -> Color {
        guard index < palette.count, !palette[index].isEmpty else { return .gray }
        return ColorValue(hex: palette[index])?.nsColor ?? .gray
    }

    private func promptLine(fg: Color) -> some View {
        HStack(spacing: 0) {
            Text("john").foregroundStyle(swatchColor(2))
            Text("@").foregroundStyle(.orange)
            Text("doe-pc").foregroundStyle(.blue)
            Text(" ~ $").foregroundStyle(.red).bold()
            Text(" eza -la --color=always --icons").foregroundStyle(fg)
        }
    }

    private func dirRow() -> some View {
        HStack(spacing: 0) {
            Text("d").foregroundStyle(swatchColor(12))
            Text("r").foregroundStyle(swatchColor(11))
            Text("w").foregroundStyle(swatchColor(9))
            Text("x").foregroundStyle(swatchColor(10))
            Text("------  -    ghostty  ").foregroundStyle(swatchColor(8))
            Text("22 Aug 13:42  ").foregroundStyle(swatchColor(4))
            Text("\u{f5c0} .cache").foregroundStyle(swatchColor(4))
        }
    }

    private func fileRow() -> some View {
        HStack(spacing: 0) {
            Text("-").foregroundStyle(swatchColor(7))
            Text("r").foregroundStyle(swatchColor(11))
            Text("w").foregroundStyle(swatchColor(9))
            Text("-").foregroundStyle(swatchColor(8))
            Text("r").foregroundStyle(swatchColor(3))
            Text("--  ").foregroundStyle(swatchColor(8))
            Text("2.5k  ghostty  ").foregroundStyle(swatchColor(11))
            Text("2 Mar 02:49  ").foregroundStyle(swatchColor(4))
            Text("\u{f16f} .viminfo").foregroundStyle(swatchColor(7))
        }
    }

    private func symlinkRow() -> some View {
        HStack(spacing: 0) {
            Text("l").foregroundStyle(swatchColor(12))
            Text("r").foregroundStyle(swatchColor(11))
            Text("w").foregroundStyle(swatchColor(9))
            Text("x").foregroundStyle(swatchColor(10))
            Text("r").foregroundStyle(swatchColor(3))
            Text("w").foregroundStyle(swatchColor(1))
            Text("x").foregroundStyle(swatchColor(2))
            Text("r").foregroundStyle(swatchColor(3))
            Text("w").foregroundStyle(swatchColor(1))
            Text("x  -  ghostty  ").foregroundStyle(swatchColor(11))
            Text("9 Feb 20:32  ").foregroundStyle(swatchColor(4))
            Text("\u{f5dd} etc -> /etc").foregroundStyle(swatchColor(6))
        }
    }
}

// MARK: - Extensions

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
