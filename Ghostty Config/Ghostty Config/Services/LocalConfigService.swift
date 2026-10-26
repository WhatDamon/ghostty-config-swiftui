// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class LocalConfigService {
    nonisolated deinit {}
    typealias Backup = LocalConfigStore.Backup

    private(set) var folderURL: URL?
    private(set) var fileURL: URL?
    private(set) var availableFiles: [URL] = []
    private(set) var backups: [Backup] = []
    private(set) var document: ConfigFileDocument?
    private(set) var snapshot: LocalConfigStore.Snapshot?
    private(set) var baseline: ConfigService.ConfigState?
    private(set) var lastSaved: Date?
    private(set) var statusMessage: String?
    var errorMessage: String?
    var conflictMessage: String?
    var bookmarkNeedsRenewal = false
    var reviewText: String?
    var reviewOriginalText: String?
    var reviewTitle = "Configuration"

    private weak var config: ConfigService?
    private let preferences: UserDefaults
    let store: LocalConfigStore
    private let bookmarkKey = "localConfig.folderBookmark"
    private let filenameKey = "localConfig.filename"
    private var resumed = false
    private var discardPromptPresented = false

    init(backupRoot: URL? = nil, preferences: UserDefaults = .standard) {
        self.preferences = preferences
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        store = LocalConfigStore(backupRoot: backupRoot ?? support.appendingPathComponent("Ghostty Config/Backups", isDirectory: true))
    }

    var isConnected: Bool { fileURL != nil && snapshot != nil }
    var hasUnsavedChanges: Bool {
        guard let config, let baseline else { return false }
        return !Self.changes(from: baseline, to: config.snapshot()).isEmpty
    }
    var changedSettingCount: Int {
        guard let config, let baseline else { return 0 }
        return Self.changes(from: baseline, to: config.snapshot()).count
    }
    var diagnostics: [String] { document?.parsed.diagnostics ?? [] }
    var includesOtherFiles: Bool { document?.lines.contains { $0.entry?.key == "config-file" } ?? false }
    var backupDirectory: URL? { fileURL.map { store.backupDirectory(for: $0) } }

    func attach(_ config: ConfigService) {
        self.config = config
        guard !resumed else { return }
        resumed = true
        // Remember the location, but load explicitly so a restored connection
        // cannot silently replace a draft from the standalone editor.
        guard let bookmark = preferences.data(forKey: bookmarkKey) else { return }
        do {
            var stale = false
            folderURL = try URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale)
            try withAccess {
                if stale { try persistBookmark() }
                try refreshFiles()
            }
            bookmarkNeedsRenewal = false
            statusMessage = "Folder access restored. Choose a file and load it to edit."
        } catch {
            bookmarkNeedsRenewal = true
            statusMessage = "Folder access expired or is unavailable. Choose the folder again."
        }
    }

    func chooseFolder() {
        withDiscardConfirmation { [weak self] in self?.chooseFolderUnchecked() }
    }

    private func chooseFolderUnchecked() {
        let panel = NSOpenPanel()
        panel.title = "Authorize Ghostty Configuration Folder"
        panel.message = "Choose only the Ghostty configuration folder (for example ~/.config/ghostty or ~/Library/Application Support/com.mitchellh.ghostty). Access is remembered for future launches."
        panel.prompt = "Authorize Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.showsHiddenFiles = true
        panel.directoryURL = folderURL
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let oldFolder = folderURL
            folderURL = url
            do { try withAccess { try refreshFiles(); try persistBookmark() } }
            catch { folderURL = oldFolder; throw error }
            clearSession()
            bookmarkNeedsRenewal = false
            statusMessage = "Folder authorized. Load the configuration file you want to edit."
        } catch { errorMessage = error.localizedDescription }
    }

    /// Available for the file panel and isolated tests; all reads/writes still
    /// validate that the selected file resolves inside the authorized directory.
    func connect(folder: URL, file: URL, config: ConfigService) throws {
        self.config = config
        let candidate = try store.read(file, authorizedFolder: folder)
        let document = try ConfigFileDocument(data: candidate.data)
        folderURL = folder
        apply(candidate, document: document)
        try refreshFiles()
    }

    func loadFile(_ url: URL) {
        withDiscardConfirmation { [weak self] in
            self?.withDraftReplacementConfirmation {
                guard let self else { return }
                do { try self.withAccess { try self.loadUnchecked(url) } }
                catch { self.errorMessage = error.localizedDescription }
            }
        }
    }

    func chooseOtherFile() {
        guard folderURL != nil else { return }
        withDiscardConfirmation { [weak self] in self?.chooseOtherFileUnchecked() }
    }

    private func chooseOtherFileUnchecked() {
        let panel = NSOpenPanel()
        panel.title = "Choose Configuration File"
        panel.message = "Select a file inside the authorized folder. To edit a file elsewhere, authorize its folder first."
        panel.directoryURL = folderURL
        panel.showsHiddenFiles = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadFile(url)
    }

    func reload() {
        guard let fileURL else { return }
        loadFile(fileURL)
    }

    @discardableResult
    func save() -> Bool {
        guard let config, let baseline, let document, let snapshot else { return false }
        do {
            let changes = Self.changes(from: baseline, to: config.snapshot())
            let data = try document.replacing(changes: changes)
            // Parse before writing; failure cannot leave a partial editor state.
            let nextDocument = try ConfigFileDocument(data: data)
            let next = try withAccess { try store.write(data, replacing: snapshot, authorizedFolder: try folder(), reason: "Before save") }
            apply(next, document: nextDocument)
            lastSaved = Date()
            statusMessage = changes.isEmpty ? "No changes to save." : "Configuration saved. Reload Ghostty with ⌘⇧, (its default shortcut) to apply changes."
            return true
        } catch LocalConfigError.conflict {
            conflictMessage = LocalConfigError.conflict.localizedDescription
        } catch { errorMessage = error.localizedDescription }
        refreshBackups()
        return false
    }

    func backupNow() {
        guard let fileURL else { return }
        do {
            // Back up disk contents, including changes from other editors.
            let current = try withAccess { try store.read(fileURL, authorizedFolder: try folder()) }
            _ = try store.backup(current, reason: "Manual backup")
            statusMessage = "Current disk contents backed up."
            refreshBackups()
        } catch { errorMessage = error.localizedDescription }
    }

    func restore(_ backup: Backup) {
        withDiscardConfirmation { [weak self] in self?.restoreUnchecked(backup) }
    }

    private func restoreUnchecked(_ backup: Backup) {
        guard let snapshot, let fileURL else { return }
        do {
            let data = try store.backupData(backup, for: fileURL)
            let document = try ConfigFileDocument(data: data)
            let next = try withAccess { try store.write(data, replacing: snapshot, authorizedFolder: try folder(), reason: "Before restore", restoreAbsence: !backup.existed, permissions: backup.permissions) }
            apply(next, document: document)
            statusMessage = "Backup restored. The previous disk contents were backed up first. Reload Ghostty to apply changes."
        } catch LocalConfigError.conflict {
            conflictMessage = LocalConfigError.conflict.localizedDescription
        } catch { errorMessage = error.localizedDescription }
        refreshBackups()
    }

    func showChanges() {
        guard let config, let baseline, let document else { return }
        do {
            let data = try document.replacing(changes: Self.changes(from: baseline, to: config.snapshot()))
            reviewTitle = "Save Preview"
            reviewText = String(decoding: data, as: UTF8.self)
            reviewOriginalText = String(decoding: document.data, as: UTF8.self)
        } catch { errorMessage = error.localizedDescription }
    }

    func showBackup(_ backup: Backup) {
        guard let fileURL else { return }
        do {
            let data = try store.backupData(backup, for: fileURL)
            reviewTitle = "Backup · \(backup.date.formatted())"
            reviewText = String(decoding: data, as: UTF8.self)
            reviewOriginalText = document.map { String(decoding: $0.data, as: UTF8.self) }
        } catch { errorMessage = error.localizedDescription }
    }

    func exportBackup(_ backup: Backup) {
        guard let fileURL else { return }
        do {
            let data = try store.backupData(backup, for: fileURL)
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "ghostty-backup-\(backup.id.uuidString.prefix(8)).conf"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
        } catch { errorMessage = error.localizedDescription }
    }

    func disconnect() {
        withDiscardConfirmation { [weak self] in self?.disconnectUnchecked() }
    }

    private func disconnectUnchecked() {
        clearSession()
        folderURL = nil
        availableFiles = []
        preferences.removeObject(forKey: bookmarkKey)
        preferences.removeObject(forKey: filenameKey)
        statusMessage = "Disconnected. The current editor values are kept as a standalone draft."
    }

    func withDiscardConfirmation(in parent: NSWindow? = nil, _ proceed: @escaping @MainActor () -> Void, cancel: @escaping @MainActor () -> Void = {}) {
        guard hasUnsavedChanges else { proceed(); return }
        guard !discardPromptPresented else { cancel(); return }
        discardPromptPresented = true
        let alert = NSAlert()
        alert.messageText = "Save changes to the local configuration?"
        alert.informativeText = "Your unsaved edits will be replaced if you continue."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Discard Changes")
        guard let window = parent ?? NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }) else {
            discardPromptPresented = false
            cancel()
            return
        }
        alert.beginSheetModal(for: window) { [weak self] response in
            guard let self else { cancel(); return }
            self.discardPromptPresented = false
            switch response {
            case .alertFirstButtonReturn:
                if self.save() { proceed() } else { cancel() }
            case .alertThirdButtonReturn:
                if let snapshot = self.snapshot, let document = self.document { self.apply(snapshot, document: document) }
                proceed()
            default: cancel()
            }
        }
    }

    private func withDraftReplacementConfirmation(_ proceed: @escaping @MainActor () -> Void) {
        guard !isConnected, config?.diff().isEmpty == false else { proceed(); return }
        let alert = NSAlert()
        alert.messageText = "Replace the editor draft?"
        alert.informativeText = "Loading a local file replaces the current draft. Export it first if you want to keep it."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Load File")
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }) else { return }
        alert.beginSheetModal(for: window) { response in
            if response == .alertSecondButtonReturn { proceed() }
        }
    }

    private func loadUnchecked(_ url: URL) throws {
        let candidate = try store.read(url, authorizedFolder: try folder())
        let document = try ConfigFileDocument(data: candidate.data)
        apply(candidate, document: document)
        statusMessage = candidate.existed ? "Loaded \(url.lastPathComponent). Only this file is edited; other configuration files may override its values." : "New configuration. The file will be created when you save."
        preferences.set(url.lastPathComponent, forKey: filenameKey)
    }

    private func apply(_ snapshot: LocalConfigStore.Snapshot, document: ConfigFileDocument) {
        guard let config else { return }
        config.resetToDefaults()
        config.load(parsed: document.parsed.values)
        self.snapshot = snapshot
        self.document = document
        fileURL = snapshot.fileURL
        baseline = config.snapshot()
        conflictMessage = nil
        refreshBackups()
    }

    private func clearSession() {
        snapshot = nil; document = nil; baseline = nil; fileURL = nil; backups = []; lastSaved = nil
    }

    private func folder() throws -> URL {
        guard let folderURL else { throw LocalConfigError.noConnection }
        return folderURL
    }

    private func withAccess<T>(_ operation: () throws -> T) throws -> T {
        let url = try folder()
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        // A false result can also mean an already accessible URL (e.g. tests).
        // File operations remain authoritative and report permission failures.
        return try operation()
    }

    private func persistBookmark() throws {
        let data = try folder().bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        preferences.set(data, forKey: bookmarkKey)
    }

    private func refreshFiles() throws {
        let folder = try folder()
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        availableFiles = files.filter { ((try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == false) && ($0.lastPathComponent == "config" || $0.lastPathComponent == "config.ghostty") }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        // This also lets a first-time user create a config without requesting
        // broad access to the user's home or Application Support directory.
        if availableFiles.isEmpty { availableFiles = [folder.appendingPathComponent("config.ghostty")] }
        if let name = preferences.string(forKey: filenameKey),
           !name.isEmpty, name != ".", name != "..", !name.contains("/"),
           !availableFiles.contains(where: { $0.lastPathComponent == name }) {
            let remembered = folder.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: remembered.path) { availableFiles.append(remembered) }
        }
    }

    private func refreshBackups() { backups = fileURL.map { store.backups(for: $0) } ?? [] }

    static func changes(from baseline: ConfigService.ConfigState, to current: ConfigService.ConfigState) -> [String: [String]] {
        let keys = Set(baseline.values.keys).union(current.values.keys)
        var result: [String: [String]] = [:]
        for key in keys {
            let changed: Bool
            if key == "palette" { changed = baseline.paletteOverrides != current.paletteOverrides }
            else { changed = baseline.values[key] != current.values[key] || baseline.explicitKeys.contains(key) != current.explicitKeys.contains(key) || baseline.explicitColors.contains(key) != current.explicitColors.contains(key) }
            guard changed else { continue }
            let raw = key.reduce(into: "") { $0 += $1.isUppercase ? "-\($1.lowercased())" : String($1) }
            if let value = current.directives[key] {
                let entries = value.entries
                result[raw] = entries.isEmpty && current.explicitKeys.contains(key) ? [""] : entries
            } else { result[raw] = [] }
        }
        return result
    }
}
