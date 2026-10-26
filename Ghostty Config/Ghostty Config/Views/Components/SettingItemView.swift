// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

struct SettingItemView: View {
    let setting: SettingItem
    @Environment(\.configService) private var configService
    @Environment(\.localConfigService) private var local
    @State private var showHelp = false

    private var isExpanded: Bool { setting.type == .palette || setting.type == .keybinds }
    private var canReset: Bool {
        configService.isNonDefault(setting.configKey) || (local.isConnected && configService.explicitKeys.contains(setting.configKey.camelCase))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isExpanded {
                heading
                controlView
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 16) {
                        heading.frame(minWidth: 160, maxWidth: .infinity, alignment: .leading)
                        controlView.frame(width: controlWidth, alignment: .trailing)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        heading
                        controlView.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            if ConfigService.schemeKeys.contains(setting.configKey) {
                switch configService.colorSource(for: setting.configKey) {
                case .theme(let name): Text("Following \(name)").font(.caption).foregroundStyle(.secondary)
                case .override: Text("Custom color override").font(.caption).foregroundStyle(.secondary)
                case .default: EmptyView()
                }
            }
            if let note = setting.note, !note.isEmpty {
                Text(HTMLStripper.strip(note))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .contextMenu {
            if canReset {
                Button("Follow theme or default") { configService.resetSetting(setting.configKey) }
            }
        }
        .popover(isPresented: $showHelp) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(setting.name).font(.headline)
                    Text(setting.configKey.rawValue).font(.callout.monospaced()).foregroundStyle(.secondary)
                    Text(.init(setting.schemaDescription ?? setting.note ?? ""))
                        .textSelection(.enabled)
                    Link("Ghostty documentation", destination: URL(string: "https://ghostty.org/docs/config/reference#\(setting.configKey.rawValue)")!)
                }
                .padding(20)
            }
            .frame(width: 440, height: 360)
        }
    }

    private var heading: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(setting.name).fontWeight(.medium).fixedSize(horizontal: false, vertical: true)
                if !setting.platform.isEmpty || setting.since != nil {
                    HStack(spacing: 6) {
                        ForEach(setting.platform, id: \.self) { platform in
                            Text(platform == "macos" ? "macOS" : platform.uppercased())
                        }
                        if let since = setting.since { Text("v\(since)+") }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            if canReset {
                Button { configService.resetSetting(setting.configKey) } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                .help(ConfigService.schemeKeys.contains(setting.configKey) ? "Follow theme or default" : "Reset \(setting.name) to default")
                .accessibilityLabel("Reset \(setting.name)")
            }
            if setting.schemaDescription != nil {
                Button { showHelp = true } label: { Image(systemName: "info.circle") }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Full description")
                    .accessibilityLabel("About \(setting.name)")
            }
        }
    }

    private var controlWidth: CGFloat {
        switch setting.type {
        case .switch: 50
        case .number: 140
        case .color: 225
        default: 240
        }
    }

    @ViewBuilder private var controlView: some View {
        Group {
            switch setting.type {
            case .switch: SwitchSettingView(configKey: setting.configKey)
            case .text: TextSettingView(configKey: setting.configKey, placeholder: setting.placeholder)
            case .number:
                NumberSettingView(configKey: setting.configKey, minValue: setting.minValue, maxValue: setting.maxValue, step: setting.step ?? 1)
            case .range:
                RangeSettingView(configKey: setting.configKey, minValue: setting.minValue ?? 0, maxValue: setting.maxValue ?? 1, step: setting.step ?? 1, showLabels: setting.showLabels ?? true)
            case .dropdown, .pill:
                DropdownSettingView(configKey: setting.configKey, options: setting.options ?? [], allowEmpty: setting.allowEmpty ?? false, emptyLabel: setting.emptyLabel ?? "Default")
            case .color: ColorSettingView(configKey: setting.configKey)
            case .palette: PaletteSettingView(configKey: setting.configKey)
            case .keybinds: KeybindSettingView(configKey: setting.configKey)
            case .theme: ThemeSettingView(configKey: setting.configKey)
            case .repeatableText: RepeatableSettingView(setting: setting)
            case .featureList: FeatureSettingView(setting: setting)
            case .duration: ValidatedSettingField(setting: setting, placeholder: "e.g. 1h30m or 750ms")
            case .dualNumber, .scrollMultiplier: PairSettingView(setting: setting)
            case .numberUnits: MetricSettingView(setting: setting)
            case .customColor, .customNumber: CustomValueSettingView(setting: setting)
            }
        }
        .disabled(setting.disabled)
    }
}
