// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

/// Pure value-format helpers shared by validation and native editors. Unknown
/// tokens stay in the raw value until the user deliberately changes them.
enum SettingCodecs {
    static func number(_ value: Double) -> String {
        if let integer = Int(exactly: value) { return String(integer) }
        return String(value)
    }

    struct Pair: Equatable {
        var first: String
        var second: String
        var linked: Bool
        var raw: String { linked ? first : "\(first),\(second)" }
    }
    static func pair(_ raw: String) -> Pair {
        let parts = raw.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        return Pair(first: parts.first ?? "", second: parts.count > 1 ? parts[1] : parts.first ?? "", linked: parts.count == 1)
    }
    static func scrollPair(_ raw: String) -> Pair {
        guard raw.contains(":") else { return pair(raw) }
        var result = Pair(first: "1", second: "3", linked: false)
        for part in raw.split(separator: ",") {
            let halves = part.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard halves.count == 2 else { continue }
            if halves[0] == "precision" { result.first = halves[1] }
            if halves[0] == "discrete" { result.second = halves[1] }
        }
        return result
    }
    static func scrollString(_ pair: Pair) -> String {
        pair.linked ? pair.first : "precision:\(pair.first),discrete:\(pair.second)"
    }

    static let durationUnits = ["ns", "us", "ms", "s", "m", "h", "d", "y"]
    static func durationError(_ raw: String, allowEmpty: Bool) -> String? {
        let text = raw.trimmingCharacters(in: .whitespaces)
        if text.isEmpty { return allowEmpty ? nil : "Enter a duration such as 5s or 1h30m." }
        let regex = try! NSRegularExpression(pattern: "([0-9]+)(ns|us|ms|s|m|h|d|y)")
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var cursor = 0
        var units = Set<String>()
        for match in matches {
            guard match.range.location == cursor, let range = Range(match.range(at: 2), in: text) else { return "Use a duration such as 750ms or 1h30m." }
            let unit = String(text[range])
            guard units.insert(unit).inserted else { return "Each duration unit may appear only once." }
            cursor += match.range.length
        }
        return cursor == text.utf16.count ? nil : "Use a duration such as 750ms or 1h30m."
    }

    static func features(_ raw: String, definitions: [FeatureDefinition]) -> [String: Bool] {
        let bare = raw.trimmingCharacters(in: .whitespaces).lowercased()
        var values = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, bare == "true" ? true : bare == "false" ? false : $0.default) })
        for token in raw.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            let id = token.hasPrefix("no-") ? String(token.dropFirst(3)) : token
            if values[id] != nil { values[id] = !token.hasPrefix("no-") }
        }
        return values
    }
    static func settingFeature(_ id: String, enabled: Bool, raw: String, definitions: [FeatureDefinition]) -> String {
        var values = features(raw, definitions: definitions)
        values[id] = enabled
        let known = Set(definitions.map(\.id))
        let unknown = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { token in
            let name = token.hasPrefix("no-") ? String(token.dropFirst(3)) : token
            return !known.contains(name) && token != "true" && token != "false" && !token.isEmpty
        }
        return (definitions.filter { values[$0.id] != $0.default }.map { values[$0.id] == true ? $0.id : "no-\($0.id)" } + unknown).joined(separator: ",")
    }

    static func validationError(_ raw: String, setting: SettingItem) -> String? {
        let widget = setting.widget
        switch setting.type {
        case .switch:
            return ["true", "false"].contains(raw) ? nil : "Requires true or false."
        case .number, .range, .customNumber:
            if setting.type == .customNumber, widget.presets?.contains(where: { $0.value == raw }) == true { return nil }
            if raw.isEmpty { return nil } // Explicit unset is a valid Ghostty directive.
            guard let value = Double(raw), value.isFinite else { return "Enter a finite number." }
            if widget.integer ?? (setting.type == .number || setting.type == .customNumber), value.rounded() != value { return "Enter a whole number." }
            return nil // UI convenience bounds are not Ghostty's import limits.
        case .duration: return durationError(raw, allowEmpty: true)
        case .numberUnits:
            if raw.isEmpty { return nil }
            let value = raw.hasSuffix("%") ? String(raw.dropLast()) : raw
            guard let number = Double(value), number.isFinite, number.rounded() == number else { return "Enter a whole number, optionally followed by %." }
            return nil
        case .dualNumber:
            let parts = raw.split(separator: ",", omittingEmptySubsequences: false)
            guard (1...2).contains(parts.count), parts.allSatisfy({ Double($0.trimmingCharacters(in: .whitespaces)).map { $0.isFinite && $0 >= 0 } ?? false }) else { return "Enter one or two non-negative numbers." }
            return nil
        case .scrollMultiplier:
            let pair = scrollPair(raw)
            guard !raw.isEmpty, [pair.first, pair.second].allSatisfy({ Double($0).map { $0.isFinite && $0 > 0 } ?? false }) else { return "Enter positive precision/discrete multipliers." }
            if raw.contains(":") {
                for entry in raw.split(separator: ",", omittingEmptySubsequences: false) {
                    let parts = entry.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
                    guard parts.count == 2, ["precision", "discrete"].contains(parts[0]),
                          Double(parts[1]).map({ $0.isFinite && $0 > 0 }) ?? false else { return "Use positive precision:/discrete: multipliers." }
                }
            } else if Double(raw).map({ $0.isFinite && $0 > 0 }) != true { return "Enter a positive multiplier." }
            return nil
        default: return nil
        }
    }
}
