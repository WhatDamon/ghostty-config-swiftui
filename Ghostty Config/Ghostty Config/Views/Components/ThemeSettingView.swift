// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

struct ThemeSettingView: View {
    let configKey: ConfigKey
    @Environment(\.configService) private var configService
    @State private var showEditor = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button {
                showEditor = true
            } label: {
                Text(configService.string(for: configKey).nilIfEmpty ?? "Choose a theme…")
                    .lineLimit(2)
            }
            .accessibilityLabel("Color theme")
            if case .dual = configService.themeSelection {
                Picker("Preview", selection: Binding(get: { configService.previewMode }, set: { configService.previewMode = $0 })) {
                    Text("System").tag(PreviewMode.system)
                    Text("Light").tag(PreviewMode.light)
                    Text("Dark").tag(PreviewMode.dark)
                }
                .pickerStyle(.segmented)
                .help("Changes the preview only; it does not change your configuration.")
            }
            if let name = configService.selectedThemeName, configService.activeThemeName == nil {
                Text("Custom theme: colors cannot be previewed.").font(.caption).foregroundStyle(.secondary)
                    .help(name)
            }
        }
        .sheet(isPresented: $showEditor) { ThemeEditor(selection: configService.themeSelection) { selection in
            configService.setString(selection.raw, for: configKey)
            showEditor = false
        } }
    }
}

private struct ThemeEditor: View {
    let selection: ThemeSelection
    let onSave: (ThemeSelection) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var dual = false
    @State private var light = ""
    @State private var dark = ""
    @State private var choosing: ThemeSide?
    private enum ThemeSide: String, Identifiable { case light, dark; var id: String { rawValue } }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Color Theme").font(.title2)
            Text("\(PanelRegistry.snapshot.themes.count) reviewed MIT themes are available offline. Other themes are not bundled or downloaded; enter a name or path from your own Ghostty installation.")
                .foregroundStyle(.secondary)
            Form {
                Toggle("Use separate light and dark themes", isOn: $dual)
                themeRow(dual ? "Light" : "Theme", text: $light, side: .light)
                if dual { themeRow("Dark", text: $dark, side: .dark) }
            }
            if dual && (light.isEmpty || dark.isEmpty) {
                Text("Choose both light and dark themes before saving.").font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Button("Reset Theme") { onSave(.unset) }
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Apply") {
                    let first = light.trimmingCharacters(in: .whitespacesAndNewlines)
                    let second = dark.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSave(dual ? .dual(light: first, dark: second) : first.isEmpty ? .unset : .single(first))
                }
                .keyboardShortcut(.defaultAction)
                .disabled(dual && (light.trimmingCharacters(in: .whitespaces).isEmpty || dark.trimmingCharacters(in: .whitespaces).isEmpty))
            }
        }
        .padding(24)
        .frame(width: 560)
        .onAppear {
            switch selection {
            case .unset: break
            case .single(let name): light = name; dark = name
            case .dual(let first, let second): dual = true; light = first; dark = second
            }
        }
        .sheet(item: $choosing) { side in
            ThemeChooser { name in
                if side == .light { light = name } else { dark = name }
                choosing = nil
            }
        }
    }

    private func themeRow(_ title: String, text: Binding<String>, side: ThemeSide) -> some View {
        HStack {
            TextField(title, text: text).textFieldStyle(.roundedBorder).accessibilityLabel("\(title) theme name")
            Button("Choose…") { choosing = side }.accessibilityLabel("Choose \(title) theme")
        }
    }
}

private struct ThemeChooser: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    private let names = PanelRegistry.snapshot.themes.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    var body: some View {
        NavigationStack {
            List {
                ForEach(names.filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }, id: \.self) { name in
                    Button { onSelect(name) } label: {
                        HStack {
                            if let theme = PanelRegistry.snapshot.themes[name] {
                                RoundedRectangle(cornerRadius: 2).fill(ColorValue(hex: theme.background ?? "#000000")?.nsColor ?? .black)
                                    .frame(width: 24, height: 16)
                                    .overlay(Text("Aa").font(.system(size: 9)).foregroundStyle(ColorValue(hex: theme.foreground ?? "#FFFFFF")?.nsColor ?? .white))
                            }
                            Text(name)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain)
                }
            }
            .searchable(text: $query, prompt: "Search themes")
            .navigationTitle("Choose Theme")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .frame(width: 440, height: 500)
    }
}
