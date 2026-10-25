// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

/// A draft is committed only on Return or focus loss. Invalid intermediate input
/// remains visible and never overwrites the last valid config value.
struct ValidatedSettingField: View {
    let setting: SettingItem
    var placeholder = "Default"
    @Environment(\.configService) private var configService
    @State private var draft = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: $draft)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .accessibilityLabel(setting.configKey.rawValue)
                .onSubmit { commit() }
                .onChange(of: focused) { _, value in if !value { commit() } }
                .onChange(of: configService.string(for: setting.configKey), initial: true) { _, raw in draft = raw; error = nil }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }
    }
    private func commit() {
        guard draft != configService.string(for: setting.configKey) else { return }
        let raw = draft.trimmingCharacters(in: .whitespaces)
        if let issue = SettingCodecs.validationError(raw, setting: setting) { error = issue; return }
        if setting.type == .duration, raw.isEmpty, !setting.defaultValue.text.isEmpty {
            configService.resetSetting(setting.configKey)
        } else { configService.setString(raw, for: setting.configKey) }
        error = nil
    }
}

struct RepeatableSettingView: View {
    let setting: SettingItem
    @Environment(\.configService) private var configService
    @State private var editing = false
    var body: some View {
        HStack {
            let values = configService.array(for: setting.configKey)
            Text(values.isEmpty ? "Default" : "\(values.count) entries")
                .foregroundStyle(.secondary)
            Button("Edit…") { editing = true }.accessibilityLabel("Edit \(setting.name)")
        }
        .sheet(isPresented: $editing) {
            RepeatableEditor(title: setting.name, values: configService.array(for: setting.configKey), canReorder: setting.widget.canReorder ?? true) { values in
                configService.set(values, for: setting.configKey)
                editing = false
            }
        }
    }
}

private struct RepeatableEditor: View {
    let title: String
    let values: [String]
    let canReorder: Bool
    let onSave: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var rows: [Row] = []
    private struct Row: Identifiable { let id = UUID(); var text: String }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2)
            Text("Each row is a separate config entry. An empty row explicitly resets earlier entries; remove all rows to follow the default.")
                .font(.callout).foregroundStyle(.secondary)
            List {
                ForEach($rows) { $row in
                    HStack {
                        TextField("Value (empty = reset)", text: $row.text)
                            .accessibilityLabel("Entry value")
                        if canReorder {
                            Button { move(row.id, by: -1) } label: { Image(systemName: "arrow.up") }
                                .disabled(rows.first?.id == row.id).accessibilityLabel("Move entry up")
                            Button { move(row.id, by: 1) } label: { Image(systemName: "arrow.down") }
                                .disabled(rows.last?.id == row.id).accessibilityLabel("Move entry down")
                        }
                        Button { rows.removeAll { $0.id == row.id } } label: { Image(systemName: "minus.circle") }
                            .accessibilityLabel("Remove entry")
                    }
                }
                .onMove { indices, destination in if canReorder { rows.move(fromOffsets: indices, toOffset: destination) } }
            }
            HStack {
                Button("Add Entry") { rows.append(Row(text: "")) }
                Button("Remove All") { rows = [] }.disabled(rows.isEmpty)
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") { onSave(rows.map(\.text)) }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20).frame(width: 620, height: 430)
        .onAppear { rows = values.map { Row(text: $0) } }
    }
    private func move(_ id: UUID, by delta: Int) {
        guard let index = rows.firstIndex(where: { $0.id == id }), rows.indices.contains(index + delta) else { return }
        rows.swapAt(index, index + delta)
    }
}

struct FeatureSettingView: View {
    let setting: SettingItem
    @Environment(\.configService) private var configService
    @State private var editing = false
    var body: some View {
        Button("Configure…") { editing = true }
            .accessibilityLabel("Configure \(setting.name)")
            .sheet(isPresented: $editing) {
                FeatureEditor(setting: setting, value: configService.string(for: setting.configKey)) { raw in
                    configService.setString(raw, for: setting.configKey)
                    editing = false
                }
            }
    }
}

private struct FeatureEditor: View {
    let setting: SettingItem
    let value: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var raw = ""
    var body: some View {
        let features = setting.widget.features ?? []
        VStack(alignment: .leading, spacing: 16) {
            Text(setting.name).font(.title2)
            Text(raw.isEmpty ? "Following Ghostty’s defaults" : "Custom feature selection")
                .foregroundStyle(.secondary)
            Form {
                ForEach(features) { feature in
                    Toggle(feature.label, isOn: Binding(
                        get: { SettingCodecs.features(raw, definitions: features)[feature.id] ?? feature.default },
                        set: { enabled in raw = SettingCodecs.settingFeature(feature.id, enabled: enabled, raw: raw, definitions: features) }
                    ))
                    .help(feature.description ?? "Default: \(feature.default ? "on" : "off")")
                }
            }
            TextField("Raw value (unknown features are preserved)", text: $raw)
                .textFieldStyle(.roundedBorder).accessibilityLabel("Raw feature value")
            HStack {
                Button("Use Defaults") { raw = "" }
                Button("All On") { setAll(true) }
                Button("All Off") { setAll(false) }
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") { onSave(raw) }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(24).frame(width: 570)
        .onAppear { raw = value }
    }

    private func setAll(_ enabled: Bool) {
        let definitions = setting.widget.features ?? []
        for feature in definitions {
            raw = SettingCodecs.settingFeature(feature.id, enabled: enabled, raw: raw, definitions: definitions)
        }
    }
}

struct PairSettingView: View {
    let setting: SettingItem
    @Environment(\.configService) private var configService
    @State private var pair = SettingCodecs.Pair(first: "", second: "", linked: true)
    @State private var error: String?
    @FocusState private var focused: Bool
    private var isScroll: Bool { setting.type == .scrollMultiplier }
    private var labels: [String] { isScroll ? ["Precision", "Discrete"] : setting.widget.labels ?? ["First", "Second"] }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading) {
                    Text(labels[0]).font(.caption)
                    TextField("Value", text: $pair.first).textFieldStyle(.roundedBorder).focused($focused)
                        .accessibilityLabel("\(setting.configKey.rawValue) \(labels[0])")
                }
                if !pair.linked {
                    VStack(alignment: .leading) {
                        Text(labels[1]).font(.caption)
                        TextField("Value", text: $pair.second).textFieldStyle(.roundedBorder).focused($focused)
                            .accessibilityLabel("\(setting.configKey.rawValue) \(labels[1])")
                    }
                }
                Toggle("Link", isOn: Binding(get: { pair.linked }, set: { linked in
                    if linked { pair.second = pair.first }
                    pair.linked = linked
                    commit()
                })).toggleStyle(.checkbox)
            }
            .onSubmit { commit() }
            .onChange(of: focused) { _, value in if !value { commit() } }
            .onChange(of: configService.string(for: setting.configKey), initial: true) { _, raw in
                pair = isScroll ? SettingCodecs.scrollPair(raw) : SettingCodecs.pair(raw); error = nil
            }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }
    }
    private func commit() {
        if pair.linked { pair.second = pair.first }
        let raw = isScroll ? SettingCodecs.scrollString(pair) : pair.raw
        if let issue = SettingCodecs.validationError(raw, setting: setting) { error = issue; return }
        if raw != configService.string(for: setting.configKey) { configService.setString(raw, for: setting.configKey) }
        error = nil
    }
}

struct MetricSettingView: View {
    let setting: SettingItem
    @Environment(\.configService) private var configService
    @State private var number = ""
    @State private var percent = false
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Default", text: $number).textFieldStyle(.roundedBorder).focused($focused)
                    .accessibilityLabel(setting.configKey.rawValue)
                    .onSubmit { commit() }
                    .onChange(of: focused) { _, value in if !value { commit() } }
                Picker("Unit", selection: Binding(get: { percent }, set: { value in percent = value; commit() })) {
                    Text("px").tag(false); Text("%").tag(true)
                }
                    .labelsHidden().frame(width: 70)
            }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .onChange(of: configService.string(for: setting.configKey), initial: true) { _, raw in
            percent = raw.hasSuffix("%")
            number = percent ? String(raw.dropLast()) : raw
            error = nil
        }
    }
    private func commit() {
        let raw = number.isEmpty ? "" : number + (percent ? "%" : "")
        if let issue = SettingCodecs.validationError(raw, setting: setting) { error = issue; return }
        if raw != configService.string(for: setting.configKey) { configService.setString(raw, for: setting.configKey) }
        error = nil
    }
}

struct CustomValueSettingView: View {
    let setting: SettingItem
    @Environment(\.configService) private var configService
    @State private var customDraft = ""
    private var presets: [DropdownOption] { setting.widget.presets ?? [] }
    private var mode: String {
        if ConfigService.schemeKeys.contains(setting.configKey), !configService.explicitColors.contains(setting.configKey) { return "__default" }
        let raw = configService.effectiveString(for: setting.configKey)
        if raw.isEmpty { return "__default" }
        return presets.contains(where: { $0.value == raw }) ? raw : "__custom"
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Picker("Value mode", selection: Binding(get: { mode }, set: { selected in
                let raw = configService.effectiveString(for: setting.configKey)
                if mode == "__custom" { customDraft = raw }
                if selected == "__default" { configService.resetSetting(setting.configKey) }
                else if selected == "__custom" {
                    let seed = setting.type == .customColor ? (configService.resolvedColor(for: setting.configKey).nilIfEmpty ?? configService.resolvedColor(for: .foreground)) : "0"
                    configService.setString(customDraft.isEmpty ? seed : customDraft, for: setting.configKey)
                } else { configService.setString(selected, for: setting.configKey) }
            })) {
                Text(ConfigService.schemeKeys.contains(setting.configKey) && configService.activeThemeName != nil ? "Follow Theme" : "Default").tag("__default")
                Text("Custom").tag("__custom")
                ForEach(presets) { Text($0.name).tag($0.value) }
            }
            .labelsHidden().accessibilityLabel("\(setting.configKey.rawValue) mode")
            if mode == "__default", setting.type == .customColor {
                HStack {
                    Spacer()
                    Text(configService.resolvedColor(for: setting.configKey)).font(.caption.monospaced()).foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ColorValue(hex: configService.resolvedColor(for: setting.configKey))?.nsColor ?? .gray)
                        .frame(width: 22, height: 14)
                }
            }
            if mode == "__custom" {
                if setting.type == .customColor { ColorSettingView(configKey: setting.configKey) }
                else { ValidatedSettingField(setting: setting, placeholder: "Blur radius") }
            }
        }
    }
}
