// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

enum PreviewMode: String, CaseIterable { case system, light, dark }
enum ColorSource: Equatable { case override, theme(String), `default` }

struct ThemeColors: Decodable {
    var palette: [String]
    let background: String?
    let foreground: String?
    let cursorColor: String?
    let cursorText: String?
    let selectionBackground: String?
    let selectionForeground: String?

    func value(for key: ConfigKey) -> String? {
        switch key {
        case .background: background
        case .foreground: foreground
        case .cursorColor: cursorColor
        case .cursorText: cursorText
        case .selectionBackground: selectionBackground
        case .selectionForeground: selectionForeground
        default: nil
        }
    }
}

enum ThemeSelection: Equatable {
    case unset
    case single(String)
    case dual(light: String, dark: String)

    init(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { self = .unset; return }
        var sides: [String: String] = [:]
        for part in trimmed.split(separator: ",") {
            let pair = part.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            if pair.count == 2, ["light", "dark"].contains(pair[0].lowercased()) {
                sides[pair[0].lowercased()] = pair[1].trimmingCharacters(in: .whitespaces)
            }
        }
        if let light = sides["light"], let dark = sides["dark"], !light.isEmpty, !dark.isEmpty {
            self = .dual(light: light, dark: dark)
        } else { self = .single(trimmed) }
    }

    var raw: String {
        switch self {
        case .unset: ""
        case .single(let name): name
        case .dual(let light, let dark): "light:\(light),dark:\(dark)"
        }
    }
    func name(isLight: Bool) -> String? {
        switch self {
        case .unset: nil
        case .single(let name): name
        case .dual(let light, let dark): isLight ? light : dark
        }
    }
}
