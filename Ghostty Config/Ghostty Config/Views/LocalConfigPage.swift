// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

struct LocalConfigPage: View {
    @Environment(\.localConfigService) private var local
    @State private var restoreTarget: LocalConfigService.Backup?

    var body: some View {
        PageView(title: "Local Config") {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Ghostty Configuration Folder") {
                    VStack(alignment: .leading, spacing: 12) {
                        if let folder = local.folderURL {
                            Text(folder.path).font(.callout.monospaced()).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                            HStack {
                                Button(local.bookmarkNeedsRenewal ? "Authorize Again…" : "Change Folder…") { local.chooseFolder() }
                                Button("Disconnect") { local.disconnect() }
                            }
                            if !local.bookmarkNeedsRenewal {
                                Divider()
                                ForEach(local.availableFiles, id: \.self) { file in
                                    HStack {
                                        Label(file.lastPathComponent, systemImage: "doc.text")
                                        if file == local.fileURL { Text("Loaded").font(.caption).foregroundStyle(.secondary) }
                                        Spacer()
                                        Button(file == local.fileURL ? "Reload" : "Load") { local.loadFile(file) }
                                    }
                                }
                                Button("Choose Another File…") { local.chooseOtherFile() }
                            }
                        } else {
                            Text("Authorize just your Ghostty configuration folder. Access is remembered across launches and can be disconnected here.")
                            Text("Common locations:\n~/.config/ghostty\n~/Library/Application Support/com.mitchellh.ghostty")
                                .font(.callout.monospaced()).textSelection(.enabled).foregroundStyle(.secondary)
                            Text("If you use XDG_CONFIG_HOME, choose its ghostty folder. Both config.ghostty and the older config filename are supported.")
                                .font(.callout).foregroundStyle(.secondary)
                            Button("Authorize Folder…") { local.chooseFolder() }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(4)
                }

                if local.isConnected {
                    GroupBox("Current File") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(local.fileURL?.path ?? "").font(.callout.monospaced()).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                            Text(local.hasUnsavedChanges ? "\(local.changedSettingCount) settings with unsaved changes" : "No unsaved changes")
                                .foregroundStyle(local.hasUnsavedChanges ? .primary : .secondary)
                            HStack {
                                Button("Save") { local.save() }.disabled(!local.hasUnsavedChanges && local.snapshot?.existed == true)
                                    .buttonStyle(.borderedProminent).accessibilityIdentifier("local-save")
                                Button("Preview Saved File…") { local.showChanges() }
                                Button("Reload from Disk") { local.reload() }
                                Button("Show in Finder") {
                                    if let file = local.fileURL { NSWorkspace.shared.activateFileViewerSelecting([file]) }
                                }
                            }
                            Text("Edit settings using the sidebar, then save with ⌘S. Comments and untouched entries are preserved. Reset removes this file's overrides; another configuration file may still supply a value.")
                                .font(.callout).foregroundStyle(.secondary)
                            if local.includesOtherFiles {
                                Label("This file includes other config-file entries. Those files are preserved and are not loaded or modified; Ghostty processes them after this file, so they may override these values.", systemImage: "info.circle")
                                    .font(.callout).foregroundStyle(.secondary)
                            }
                            if !local.diagnostics.isEmpty {
                                DisclosureGroup("Preserved syntax and diagnostics (\(local.diagnostics.count))") {
                                    Text(local.diagnostics.joined(separator: "\n")).font(.caption).textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(4)
                    }
                    backups
                }
                if let status = local.statusMessage { Text(status).font(.callout).foregroundStyle(.secondary).textSelection(.enabled) }
                Text("Ghostty can load multiple files from the XDG and macOS folders. This editor manages only the selected file and does not show Ghostty's combined live configuration.")
                    .font(.callout).foregroundStyle(.secondary)
            }.padding(20).frame(maxWidth: 860)
        }
        .sheet(item: $restoreTarget) { backup in
            VStack(alignment: .leading, spacing: 16) {
                Text("Restore Backup").font(.title2.bold())
                Text(backup.date.formatted(date: .complete, time: .standard))
                Text(backup.existed
                     ? "This replaces the selected file. Its current disk contents will be backed up first. Unsaved editor changes must be saved or discarded."
                     : "The file did not exist when this backup was made. Restoring it removes the selected file after backing up its current contents. Unsaved edits must be saved or discarded.")
                    .foregroundStyle(.secondary)
                Text("Source: \(backup.sourcePath)").font(.caption.monospaced()).textSelection(.enabled)
                Text("SHA-256: \(backup.sha256)").font(.caption.monospaced()).textSelection(.enabled)
                HStack {
                    Spacer()
                    Button("Cancel") { restoreTarget = nil }.keyboardShortcut(.cancelAction)
                    Button("Restore", role: .destructive) { restoreTarget = nil; local.restore(backup) }
                }
            }.padding(24).frame(width: 600)
        }
    }

    private var backups: some View {
        GroupBox("Backups for This File") {
            VStack(alignment: .leading, spacing: 12) {
                Text("A verified byte-for-byte backup is required before saving or restoring. Backups are kept locally in the app's sandbox, separated by source file, and are never automatically deleted.")
                    .font(.callout).foregroundStyle(.secondary)
                HStack {
                    Button("Back Up Disk Contents") { local.backupNow() }.accessibilityIdentifier("local-backup")
                    Button("Show Backups in Finder") {
                        if let folder = local.backupDirectory { NSWorkspace.shared.open(folder) }
                    }.disabled(local.backups.isEmpty)
                }
                if local.backups.isEmpty {
                    Text("No backups yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(local.backups) { backup in
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(backup.date.formatted(date: .abbreviated, time: .standard))
                                Text("\(backup.reason) · \(backup.existed ? "\(backup.byteCount) bytes" : "File did not exist")").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("View") { local.showBackup(backup) }
                            Button("Export…") { local.exportBackup(backup) }
                            Button("Restore…") { restoreTarget = backup }
                        }
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(4)
        }
    }
}
