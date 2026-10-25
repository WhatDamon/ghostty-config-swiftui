// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

struct KeybindSettingView: View {
    let configKey: ConfigKey
    @Environment(\.configService) private var configService
    @State private var editor: EditorSelection?
    @State private var filter = ""
    @State private var confirmReset = false

    private struct EditorSelection: Identifiable {
        let id = UUID()
        let index: Int?
        let value: String
    }

    private var bindings: [String] { configService.array(for: configKey) }

    var body: some View {
        let diagnostics = getDiagnostics(bindings)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Filter keybindings", text: $filter)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Filter keybindings")
                Button { editor = EditorSelection(index: nil, value: "") } label: {
                    Label("Add", systemImage: "plus")
                }
                Button("Reset Defaults") { confirmReset = true }
                    .disabled(!configService.isNonDefault(configKey))
            }
            Text("\(bindings.count) keybindings · Changes override Ghostty’s defaults.")
                .font(.caption).foregroundStyle(.secondary)
            LazyVStack(spacing: 0) {
                ForEach(Array(bindings.enumerated()), id: \.offset) { index, binding in
                    if filter.isEmpty || binding.localizedCaseInsensitiveContains(filter) {
                        row(binding, index: index, diagnostic: diagnostics[index])
                        Divider()
                    }
                }
            }
            if bindings.isEmpty { Text("No keybindings. Add one to get started.").foregroundStyle(.secondary) }
        }
        .sheet(item: $editor) { selection in
            KeybindEditorSheet(initialValue: selection.value, onSave: { result in
                var updated = bindings
                if let index = selection.index, updated.indices.contains(index) { updated[index] = result }
                else { updated.append(result) }
                configService.set(updated, for: configKey)
                editor = nil
                filter = ""
            }, onCancel: { editor = nil })
        }
        .confirmationDialog("Reset all keybindings to their defaults?", isPresented: $confirmReset) {
            Button("Reset Keybindings", role: .destructive) { configService.resetSetting(configKey) }
        }
    }

    private func row(_ binding: String, index: Int, diagnostic: (status: String, duplicate: Bool, errors: [String], canonical: String)) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: diagnostic.status == "invalid" ? "exclamationmark.triangle" : diagnostic.duplicate ? "exclamationmark.circle" : "keyboard")
                .foregroundStyle(diagnostic.status == "invalid" ? Color.red : diagnostic.duplicate ? Color.orange : Color.secondary)
                .help((diagnostic.errors + (diagnostic.duplicate ? ["This trigger has multiple bindings; check that chained actions are intentional."] : [])).joined(separator: "\n"))
            Text(binding)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Button { editor = EditorSelection(index: index, value: binding) } label: { Image(systemName: "pencil") }
                .accessibilityLabel("Edit \(binding)")
            Button {
                var updated = bindings
                updated.remove(at: index)
                configService.set(updated, for: configKey)
            } label: { Image(systemName: "minus.circle") }
                .accessibilityLabel("Remove \(binding)")
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 10)
    }
}
