// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Keybind Editor Sheet

struct KeybindEditorSheet: View {
    let initialValue: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var prefixes: Set<String> = []
    @State private var steps: [EditorStep] = [EditorStep(key: "a", modifiers: [])]
    @State private var actionName: String = ""
    @State private var actionArg: String = ""
    @State private var resizeDirection: String = "right"
    @State private var resizeAmount: String = ""
    private var validationErrors: [String] { parseKeybind(computedFull).errors }

    private static let validPrefixes = ["all", "global", "unconsumed", "performable"]

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(initialValue.isEmpty ? "Add Keybind" : "Edit Keybind")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    prefixesSection
                    triggerSection
                    actionSection
                    resultSection
                }
                .padding()
            }

            Divider()

            // Bottom bar
            HStack {
                if let firstError = validationErrors.first {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(firstError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape)
                Button("Save", action: saveAction)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                    .disabled(!validationErrors.isEmpty)
            }
            .padding()
        }
        .frame(width: 560, height: 600)
        .onAppear { loadFromInitial() }
        .onChange(of: actionName) { old, new in
            if !old.isEmpty && old != new { actionArg = ""; resizeAmount = "" }
        }
    }

    // MARK: - Load

    private func loadFromInitial() {
        guard !initialValue.isEmpty else { return }
        let parsed = parseKeybind(initialValue)
        prefixes = Set(parsed.trigger?.prefixes ?? [])
        if let steps = parsed.trigger?.steps, !steps.isEmpty {
            self.steps = steps.map { EditorStep(key: $0.key, modifiers: Set($0.modifiers)) }
        }
        actionName = parsed.action ?? ""
        actionArg = parsed.args ?? ""
        if let args = parsed.args, actionName == "resize_split" {
            let parts = args.split(separator: ",", maxSplits: 1).map(String.init)
            if parts.count >= 1 { resizeDirection = parts[0] }
            if parts.count >= 2 { resizeAmount = parts[1] }
        }
    }

    // MARK: - Prefixes

    private var prefixesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Prefixes")
            HStack(spacing: 12) {
                ForEach(Self.validPrefixes, id: \.self) { prefix in
                    Toggle(isOn: Binding(
                        get: { prefixes.contains(prefix) },
                        set: { enabled in
                            if enabled {
                                prefixes.insert(prefix)
                                if prefix == "all" || prefix == "global" { steps = Array(steps.prefix(1)) }
                            } else { prefixes.remove(prefix) }
                        }
                    )) {
                        Text(prefix)
                            .font(.caption)
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
    }

    // MARK: - Trigger

    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Trigger")

            ForEach(steps.indices, id: \.self) { index in
                stepView(at: index)

                if index < steps.count - 1 {
                    HStack {
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.leading, 20)
                }
            }

            if steps.count < 4 && !prefixes.contains("global") && !prefixes.contains("all") {
                Button {
                    steps.append(EditorStep(key: "", modifiers: []))
                } label: {
                    Label("Add Sequence Step", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
    }

    private func stepView(at index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                if steps.count > 1 {
                    Button { steps.remove(at: index) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField("key", text: $steps[index].key)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 120)
                    .accessibilityLabel("Key \(index + 1)")

                HStack(spacing: 8) {
                    ForEach(["ctrl", "alt", "super", "shift"], id: \.self) { mod in
                        Toggle(isOn: Binding(
                            get: { steps[index].modifiers.contains(mod) },
                            set: { enabled in
                                if enabled { steps[index].modifiers.insert(mod) }
                                else { steps[index].modifiers.remove(mod) }
                            }
                        )) {
                            Text(mod)
                                .font(.caption2)
                        }
                        .toggleStyle(.checkbox)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.textBackgroundColor).opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Action

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Action")

            Picker("Action", selection: $actionName) {
                Text("Select action…").tag("")
                ForEach(actionDefinitions, id: \.name) { def in
                    HStack {
                        Text(def.name)
                        if let desc = def.description {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(def.name)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)

            if let currentAction = actionLookup[actionName], currentAction.type != .none {
                Divider()
                argumentView(for: currentAction)
            }
        }
    }

    @ViewBuilder
    private func argumentView(for action: ActionDefinition) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Argument")
                .font(.caption)
                .foregroundStyle(.secondary)

            switch action.type {
            case .enum:
                let allOptions = (action.allowEmpty ? [""] : []) + (action.options ?? [])
                Picker("", selection: $actionArg) {
                    ForEach(allOptions, id: \.self) { opt in
                        Text(opt.isEmpty ? "default" : opt).tag(opt)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

            case .number, .integer, .unsignedInteger:
                TextField("value", text: $actionArg)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 100)
                    .accessibilityLabel("Argument value")

            case .resize:
                HStack(spacing: 8) {
                    Picker("Direction", selection: $resizeDirection) {
                        ForEach(["up", "down", "left", "right"], id: \.self) { dir in
                            Text(dir).tag(dir)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()

                    TextField("pixels", text: $resizeAmount)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))
                        .frame(width: 60)
                }

            case .text, .free:
                TextField(action.type == .text ? "Zig string literal" : "raw sequence", text: $actionArg)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))

            case .direction, .none:
                EmptyView()
            }
        }
    }

    // MARK: - Result

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Preview")

            HStack(spacing: 0) {
                Text(computedTrigger)
                    .foregroundStyle(.blue)
                Text(" = ")
                Text(computedActionWithArg)
                    .foregroundStyle(.green)
            }
            .font(.system(.caption, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.textBackgroundColor).opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if !validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(validationErrors, id: \.self) { error in
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    // MARK: - Computed

    private var computedTrigger: String {
        formatTrigger(ParsedTrigger(prefixes: Array(prefixes), steps: steps.map {
            ParsedTriggerStep(key: $0.key, modifiers: Array($0.modifiers))
        }))
    }

    private var computedActionWithArg: String {
        guard let definition = actionLookup[actionName] else { return actionName }
        if definition.type == .none { return actionName }
        if definition.type == .resize { return "\(actionName):\(resizeDirection),\(resizeAmount)" }
        if actionArg.isEmpty && definition.allowEmpty { return actionName }
        return "\(actionName):\(actionArg)"
    }

    private var computedFull: String { "\(computedTrigger)=\(computedActionWithArg)" }

    private func saveAction() {
        guard validationErrors.isEmpty else { return }
        let result = computedFull
        onSave(result)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
    }
}

// MARK: - Editor Step

struct EditorStep {
    var key: String
    var modifiers: Set<String>
}
