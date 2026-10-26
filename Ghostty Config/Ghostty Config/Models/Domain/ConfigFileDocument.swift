// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Damon Lu (@WhatDamon).

import Foundation

/// Keep the source text separate from the editor's normalized values. Untouched
/// lines (including unsupported syntax) must never pass through the serializer.
struct ConfigFileDocument {
    struct Line {
        var text: String
        var ending: String
        var entry: (key: String, value: String)? {
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("#"), let equals = trimmed.firstIndex(of: "=") else { return nil }
            let key = trimmed[..<equals].trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty, key.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }) else { return nil }
            return (key, trimmed[trimmed.index(after: equals)...].trimmingCharacters(in: .whitespaces))
        }
    }

    let data: Data
    let lines: [Line]
    let hasBOM: Bool
    let parsed: ConfigParseResult
    let protectedKeys: Set<String>

    init(data: Data) throws {
        guard var text = String(data: data, encoding: .utf8), !text.contains("\0") else { throw LocalConfigError.unsupportedEncoding }
        self.data = data
        hasBOM = text.hasPrefix("\u{FEFF}")
        if hasBOM { text.removeFirst() }
        var lines: [Line] = []
        // NSString splitting treats CRLF as bytes rather than a Swift grapheme.
        let parts = text.components(separatedBy: "\n")
        for (index, part) in parts.enumerated() {
            let isLast = index == parts.count - 1
            if isLast && part.isEmpty { continue }
            let crlf = !isLast && part.hasSuffix("\r")
            lines.append(Line(text: crlf ? String(part.dropLast()) : part, ending: isLast ? "" : (crlf ? "\r\n" : "\n")))
        }
        self.lines = lines
        var normalized: [String] = []
        var protected = Set<String>()
        var diagnostics: [String] = []
        for (index, line) in lines.enumerated() {
            guard let entry = line.entry else {
                if !line.text.trimmingCharacters(in: .whitespaces).isEmpty && !line.text.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                    diagnostics.append("Line \(index + 1): unrecognized text is preserved unchanged.")
                }
                continue
            }
            var value = entry.value
            if value.hasPrefix("\"") {
                if value.count >= 2 && value.hasSuffix("\"") && !value.contains("\\") {
                    value = String(value.dropFirst().dropLast())
                } else {
                    protected.insert(entry.key)
                    diagnostics.append("Line \(index + 1): \(entry.key) uses quoting this editor cannot safely modify; the original text is preserved.")
                    continue
                }
            }
            let key = ConfigKey(rawValue: entry.key)
            if value.isEmpty, let setting = PanelRegistry.definitions[key], !setting.repeatable, key != .palette {
                // Empty is a reset to the default even for numeric settings.
                normalized.removeAll { $0.hasPrefix(entry.key + " =") }
                continue
            }
            let inspected = ConfigParserService.inspect("\(entry.key) = \(value)")
            if !inspected.diagnostics.isEmpty {
                protected.insert(entry.key)
                diagnostics.append("Line \(index + 1): \(entry.key) is preserved but cannot be safely edited here.")
            }
            normalized.append("\(entry.key) = \(value)")
        }
        var parsed = ConfigParserService.inspect(normalized.joined(separator: "\n"))
        parsed.diagnostics = diagnostics
        self.parsed = parsed
        protectedKeys = protected
    }

    func replacing(changes: [String: [String]]) throws -> Data {
        guard !changes.isEmpty else { return data }
        var output = lines
        let newline = lines.first(where: { !$0.ending.isEmpty })?.ending ?? "\n"
        for key in changes.keys.sorted() {
            guard !protectedKeys.contains(key) else { throw LocalConfigError.protectedSetting(key) }
            let values = changes[key]!
            guard values.allSatisfy({ !$0.contains("\n") && !$0.contains("\r") && !$0.contains("\0") && !$0.hasPrefix("\"") }) else { throw LocalConfigError.invalidValue(key) }
            for value in values where !value.isEmpty {
                guard ConfigParserService.inspect("\(key) = \(value)").diagnostics.isEmpty else { throw LocalConfigError.invalidValue(key) }
            }
            let indices = output.indices.filter { output[$0].entry?.key == key }
            if let last = indices.last {
                // Replace at the last occurrence, leaving adjacent comments and
                // directives in place. No untouched setting is reordered.
                let ending = output[last].ending
                var replacements = values.map { Line(text: "\(key) = \($0)", ending: newline) }
                if !replacements.isEmpty { replacements[replacements.count - 1].ending = ending }
                output.replaceSubrange(last...last, with: replacements)
                for index in indices.dropLast().reversed() { output.remove(at: index) }
            } else if !values.isEmpty {
                if !output.isEmpty && output[output.count - 1].ending.isEmpty { output[output.count - 1].ending = newline }
                output.append(contentsOf: values.map { Line(text: "\(key) = \($0)", ending: newline) })
            }
        }
        let text = (hasBOM ? "\u{FEFF}" : "") + output.map { $0.text + $0.ending }.joined()
        return Data(text.utf8)
    }
}

enum LocalConfigError: LocalizedError {
    case unsupportedEncoding, conflict, accessOutsideFolder, unsafeFile, backupCorrupt, noConnection
    case protectedSetting(String), invalidValue(String)
    var errorDescription: String? {
        switch self {
        case .unsupportedEncoding: "The file must be UTF-8 text without NUL characters. No files were changed."
        case .conflict: "The configuration changed outside this app (or its symbolic link changed). Reload and review it before saving. Your edits are still in the editor."
        case .accessOutsideFolder: "This symbolic link points outside the authorized folder. Choose the target file's folder to edit it safely."
        case .unsafeFile: "Only a regular file with a single hard link can be managed. No files were changed."
        case .backupCorrupt: "The backup is missing or its checksum does not match. Restore was stopped."
        case .noConnection: "Connect and load a configuration file first."
        case .protectedSetting(let key): "The original \(key) syntax cannot be safely edited here. Other settings can still be saved; reload to discard this unsupported edit."
        case .invalidValue(let key): "\(key) contains unsupported multiline or quoted syntax. No files were changed."
        }
    }
}
