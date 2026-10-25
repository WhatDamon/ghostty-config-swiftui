// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

struct ConfigParseResult {
    var values: [String: ConfigValue] = [:]
    var diagnostics: [String] = []
    var entryCount = 0
}

struct ConfigParserService {
    private static let lineRegex = try! NSRegularExpression(pattern: "^([a-zA-Z0-9_-]+)\\s*=\\s*(.*)$")

    static func parse(_ text: String) -> [String: ConfigValue] { inspect(text).values }

    static func inspect(_ text: String) -> ConfigParseResult {
        var result = ConfigParseResult()
        var palette = Array(repeating: "", count: 256)
        var hasPalette = false
        for (offset, line) in text.components(separatedBy: .newlines).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            let number = offset + 1
            guard let match = lineRegex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
                  let keyRange = Range(match.range(at: 1), in: trimmed), let valueRange = Range(match.range(at: 2), in: trimmed) else {
                result.diagnostics.append("Line \(number): expected key = value."); continue
            }
            let rawKey = String(trimmed[keyRange])
            let value = String(trimmed[valueRange]).trimmingCharacters(in: .whitespaces)
            let key = ConfigKey(rawValue: rawKey)
            let name = camelCase(rawKey)
            if key == .palette {
                let parts = value.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard parts.count == 2, let index = Int(parts[0].trimmingCharacters(in: .whitespaces)), (0..<256).contains(index),
                      let color = ColorValue(hex: parts[1].trimmingCharacters(in: .whitespaces)) else {
                    result.diagnostics.append("Line \(number): palette requires an index from 0 to 255 and a hex color."); continue
                }
                palette[index] = color.hexString
                hasPalette = true
            } else if let setting = PanelRegistry.definitions[key] {
                if !setting.repeatable, let error = SettingCodecs.validationError(value, setting: setting) {
                    result.diagnostics.append("Line \(number): \(rawKey): \(error)"); continue
                }
                if setting.repeatable {
                    var entries = result.values[name]?.entries ?? []
                    entries.append(value) // Empty entries are explicit reset directives, not absent entries.
                    result.values[name] = .list(entries)
                } else {
                    let color = setting.type == .color || setting.type == .customColor
                    result.values[name] = .scalar(color ? ColorValue(hex: value)?.hexString ?? value : value)
                }
                if key == .keybind {
                    let errors = parseKeybind(value).errors
                    if !errors.isEmpty { result.diagnostics.append("Line \(number): keybind preserved; \(errors.joined(separator: "; ")).") }
                }
            } else if let previous = result.values[name] {
                result.values[name] = .list(previous.entries + [value])
            } else { result.values[name] = .scalar(value) }
            result.entryCount += 1
        }
        if hasPalette { result.values["palette"] = .list(palette) }
        return result
    }

    static func camelCase(_ key: String) -> String {
        let parts = key.split(separator: "-")
        return (parts.first.map(String.init) ?? "") + parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }
}
