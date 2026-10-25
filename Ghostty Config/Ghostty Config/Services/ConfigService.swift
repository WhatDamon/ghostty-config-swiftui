// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class ConfigService {
    nonisolated deinit {}

    private(set) var config: [String: ConfigValue]
    private let defaults: [String: ConfigValue]
    private(set) var explicitColors = Set<ConfigKey>()
    private(set) var paletteOverrides: [Int: String] = [:]
    var pendingImportText: String?
    var previewMode: PreviewMode = .system
    var systemIsLight = false

    static let schemeKeys: Set<ConfigKey> = [.background, .foreground, .cursorColor, .cursorText, .selectionBackground, .selectionForeground]

    init() {
        let values = Dictionary(uniqueKeysWithValues: PanelRegistry.definitions.map { ($0.key.camelCase, $0.value.defaultValue) })
        defaults = values
        config = values
    }

    func string(for key: ConfigKey) -> String { config[key.camelCase]?.text ?? "" }
    func bool(for key: ConfigKey) -> Bool { string(for: key) == "true" }
    func double(for key: ConfigKey) -> Double { Double(string(for: key)) ?? 0 }
    func int(for key: ConfigKey) -> Int { Int(exactly: double(for: key)) ?? 0 }
    func array(for key: ConfigKey) -> [String] {
        guard case .list(let values) = config[key.camelCase] else { return [] }
        return values
    }

    func set(_ values: [String], for key: ConfigKey) {
        if key == .palette {
            let previous = array(for: key)
            for (index, color) in values.enumerated() where index < 256 && (index >= previous.count || color != previous[index]) { setPalette(color, at: index) }
        } else { config[key.camelCase] = .list(values) }
    }
    func setString(_ value: String, for key: ConfigKey) {
        config[key.camelCase] = PanelRegistry.definitions[key]?.repeatable == true ? .list(value.components(separatedBy: "\n")) : .scalar(value)
        if Self.schemeKeys.contains(key) { explicitColors.insert(key) }
    }
    func setBool(_ value: Bool, for key: ConfigKey) { setString(value ? "true" : "false", for: key) }
    func setInt(_ value: Int, for key: ConfigKey) { setString(String(value), for: key) }
    func setDouble(_ value: Double, for key: ConfigKey) { guard value.isFinite else { return }; setString(SettingCodecs.number(value), for: key) }

    func isNonDefault(_ key: ConfigKey) -> Bool {
        if key == .palette { return !paletteOverrides.isEmpty }
        if Self.schemeKeys.contains(key) { return explicitColors.contains(key) }
        return config[key.camelCase] != defaults[key.camelCase]
    }
    func resetSetting(_ key: ConfigKey) {
        config[key.camelCase] = defaults[key.camelCase]
        explicitColors.remove(key)
        if key == .palette { paletteOverrides = [:] }
    }
    func resetColorScheme() {
        for key in Self.schemeKeys.union([.theme, .palette]) { resetSetting(key) }
    }

    var themeSelection: ThemeSelection { ThemeSelection(string(for: .theme)) }
    var previewIsLight: Bool { previewMode == .system ? systemIsLight : previewMode == .light }
    var selectedThemeName: String? { themeSelection.name(isLight: previewIsLight) }
    var activeThemeName: String? { selectedThemeName.flatMap { PanelRegistry.snapshot.themes[$0] == nil ? nil : $0 } }
    private var activeTheme: ThemeColors? { activeThemeName.flatMap { PanelRegistry.snapshot.themes[$0] } }

    func effectiveString(for key: ConfigKey) -> String {
        guard Self.schemeKeys.contains(key), !explicitColors.contains(key) else { return string(for: key) }
        return activeTheme?.value(for: key) ?? string(for: key)
    }
    func colorSource(for key: ConfigKey) -> ColorSource {
        if explicitColors.contains(key) { return .override }
        if let name = activeThemeName, activeTheme?.value(for: key) != nil { return .theme(name) }
        return .default
    }
    var effectivePalette: [String] {
        array(for: .palette).enumerated().map { index, color in
            paletteOverrides[index] ?? activeTheme.flatMap { index < $0.palette.count ? $0.palette[index] : nil } ?? color
        }
    }
    func paletteSource(at index: Int) -> ColorSource {
        if paletteOverrides[index] != nil { return .override }
        if let name = activeThemeName, let theme = activeTheme, index < theme.palette.count { return .theme(name) }
        return .default
    }
    func setPalette(_ color: String, at index: Int) {
        guard (0..<256).contains(index) else { return }
        let normalized = ColorValue(hex: color)?.hexString ?? color
        paletteOverrides[index] = normalized
        var values = array(for: .palette)
        values[index] = normalized
        config[ConfigKey.palette.camelCase] = .list(values)
    }
    func resetPalette(at index: Int) {
        paletteOverrides[index] = nil
        var values = array(for: .palette)
        if case .list(let original) = defaults[ConfigKey.palette.camelCase], values.indices.contains(index) { values[index] = original[index] }
        config[ConfigKey.palette.camelCase] = .list(values)
    }

    /// Resolve Ghostty cell keywords once, so every preview agrees with editors.
    func resolvedColor(for key: ConfigKey) -> String {
        let raw = effectiveString(for: key)
        switch raw {
        case "cell-foreground": return effectiveString(for: .foreground)
        case "cell-background": return effectiveString(for: .background)
        case "":
            switch key {
            case .selectionBackground, .cursorColor: return effectiveString(for: .foreground)
            case .selectionForeground, .cursorText: return effectiveString(for: .background)
            default: return raw
            }
        default: return raw
        }
    }

    func diff() -> [String: ConfigValue] {
        var output: [String: ConfigValue] = [:]
        for (key, value) in config {
            let configKey = ConfigKey(rawValue: kebabFromCamel(key))
            if configKey == .palette {
                if !paletteOverrides.isEmpty { output[key] = .list(paletteOverrides.keys.sorted().map { "\($0)=\(paletteOverrides[$0]!)" }) }
            } else if configKey == .keybind {
                guard case .list(let current) = value, case .list(let original) = defaults[key] else { continue }
                if current == original { continue }
                if current.contains("clear") { output[key] = value; continue }
                if current.contains(where: { $0.hasPrefix("chain=") }) { output[key] = .list(["clear"] + current); continue }
                var additions = current.filter { !original.contains($0) }
                let triggers = Set(current.compactMap { parseKeybind($0).trigger.map(canonicalTrigger) })
                for binding in original where !current.contains(binding) {
                    guard let trigger = parseKeybind(binding).trigger, !triggers.contains(canonicalTrigger(trigger)) else { continue }
                    additions.append("\(formatTrigger(trigger))=unbind")
                }
                if !additions.isEmpty { output[key] = .list(additions) }
            } else if value != defaults[key] || explicitColors.contains(configKey) { output[key] = value }
        }
        return output
    }

    func stringifyConfig(includeHeader: Bool = true) -> String { serialize(diff(), includeHeader: includeHeader) }
    func serializeForShare() -> String { stringifyConfig(includeHeader: false) }
    func serialize(_ values: [String: ConfigValue], includeHeader: Bool = false) -> String {
        var lines = includeHeader ? ["# Config generated by Ghostty Config", ""] : []
        for key in values.keys.sorted() {
            for entry in values[key]!.entries { lines.append("\(kebabFromCamel(key)) = \(entry)") }
        }
        return lines.joined(separator: "\n")
    }

    func load(parsed: [String: ConfigValue]) {
        for (key, value) in parsed {
            let configKey = ConfigKey(rawValue: kebabFromCamel(key))
            if configKey == .keybind {
                let incoming = value.entries
                if incoming.contains("clear") { config[key] = value; continue }
                var current = array(for: .keybind)
                if incoming.isEmpty || current.suffix(incoming.count).elementsEqual(incoming) { continue }
                let triggers = Set(incoming.compactMap { parseKeybind($0).trigger.map(canonicalTrigger) })
                var removingParent = false
                current = current.filter { binding in
                    if binding.hasPrefix("chain=") { return !removingParent }
                    removingParent = parseKeybind(binding).trigger.map { triggers.contains(canonicalTrigger($0)) } ?? false
                    return !removingParent
                }
                config[key] = .list(current + incoming)
            } else if configKey == .palette {
                for (index, color) in value.entries.enumerated() where !color.isEmpty { setPalette(color, at: index) }
            } else {
                config[key] = value
                if Self.schemeKeys.contains(configKey) { explicitColors.insert(configKey) }
            }
        }
    }

    struct ImportChange: Identifiable {
        var id: String { key }
        let key: String
        let before: String
        let after: String
        let overridesExisting: Bool
    }
    func importChanges(_ parsed: [String: ConfigValue]) -> [ImportChange] {
        let candidate = ConfigService()
        candidate.config = config
        candidate.explicitColors = explicitColors
        candidate.paletteOverrides = paletteOverrides
        candidate.load(parsed: parsed)
        return parsed.keys.sorted().compactMap { key in
            let newValue = candidate.config[key]
            let configKey = ConfigKey(rawValue: kebabFromCamel(key))
            let changedSource = Self.schemeKeys.contains(configKey) && candidate.explicitColors.contains(configKey) != explicitColors.contains(configKey)
            guard newValue != config[key] || changedSource || (key == "palette" && candidate.paletteOverrides != paletteOverrides) else { return nil }
            let previous: String
            let next: String
            if key == "palette" {
                previous = "\(paletteOverrides.count) explicit color overrides"
                next = "\(candidate.paletteOverrides.count) explicit color overrides"
            } else {
                previous = Self.describe(config[key])
                next = Self.describe(newValue)
            }
            return ImportChange(key: kebabFromCamel(key), before: previous, after: next, overridesExisting: isNonDefault(configKey))
        }
    }

    private static func describe(_ value: ConfigValue?) -> String {
        guard let value else { return "Not set" }
        switch value {
        case .scalar(let raw): return raw.isEmpty ? "Default / unset" : raw
        case .list(let entries): return entries.isEmpty ? "Default (no entries)" : entries.map { $0.isEmpty ? "(reset earlier entries)" : $0 }.joined(separator: "\n")
        }
    }

    func kebabFromCamel(_ camel: String) -> String {
        camel.reduce(into: "") { result, character in result += character.isUppercase ? "-" + character.lowercased() : String(character) }
    }
}
