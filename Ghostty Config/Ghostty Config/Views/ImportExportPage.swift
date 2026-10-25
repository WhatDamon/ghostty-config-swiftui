// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI
import UniformTypeIdentifiers

struct ImportExportPage: View {
    @Environment(\.configService) private var configService
    @Environment(\.toastService) private var toastService
    @State private var showFilePicker = false
    @State private var showImport = false
    @State private var importText = ""
    @State private var showShare = false
    @State private var showImportChanges = false
    @State private var importSource = "Text or share link"
    @State private var failure: String?

    private var exportedText: String { configService.stringifyConfig() }
    private var hasChanges: Bool { !configService.diff().isEmpty }

    var body: some View {
        PageView(title: "Import & Export") {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Config Preview") {
                    ScrollView([.vertical, .horizontal]) {
                        VStack(alignment: .leading) {
                        Text(hasChanges ? exportedText : "# No changes to the default config yet")
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .accessibilityIdentifier("config-preview")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 276, alignment: .topLeading)
                        .padding(12)
                    }
                    .frame(height: 300)
                    .background(Color(.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                GroupBox("Import") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review a config before merging it. Unchanged settings are kept, and repeated imports do not duplicate identical keybindings.")
                            .font(.callout).foregroundStyle(.secondary)
                        HStack {
                            Button("Paste from Clipboard") { pasteConfig() }
                            Button("Paste Text or Link…") { importText = ""; importSource = "Text or share link"; showImportChanges = false; showImport = true }
                            Button("Open File…") { showFilePicker = true }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(4)
                }
                GroupBox("Export") {
                    HStack {
                        Button("Copy to Clipboard") { copy(exportedText, message: "Config copied") }
                        Button("Save File…") { saveConfig() }
                        Button("Share…") { showShare = true }.buttonStyle(.borderedProminent)
                        Spacer()
                    }.disabled(!hasChanges).padding(4)
                }
            }
            .padding(20)
            .frame(maxWidth: 900)
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.plainText, .data]) { result in
            switch result {
            case .success(let url):
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                do { importText = try String(contentsOf: url, encoding: .utf8); importSource = url.lastPathComponent; showImportChanges = true; showImport = true }
                catch { failure = error.localizedDescription }
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError { failure = error.localizedDescription }
            }
        }
        .onChange(of: configService.pendingImportText, initial: true) { _, text in
            if let text { importText = text; importSource = "Shared config"; showImportChanges = true; showImport = true; configService.pendingImportText = nil }
        }
        .sheet(isPresented: $showImport) { importSheet }
        .sheet(isPresented: $showShare) { shareSheet }
        .alert("Could not complete the operation", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
            Button("OK") { failure = nil }
        } message: { Text(failure ?? "") }
    }

    private func decodedImport() -> Result<String, ShareServiceError> {
        let candidate = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !candidate.contains("\n"), let url = URL(string: candidate),
           ["http", "https", "ghosttyconfig"].contains(url.scheme ?? "") {
            return ShareService.extractConfigFromURL(url).flatMap(ShareService.decodeConfig)
        }
        return .success(importText)
    }

    private var importSheet: some View {
        let decoded = decodedImport()
        let text = (try? decoded.get()) ?? ""
        let parsed = ConfigParserService.inspect(text)
        let changes = configService.importChanges(parsed.values)
        return VStack(alignment: .leading, spacing: 16) {
            Text("Review Import").font(.title2.bold())
            Text("Paste configuration text or a Web share link. Import merges the valid entries below into your current config.")
                .foregroundStyle(.secondary)
            Text("Source: \(importSource)").font(.callout).foregroundStyle(.secondary)
            Picker("Review", selection: $showImportChanges) {
                Text("Original Text").tag(false)
                Text("Changes").tag(true)
            }.pickerStyle(.segmented)
            if showImportChanges {
                List {
                    if changes.isEmpty {
                        Text(parsed.entryCount == 0 ? "No valid config entries found." : "This import does not change any current values.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(changes) { change in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(change.key).font(.callout.monospaced()).fontWeight(.medium)
                                if change.overridesExisting { Text("Replaces current changes").font(.caption).foregroundStyle(.secondary) }
                            }
                            Text("Before: \(change.before)").lineLimit(2).foregroundStyle(.secondary)
                            Text("After: \(change.after)").lineLimit(3)
                        }
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                    }
                }
            } else {
                TextEditor(text: $importText)
                    .font(.body.monospaced())
                    .accessibilityLabel("Configuration to import")
                    .border(Color.secondary.opacity(0.2))
            }
            if case .failure(let error) = decoded { Text(error.localizedDescription).foregroundStyle(.red) }
            Text("\(parsed.entryCount) valid entries · \(changes.count) changed settings").font(.callout)
            if parsed.entryCount == 0 && !importText.isEmpty {
                Text("No valid config found. Review the text and diagnostics before importing.").font(.caption).foregroundStyle(.secondary)
            }
            if !parsed.diagnostics.isEmpty {
                ScrollView {
                    Text(parsed.diagnostics.joined(separator: "\n"))
                        .font(.caption).foregroundStyle(.orange)
                        .accessibilityIdentifier("import-diagnostics")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxHeight: 100)
            }
            HStack {
                Button("Cancel") { showImport = false }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Import Config") {
                    configService.load(parsed: parsed.values)
                    showImport = false
                    toastService.success("Imported \(parsed.entryCount) entries")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(parsed.entryCount == 0)
            }
        }
        .padding(24)
        .frame(width: 680, height: 580)
    }

    private var shareSheet: some View {
        let result = ShareService.buildShareUrl(encodedConfig: ShareService.encodeConfig(configService.serializeForShare()))
        return VStack(alignment: .leading, spacing: 16) {
            Text("Share Config").font(.title2.bold())
            switch result {
            case .success(let url):
                Text("This link opens your configuration in the Web editor. It can also be pasted into this app’s import dialog.")
                    .foregroundStyle(.secondary)
                Text(url.absoluteString).font(.callout.monospaced()).textSelection(.enabled)
                    .lineLimit(5)
                    .padding(12).background(Color(.textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                Button("Copy Link") { copy(url.absoluteString, message: "Share link copied") }
                    .buttonStyle(.borderedProminent)
            case .failure:
                Text("This config is too large to share as a link. Copy the text or save a file instead.")
                HStack {
                    Button("Copy Config Text") { copy(exportedText, message: "Config copied") }
                    Button("Save File…") { showShare = false; saveConfig() }
                }
            }
            HStack { Spacer(); Button("Close") { showShare = false }.keyboardShortcut(.cancelAction) }
        }
        .padding(24)
        .frame(width: 520)
    }

    private func pasteConfig() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            toastService.error("The clipboard contains no text")
            return
        }
        importText = text
        importSource = "Clipboard"
        showImportChanges = true
        showImport = true
    }

    private func copy(_ text: String, message: String) {
        NSPasteboard.general.clearContents()
        if NSPasteboard.general.setString(text, forType: .string) { toastService.success(message) }
        else { toastService.error("Could not copy to clipboard") }
    }

    private func saveConfig() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "config"
        panel.canCreateDirectories = true
        let snapshot = exportedText
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try snapshot.write(to: url, atomically: true, encoding: .utf8)
                toastService.success("Config saved")
            } catch { failure = error.localizedDescription }
        }
    }
}
