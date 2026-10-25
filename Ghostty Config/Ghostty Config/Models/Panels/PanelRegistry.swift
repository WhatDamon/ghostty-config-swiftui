// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

/// The reviewed registry snapshot is bundled with the app. No network or runtime
/// JavaScript is needed to construct controls, defaults or theme options.
enum PanelRegistry {
    struct Snapshot: Decodable {
        let source: Source
        let registry: [String: SettingDefinition]
        let navigation: [Panel]
        let themes: [String: ThemeColors]
    }
    struct Source: Decodable { let repository: String; let revision: String; let platform: String }
    struct Panel: Decodable { let id: String; let name: String; let note: String?; let groups: [Group] }
    struct Group: Decodable { let id: String; let name: String; let note: String?; let preview: String?; let settings: [String] }

    static let snapshot: Snapshot = {
        guard let url = Bundle.main.url(forResource: "UpstreamSettings", withExtension: "json") else {
            preconditionFailure("Missing bundled UpstreamSettings.json")
        }
        do { return try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: url)) }
        catch { preconditionFailure("Invalid bundled settings: \(error)") }
    }()

    static let definitions: [ConfigKey: SettingItem] = Dictionary(uniqueKeysWithValues: snapshot.registry.map { id, definition in
        let key = ConfigKey(rawValue: definition.key)
        precondition(key != .unknown && key.camelCase == id, "Unknown registry key \(definition.key)")
        return (key, SettingItem(configKey: key, definition: definition))
    })

    static let all: [SettingsPanel] = snapshot.navigation.map { panel in
        SettingsPanel(panelId: panel.id, name: panel.name, note: panel.note, groups: panel.groups.map { group in
            SettingGroup(groupId: group.id, name: group.name, note: group.note, preview: group.preview,
                         settings: group.settings.map { id in
                guard let definition = snapshot.registry[id], let item = definitions[ConfigKey(rawValue: definition.key)] else {
                    preconditionFailure("Missing navigation definition \(id)")
                }
                return item
            })
        })
    }

    static let settings: [ConfigKey: SettingItem] = Dictionary(uniqueKeysWithValues: all.flatMap(\.groups).flatMap(\.settings).map { ($0.configKey, $0) })
}
