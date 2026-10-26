// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Damon Lu (@WhatDamon).

import CryptoKit
import Foundation

/// File operations are separate from authorization and UI. Callers must hold a
/// security scope for the selected folder while accessing its contents.
struct LocalConfigStore {
    struct Snapshot {
        let fileURL: URL
        let targetURL: URL
        let data: Data
        let fileID: UInt64?
        let permissions: NSNumber?
        let existed: Bool
    }

    struct Backup: Codable, Identifiable, Equatable {
        let id: UUID
        let sourcePath: String
        let targetPath: String
        let date: Date
        let reason: String
        let byteCount: Int
        let sha256: String
        let permissions: UInt16?
        let existed: Bool
    }

    let backupRoot: URL
    private let fm = FileManager.default

    func read(_ file: URL, authorizedFolder: URL) throws -> Snapshot {
        let folder = authorizedFolder.resolvingSymlinksInPath().standardizedFileURL
        let target = file.resolvingSymlinksInPath().standardizedFileURL
        guard target.path.hasPrefix(folder.path + "/") else { throw LocalConfigError.accessOutsideFolder }
        let exists = fm.fileExists(atPath: target.path)
        guard exists else {
            // Allow creation only directly inside the authorized folder.
            guard target.deletingLastPathComponent() == folder else { throw LocalConfigError.unsafeFile }
            return Snapshot(fileURL: file, targetURL: target, data: Data(), fileID: nil, permissions: nil, existed: false)
        }
        let attributes = try fm.attributesOfItem(atPath: target.path)
        guard attributes[.type] as? FileAttributeType == .typeRegular,
              (attributes[.referenceCount] as? NSNumber)?.intValue == 1 else { throw LocalConfigError.unsafeFile }
        return Snapshot(fileURL: file, targetURL: target, data: try Data(contentsOf: target),
                        fileID: (attributes[.systemFileNumber] as? NSNumber)?.uint64Value,
                        permissions: attributes[.posixPermissions] as? NSNumber, existed: true)
    }

    func write(_ data: Data, replacing snapshot: Snapshot, authorizedFolder: URL, reason: String,
               restoreAbsence: Bool = false, permissions: UInt16? = nil) throws -> Snapshot {
        var coordinationError: NSError?
        var outcome: Result<Snapshot, Error>?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(writingItemAt: snapshot.targetURL, options: .forReplacing, error: &coordinationError) { _ in
            outcome = Result {
                let current = try read(snapshot.fileURL, authorizedFolder: authorizedFolder)
                guard current.targetURL == snapshot.targetURL, current.data == snapshot.data,
                      current.fileID == snapshot.fileID, current.existed == snapshot.existed else { throw LocalConfigError.conflict }
                if restoreAbsence {
                    guard current.existed else { return current }
                    _ = try backup(current, reason: reason)
                    try fm.removeItem(at: current.targetURL)
                    return try read(snapshot.fileURL, authorizedFolder: authorizedFolder)
                }
                guard data != current.data || !current.existed || permissions.map({ NSNumber(value: $0) != current.permissions }) == true else { return current }
                _ = try backup(current, reason: reason)
                let temp = current.targetURL.deletingLastPathComponent().appendingPathComponent(".ghostty-config-\(UUID().uuidString).tmp")
                defer { try? fm.removeItem(at: temp) }
                try data.write(to: temp, options: .withoutOverwriting)
                let mode = permissions.map { NSNumber(value: $0) } ?? current.permissions ?? NSNumber(value: 0o600)
                try fm.setAttributes([.posixPermissions: mode], ofItemAtPath: temp.path)
                if current.existed {
                    // FileManager's replacement keeps the destination metadata.
                    _ = try fm.replaceItemAt(current.targetURL, withItemAt: temp)
                } else {
                    try fm.moveItem(at: temp, to: current.targetURL)
                }
                if let permissions { try fm.setAttributes([.posixPermissions: NSNumber(value: permissions)], ofItemAtPath: current.targetURL.path) }
                let saved = try read(snapshot.fileURL, authorizedFolder: authorizedFolder)
                guard saved.data == data else { throw CocoaError(.fileWriteUnknown) }
                return saved
            }
        }
        if let coordinationError { throw coordinationError }
        guard let outcome else { throw CocoaError(.fileWriteUnknown) }
        return try outcome.get()
    }

    @discardableResult
    func backup(_ snapshot: Snapshot, reason: String) throws -> Backup {
        let record = Backup(id: UUID(), sourcePath: snapshot.fileURL.standardizedFileURL.path,
                            targetPath: snapshot.targetURL.path, date: Date(), reason: reason,
                            byteCount: snapshot.data.count, sha256: Self.digest(snapshot.data),
                            permissions: snapshot.permissions?.uint16Value, existed: snapshot.existed)
        let directory = backupDirectory(for: snapshot.fileURL)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let content = directory.appendingPathComponent("\(record.id).config")
        let metadata = directory.appendingPathComponent("\(record.id).json")
        try snapshot.data.write(to: content, options: .withoutOverwriting)
        try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: content.path)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(record).write(to: metadata, options: .withoutOverwriting)
            try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: metadata.path)
            guard try backupData(record, for: snapshot.fileURL) == snapshot.data else { throw LocalConfigError.backupCorrupt }
        } catch {
            try? fm.removeItem(at: content)
            try? fm.removeItem(at: metadata)
            throw error
        }
        return record
    }

    func backups(for file: URL) -> [Backup] {
        let folder = backupDirectory(for: file)
        return ((try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []).compactMap { url in
            guard url.pathExtension == "json", let data = try? Data(contentsOf: url),
                  let backup = try? JSONDecoder().decode(Backup.self, from: data),
                  backup.sourcePath == file.standardizedFileURL.path else { return nil }
            return backup
        }.sorted { $0.date > $1.date }
    }

    func backupData(_ backup: Backup, for file: URL) throws -> Data {
        guard backup.sourcePath == file.standardizedFileURL.path else { throw LocalConfigError.backupCorrupt }
        let data = try Data(contentsOf: backupDirectory(for: file).appendingPathComponent("\(backup.id).config"))
        guard data.count == backup.byteCount, Self.digest(data) == backup.sha256 else { throw LocalConfigError.backupCorrupt }
        return data
    }

    func backupDirectory(for file: URL) -> URL {
        backupRoot.appendingPathComponent(Self.digest(Data(file.standardizedFileURL.path.utf8)), isDirectory: true)
    }

    static func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
}
