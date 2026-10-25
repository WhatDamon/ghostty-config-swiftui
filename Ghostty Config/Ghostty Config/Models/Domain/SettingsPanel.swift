// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

/// Config values stay in Ghostty's wire format. UI codecs never change storage
/// shape based on how a value happens to look (e.g. a numeric-looking path).
enum ConfigValue: Equatable, Codable {
    case scalar(String)
    case list([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let list = try? container.decode([String].self) { self = .list(list) }
        else { self = .scalar(try container.decode(String.self)) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .scalar(let value): try container.encode(value)
        case .list(let values): try container.encode(values)
        }
    }

    var text: String {
        switch self { case .scalar(let value): value; case .list(let values): values.joined(separator: "\n") }
    }
    var entries: [String] {
        switch self { case .scalar(let value): [value]; case .list(let values): values }
    }
}

enum SettingUIType: String, Decodable {
    case `switch`, text, number, range, dropdown, color, palette, keybinds, theme
    case repeatableText = "repeatable-text"
    case featureList = "feature-list"
    case pill, duration
    case dualNumber = "dual-number"
    case customColor = "custom-color"
    case customNumber = "custom-number"
    case scrollMultiplier = "scroll-multiplier"
    case numberUnits = "number-units"
}

struct DropdownOption: Identifiable, Decodable, Equatable {
    var id: String { value }
    let name: String
    let value: String
    let description: String?

    init(name: String, value: String? = nil, description: String? = nil) {
        self.name = name; self.value = value ?? name; self.description = description
    }
    private enum CodingKeys: String, CodingKey { case name, label, value, description }
    init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) { self.init(name: string); return }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let value = try c.decode(String.self, forKey: .value)
        let name = try c.decodeIfPresent(String.self, forKey: .name) ?? c.decodeIfPresent(String.self, forKey: .label) ?? value
        self.init(name: name, value: value, description: try c.decodeIfPresent(String.self, forKey: .description))
    }
}

struct FeatureDefinition: Decodable, Identifiable {
    let id: String
    let label: String
    let `default`: Bool
    let description: String?
}

struct WidgetDefinition: Decodable {
    let type: SettingUIType
    var min: Double? = nil
    var max: Double? = nil
    var step: Double? = nil
    var integer: Bool? = nil
    var placeholder: String? = nil
    var options: [DropdownOption]? = nil
    var presets: [DropdownOption]? = nil
    var labels: [String]? = nil
    var features: [FeatureDefinition]? = nil
    var showLabels: Bool? = nil
    var allowEmpty: Bool? = nil
    var emptyLabel: String? = nil
    var canReorder: Bool? = nil
}

struct SettingDefinition: Decodable {
    let key: String
    let name: String
    let `default`: ConfigValue
    let description: String
    let note: String?
    let platform: [String]?
    let since: String?
    let disabled: Bool?
    let repeatable: Bool?
    let widget: WidgetDefinition?
}

struct SettingItem: Identifiable {
    var id: String { configKey.camelCase }
    let configKey: ConfigKey
    let definition: SettingDefinition
    var name: String { definition.name.isEmpty ? (configKey == .keybind ? "Keybindings" : "256-color palette") : definition.name }
    var type: SettingUIType {
        if configKey == .keybind { return .keybinds }
        return definition.widget?.type ?? (repeatable ? .repeatableText : .text)
    }
    var widget: WidgetDefinition { definition.widget ?? WidgetDefinition(type: repeatable ? .repeatableText : .text) }
    var defaultValue: ConfigValue { definition.default }
    var note: String? { definition.note }
    var placeholder: String? { widget.placeholder }
    var minValue: Double? { widget.min }
    var maxValue: Double? { widget.max }
    var step: Double? { widget.step }
    var options: [DropdownOption]? { widget.options }
    var showLabels: Bool? { widget.showLabels }
    var allowEmpty: Bool? { widget.allowEmpty }
    var emptyLabel: String? { widget.emptyLabel }
    var disabled: Bool { definition.disabled ?? false }
    var platform: [String] { definition.platform ?? [] }
    var since: String? { definition.since }
    var schemaDescription: String? { definition.description }
    var repeatable: Bool { definition.repeatable ?? false }
}

struct SettingGroup: Identifiable {
    var id: String { groupId }
    let groupId: String
    let name: String
    let note: String?
    var preview: String? = nil
    var settings: [SettingItem]
}
struct SettingsPanel: Identifiable {
    var id: String { panelId }
    let panelId: String
    let name: String
    let note: String?
    var groups: [SettingGroup]
}
