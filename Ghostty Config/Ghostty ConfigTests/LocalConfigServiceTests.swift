// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Damon Lu (@WhatDamon).

import XCTest
@testable import Ghostty_Config

@MainActor
final class LocalConfigServiceTests: XCTestCase {
    private func patch(_ original: String, edit: (ConfigService) -> Void) throws -> String {
        let document = try ConfigFileDocument(data: Data(original.utf8))
        let config = ConfigService()
        config.load(parsed: document.parsed.values)
        let baseline = config.snapshot()
        edit(config)
        return String(decoding: try document.replacing(changes: LocalConfigService.changes(from: baseline, to: config.snapshot())), as: UTF8.self)
    }

    func testNoEditsPreserveEveryByteIncludingBOMMixedEndingsAndExplicitDefaults() throws {
        let original = "\u{FEFF}# comment\r\nfont-size = 12\nunknown-key = 123\r\nfont-family = \"JetBrains Mono\"\r\ninvalid syntax\n"
        XCTAssertEqual(try patch(original) { _ in }, original)
    }

    func testUnrelatedEditsPreserveUnknownEntriesCommentsAndOrder() throws {
        let original = "# comment\nfont-size = 12\nunknown-option = kept\nunknown-option = twice\nkeybind = ctrl+a=copy_to_clipboard\n\n"
        XCTAssertEqual(try patch(original) { $0.setInt(18, for: .fontSize) }, original.replacingOccurrences(of: "font-size = 12", with: "font-size = 18"))
    }

    func testChangedScalarReplacesAllOccurrencesAtLastPosition() throws {
        let text = "font-size = 12\n# note\nfont-size=14\nforeground = #eeeeee"
        XCTAssertEqual(try patch(text) { $0.setInt(20, for: .fontSize) }, "# note\nfont-size = 20\nforeground = #eeeeee")
    }

    func testCRLFAndNoTrailingNewlineAreRetained() throws {
        XCTAssertEqual(try patch("# comment\r\nfont-size = 12") { $0.setInt(18, for: .fontSize) }, "# comment\r\nfont-size = 18")
    }

    func testNewEntryDoesNotJoinPreviousUnterminatedLine() throws {
        XCTAssertEqual(try patch("# only a comment") { $0.setInt(20, for: .fontSize) }, "# only a comment\nfont-size = 20\n")
    }

    func testResetRemovesAnExplicitDefaultInsteadOfLeavingItBehind() throws {
        let config = ConfigService()
        let text = "# explicit default\nfont-size = \(config.string(for: .fontSize))\n"
        XCTAssertEqual(try patch(text) { $0.resetSetting(.fontSize) }, "# explicit default\n")
    }

    func testEmptyScalarResetIsLoadedAsDefaultAndKeptUntouched() throws {
        let document = try ConfigFileDocument(data: Data("font-size = 20\nfont-size =\n".utf8))
        let config = ConfigService()
        config.load(parsed: document.parsed.values)
        XCTAssertEqual(config.string(for: .fontSize), ConfigService().string(for: .fontSize))
        XCTAssertEqual(try document.replacing(changes: [:]), document.data)
    }

    func testExplicitlySettingDefaultIsWritten() throws {
        let expected = ConfigService().string(for: .fontSize)
        XCTAssertEqual(try patch("") { $0.setString(expected, for: .fontSize) }, "font-size = \(expected)\n")
    }

    func testPaletteWritesIndexedOverridesAndNeverExpandsDefaultPalette() throws {
        let text = "# colors\npalette = 3=#112233\nfont-size = 18\n"
        let result = try patch(text) { $0.setPalette("#aabbcc", at: 7) }
        XCTAssertTrue(result.contains("palette = 3=#112233\npalette = 7=#AABBCC\n"))
        XCTAssertEqual(result.components(separatedBy: "palette =").count - 1, 2)
        XCTAssertTrue(result.hasSuffix("font-size = 18\n"))
    }

    func testPaletteResetRemovesItsOverrides() throws {
        XCTAssertEqual(try patch("palette = 3=#112233\n") { $0.resetSetting(.palette) }, "")
    }

    func testKeybindEditUsesClearSoRemovedBindingsStayRemovedOnReload() throws {
        let original = "keybind = ctrl+a=copy_to_clipboard\n# note\nkeybind = ctrl+b=paste_from_clipboard\n"
        let output = try patch(original) { $0.set(["ctrl+x=copy_to_clipboard"], for: .keybind) }
        XCTAssertEqual(output, "# note\nkeybind = clear\nkeybind = ctrl+x=copy_to_clipboard\n")
        let loaded = ConfigService()
        loaded.load(parsed: try ConfigFileDocument(data: Data(output.utf8)).parsed.values)
        XCTAssertEqual(loaded.array(for: .keybind), ["clear", "ctrl+x=copy_to_clipboard"])
    }

    func testQuotedStringIsDecodedForEditingButKeptUntilChanged() throws {
        let original = "title = \"my terminal\"\n"
        let doc = try ConfigFileDocument(data: Data(original.utf8))
        XCTAssertEqual(doc.parsed.values["title"], .scalar("my terminal"))
        XCTAssertEqual(try patch(original) { _ in }, original)
        XCTAssertEqual(try patch(original) { $0.setString("new terminal", for: .title) }, "title = new terminal\n")
    }

    func testUnsupportedSyntaxBlocksOnlyChangesToAffectedKey() throws {
        let original = "title = \"escaped\\\"quote\"\nfont-size = 12\n"
        XCTAssertNoThrow(try patch(original) { $0.setInt(20, for: .fontSize) })
        XCTAssertThrowsError(try patch(original) { $0.setString("new", for: .title) })
    }

    func testEmbeddedNewlineIsRejectedRatherThanCreatingAnExtraDirective() throws {
        XCTAssertThrowsError(try patch("") { $0.setString("value\ncommand = bad", for: .title) })
    }

    private func fixture(_ body: (URL, URL, LocalConfigStore) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let folder = root.appendingPathComponent("ghostty")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(folder, folder.appendingPathComponent("config"), LocalConfigStore(backupRoot: root.appendingPathComponent("backups")))
    }

    func testSaveMakesVerifiedBackupAndPreservesPermissions() throws {
        try fixture { folder, file, store in
            let original = Data("# original\nfont-size = 18\n".utf8)
            try original.write(to: file)
            try FileManager.default.setAttributes([.posixPermissions: 0o640], ofItemAtPath: file.path)
            let before = try store.read(file, authorizedFolder: folder)
            let new = Data("# original\nfont-size = 20\n".utf8)
            let after = try store.write(new, replacing: before, authorizedFolder: folder, reason: "Before save")
            XCTAssertEqual(after.data, new)
            XCTAssertEqual(after.permissions?.intValue, 0o640)
            let backup = try XCTUnwrap(store.backups(for: file).first)
            XCTAssertEqual(try store.backupData(backup, for: file), original)
        }
    }

    func testExternalChangesStopSaveAndRestoreWithoutCreatingBackup() throws {
        try fixture { folder, file, store in
            try Data("font-size = 18\n".utf8).write(to: file)
            let snapshot = try store.read(file, authorizedFolder: folder)
            let external = Data("font-size = 22\n".utf8)
            try external.write(to: file)
            XCTAssertThrowsError(try store.write(Data("font-size = 30\n".utf8), replacing: snapshot, authorizedFolder: folder, reason: "Before restore"))
            XCTAssertEqual(try Data(contentsOf: file), external)
            XCTAssertTrue(store.backups(for: file).isEmpty)
        }
    }

    func testNoOpSaveDoesNotWriteOrCreateBackup() throws {
        try fixture { folder, file, store in
            let data = Data("font-size=18\n".utf8)
            try data.write(to: file)
            let before = try store.read(file, authorizedFolder: folder)
            let after = try store.write(data, replacing: before, authorizedFolder: folder, reason: "Before save")
            XCTAssertEqual(before.fileID, after.fileID)
            XCTAssertTrue(store.backups(for: file).isEmpty)
        }
    }

    func testCorruptOrWrongSourceBackupIsRejected() throws {
        try fixture { folder, file, store in
            try Data("font-size=18".utf8).write(to: file)
            let backup = try store.backup(store.read(file, authorizedFolder: folder), reason: "Manual")
            XCTAssertThrowsError(try store.backupData(backup, for: folder.appendingPathComponent("other")))
            try Data("corrupt".utf8).write(to: store.backupDirectory(for: file).appendingPathComponent("\(backup.id).config"))
            XCTAssertThrowsError(try store.backupData(backup, for: file))
        }
    }

    func testFailedBackupPreventsAnyWrite() throws {
        try fixture { folder, file, _ in
            let data = Data("font-size=18".utf8)
            try data.write(to: file)
            let blocked = folder.appendingPathComponent("not-a-directory")
            try Data().write(to: blocked)
            let store = LocalConfigStore(backupRoot: blocked)
            XCTAssertThrowsError(try store.write(Data("changed".utf8), replacing: store.read(file, authorizedFolder: folder), authorizedFolder: folder, reason: "Before save"))
            XCTAssertEqual(try Data(contentsOf: file), data)
        }
    }

    func testSymlinkWithinFolderKeepsTheLinkAndWritesTarget() throws {
        try fixture { folder, file, store in
            let target = folder.appendingPathComponent("actual.conf")
            try Data("font-size=18".utf8).write(to: target)
            try FileManager.default.createSymbolicLink(at: file, withDestinationURL: target)
            let before = try store.read(file, authorizedFolder: folder)
            _ = try store.write(Data("font-size=20".utf8), replacing: before, authorizedFolder: folder, reason: "Before save")
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: file.path), target.path)
            XCTAssertEqual(try String(contentsOf: target, encoding: .utf8), "font-size=20")
        }
    }

    func testSymlinkOutsideAuthorizedFolderIsRejected() throws {
        try fixture { folder, file, store in
            let external = folder.deletingLastPathComponent().appendingPathComponent("outside")
            try Data().write(to: external)
            try FileManager.default.createSymbolicLink(at: file, withDestinationURL: external)
            XCTAssertThrowsError(try store.read(file, authorizedFolder: folder))
        }
    }

    func testBackupsAreSeparatedByFileAndNeverOverwriteWithinSameSecond() throws {
        try fixture { folder, file, store in
            try Data("title=one".utf8).write(to: file)
            let one = try store.read(file, authorizedFolder: folder)
            let first = try store.backup(one, reason: "Manual")
            let second = try store.backup(one, reason: "Manual")
            XCTAssertNotEqual(first.id, second.id)
            XCTAssertEqual(store.backups(for: file).count, 2)
            XCTAssertTrue(store.backups(for: folder.appendingPathComponent("different")).isEmpty)
        }
    }

    func testCreatingNewFileBacksUpPreviousAbsence() throws {
        try fixture { folder, file, store in
            let before = try store.read(file, authorizedFolder: folder)
            XCTAssertFalse(before.existed)
            let after = try store.write(Data("title=new\n".utf8), replacing: before, authorizedFolder: folder, reason: "Before save")
            XCTAssertTrue(after.existed)
            XCTAssertFalse(try XCTUnwrap(store.backups(for: file).first).existed)
            let absence = try XCTUnwrap(store.backups(for: file).first)
            let restored = try store.write(try store.backupData(absence, for: file), replacing: after, authorizedFolder: folder, reason: "Before restore", restoreAbsence: true)
            XCTAssertFalse(restored.existed)
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
            XCTAssertEqual(store.backups(for: file).count, 2)
        }
    }

    func testServiceSaveRestoreAndManualBackupReadDisk() throws {
        try fixture { folder, file, store in
            let original = Data("# original\nfont-size = 17\nunknown-test = retained\n".utf8)
            try original.write(to: file)
            let config = ConfigService()
            let service = LocalConfigService(backupRoot: store.backupRoot, preferences: UserDefaults(suiteName: UUID().uuidString)!)
            try service.connect(folder: folder, file: file, config: config)
            XCTAssertFalse(service.hasUnsavedChanges)
            config.setInt(19, for: .fontSize)
            XCTAssertTrue(service.hasUnsavedChanges)
            XCTAssertTrue(service.save())
            XCTAssertFalse(service.hasUnsavedChanges)
            let backup = try XCTUnwrap(service.backups.first)
            XCTAssertEqual(try store.backupData(backup, for: file), original)
            service.restore(backup)
            XCTAssertEqual(try Data(contentsOf: file), original)
            XCTAssertEqual(config.int(for: .fontSize), 17)

            let external = Data("font-size = 25\n".utf8)
            try external.write(to: file)
            service.backupNow()
            XCTAssertEqual(try store.backupData(XCTUnwrap(service.backups.first), for: file), external)
            config.setInt(30, for: .fontSize)
            XCTAssertFalse(service.save())
            XCTAssertNotNil(service.conflictMessage)
            XCTAssertTrue(service.hasUnsavedChanges)
            XCTAssertEqual(try Data(contentsOf: file), external)
        }
    }

    func testRetargetedSymlinkIsDetectedEvenWithSameBytes() throws {
        try fixture { folder, file, store in
            let first = folder.appendingPathComponent("first")
            let second = folder.appendingPathComponent("second")
            try Data("title=same".utf8).write(to: first)
            try Data("title=same".utf8).write(to: second)
            try FileManager.default.createSymbolicLink(at: file, withDestinationURL: first)
            let snapshot = try store.read(file, authorizedFolder: folder)
            try FileManager.default.removeItem(at: file)
            try FileManager.default.createSymbolicLink(at: file, withDestinationURL: second)
            XCTAssertThrowsError(try store.write(Data("title=new".utf8), replacing: snapshot, authorizedFolder: folder, reason: "Before save"))
            XCTAssertEqual(try String(contentsOf: second, encoding: .utf8), "title=same")
        }
    }

    func testRestoreCanRestoreBackupPermissions() throws {
        try fixture { folder, file, store in
            try Data("title=old".utf8).write(to: file)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
            let old = try store.read(file, authorizedFolder: folder)
            let backup = try store.backup(old, reason: "Manual")
            let updated = try store.write(Data("title=new".utf8), replacing: old, authorizedFolder: folder, reason: "Before save")
            try FileManager.default.setAttributes([.posixPermissions: 0o640], ofItemAtPath: file.path)
            let restored = try store.write(try store.backupData(backup, for: file), replacing: updated, authorizedFolder: folder, reason: "Before restore", permissions: backup.permissions)
            XCTAssertEqual(restored.permissions?.intValue, 0o600)
            XCTAssertEqual(restored.data, old.data)
        }
    }
}
