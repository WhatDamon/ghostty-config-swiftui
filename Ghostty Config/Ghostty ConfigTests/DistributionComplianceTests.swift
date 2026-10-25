// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Damon Lu (@WhatDamon)

import XCTest
@testable import Ghostty_Config

@MainActor
final class DistributionComplianceTests: XCTestCase {
    private struct Manifest: Decodable {
        let themes: [String: ThemeRecord]
        let sources: [SourceRecord]
    }
    private struct ThemeRecord: Decodable { let license: String; let licenseRevision: String; let licenseSHA256: String; let colorsSHA256: String }
    private struct SourceRecord: Decodable { let license: String; let revision: String }

    func testThemeOptionsAndResourcesContainOnlyReviewedThemes() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "ThemeLicenses", withExtension: "json"))
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: url))
        let names = Set(PanelRegistry.snapshot.themes.keys)
        XCTAssertEqual(names.count, 56)
        XCTAssertEqual(Set(manifest.themes.keys), names)
        XCTAssertEqual(manifest.sources.count, 15)
        XCTAssertTrue(manifest.themes.values.allSatisfy { $0.license == "MIT" && $0.licenseRevision.count == 40 && $0.licenseSHA256.count == 64 && $0.colorsSHA256.count == 64 })
        XCTAssertTrue(manifest.sources.allSatisfy { $0.license == "MIT" && $0.revision.count == 40 })
        XCTAssertEqual(Set(PanelRegistry.definitions[.theme]?.options?.map(\.value) ?? []), names)
        for excluded in ["Monokai Pro", "Monokai Classic", "3024 Day", "3024 Night", "hazyland"] {
            XCTAssertFalse(names.contains(excluded))
        }
    }

    func testCompleteLegalNoticesAreActuallyBundledInApplication() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "LegalNotices", withExtension: "txt"))
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.contains("Apache License"))
        XCTAssertTrue(text.contains("Copyright 2024 Zerebos"))
        XCTAssertTrue(text.contains("Copyright 2026 Damon Lu"))
        XCTAssertTrue(text.contains("Mitchell Hashimoto, Ghostty contributors"))
        XCTAssertTrue(text.contains("Mark Badolato"))
        XCTAssertTrue(text.contains("Permission is hereby granted, free of charge"))
        XCTAssertTrue(text.contains("Copyright (c) 2021 Catppuccin"))
        XCTAssertEqual(AppAttribution.legalText, text)
    }

    func testNonBundledThemeNameStillRoundTripsWithoutColors() {
        let config = ConfigService()
        config.setString("Monokai Pro", for: .theme)
        XCTAssertNil(config.activeThemeName)
        XCTAssertEqual(config.diff(), ["theme": .scalar("Monokai Pro")])
        XCTAssertEqual(config.stringifyConfig(includeHeader: false), "theme = Monokai Pro")
    }

    func testUnofficialIdentityNamesMaintainerAndUpstream() {
        XCTAssertTrue(AppAttribution.summary.contains("Unofficial"))
        XCTAssertTrue(AppAttribution.summary.contains("Damon Lu (@WhatDamon)"))
        XCTAssertTrue(AppAttribution.summary.contains("Zerebos"))
        XCTAssertTrue(AppAttribution.summary.contains("not an official release"))
    }
}
