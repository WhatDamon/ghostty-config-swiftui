import XCTest
@testable import Ghostty_Config

@MainActor
final class UpstreamMigrationTests: XCTestCase {
    func testSnapshotIsCompleteAndNavigationHasNoDuplicates() {
        XCTAssertEqual(PanelRegistry.snapshot.source.revision, "f2eac4de31a8b4eb924850c5f96f4a113c940773")
        XCTAssertEqual(PanelRegistry.snapshot.themes.count, 56)
        XCTAssertEqual(PanelRegistry.definitions.count, 201)
        XCTAssertEqual(PanelRegistry.all.count, 9)
        let items = PanelRegistry.all.flatMap(\.groups).flatMap(\.settings)
        XCTAssertEqual(items.count, 181)
        XCTAssertEqual(Set(items.map(\.configKey)).count, 181)
        XCTAssertEqual(PanelRegistry.all.first { $0.panelId == "terminal" }?.groups.flatMap(\.settings).count, 16)
        XCTAssertEqual(PanelRegistry.settings[.windowPaddingX]?.type, .dualNumber)
        XCTAssertEqual(PanelRegistry.settings[.mouseScrollMultiplier]?.type, .scrollMultiplier)
        XCTAssertEqual(PanelRegistry.settings[.fontFamily]?.defaultValue, .list([]))
        XCTAssertEqual(PanelRegistry.settings[.undoTimeout]?.defaultValue, .scalar("5s"))
        XCTAssertEqual(PanelRegistry.settings[.copyOnSelect]?.defaultValue, .scalar("true"))
    }

    func testEveryNewWidgetHasNativeMetadata() {
        let expected: [(ConfigKey, SettingUIType)] = [(.fontFeature, .repeatableText), (.shellIntegrationFeatures, .featureList), (.adjustCellWidth, .numberUnits), (.undoTimeout, .duration), (.windowPaddingY, .dualNumber), (.backgroundBlur, .customNumber), (.cursorColor, .customColor)]
        for (key, type) in expected { XCTAssertEqual(PanelRegistry.settings[key]?.type, type) }
        XCTAssertEqual(PanelRegistry.settings[.shellIntegrationFeatures]?.widget.features?.count, 6)
        XCTAssertTrue(PanelRegistry.settings[.backgroundBlur]?.widget.presets?.contains { $0.value == "macos-glass-clear" } ?? false)
    }

    func testAllNewFormatsImportAndExportWithoutLosingStrings() {
        let text = """
        font-family = First Font
        font-family =
        font-family = 第二字体
        undo-timeout = 1h30m
        resize-overlay-duration = 750ms
        adjust-cell-width = -15%
        window-padding-x = 2,4
        mouse-scroll-multiplier = precision:1,discrete:3
        shell-integration-features = no-sudo,new-feature
        background-blur = macos-glass-clear
        cursor-color = cell-foreground
        window-width =
        """
        let parsed = ConfigParserService.inspect(text)
        XCTAssertTrue(parsed.diagnostics.isEmpty, parsed.diagnostics.joined(separator: ";"))
        let first = ConfigService()
        first.load(parsed: parsed.values)
        XCTAssertEqual(first.array(for: .fontFamily), ["First Font", "", "第二字体"])
        XCTAssertEqual(first.string(for: .windowWidth), "")
        let output = first.stringifyConfig()
        let second = ConfigService()
        second.load(parsed: ConfigParserService.parse(output))
        XCTAssertEqual(second.stringifyConfig(), output)
        XCTAssertTrue(output.contains("font-family = \n"))
        XCTAssertEqual(second.string(for: .mouseScrollMultiplier), "precision:1,discrete:3")
    }

    func testValueShapeIsNotInferredFromText() {
        let parsed = ConfigParserService.parse("title = 0123\nfont-family = 42\nmouse-hide-while-typing = true\nfont-size = 14.50")
        XCTAssertEqual(parsed["title"], .scalar("0123"))
        XCTAssertEqual(parsed["fontFamily"], .list(["42"]))
        XCTAssertEqual(parsed["mouseHideWhileTyping"], .scalar("true"))
        XCTAssertEqual(parsed["fontSize"], .scalar("14.50"))
    }

    func testImportDoesNotUseSliderConvenienceBoundsAsParserLimits() {
        let parsed = ConfigParserService.inspect("font-size = 72\nmouse-scroll-multiplier = precision:0.01,discrete:500\nwindow-height = 1000")
        XCTAssertEqual(parsed.entryCount, 3)
        XCTAssertTrue(parsed.diagnostics.isEmpty)
    }

    func testOnlySelectingAThemeExportsOnlyTheme() {
        let service = ConfigService()
        service.setString("Catppuccin Mocha", for: .theme)
        XCTAssertEqual(service.diff(), ["theme": .scalar("Catppuccin Mocha")])
        XCTAssertEqual(service.resolvedColor(for: .background).lowercased(), "#1e1e2e")
        XCTAssertEqual(service.colorSource(for: .background), .theme("Catppuccin Mocha"))
    }

    func testThemeOverrideSurvivesThemeSwitchAndResetFollowsTheme() {
        let service = ConfigService()
        service.setString("Catppuccin Mocha", for: .theme)
        service.setString("#123456", for: .background)
        service.setString("Catppuccin Latte", for: .theme)
        XCTAssertEqual(service.resolvedColor(for: .background), "#123456")
        XCTAssertEqual(service.colorSource(for: .background), .override)
        service.resetSetting(.background)
        XCTAssertEqual(service.colorSource(for: .background), .theme("Catppuccin Latte"))
        XCTAssertEqual(service.resolvedColor(for: .background).lowercased(), "#eff1f5")
        XCTAssertNil(service.diff()["background"])
    }

    func testExplicitAppDefaultColorStillOverridesTheme() {
        let service = ConfigService()
        let original = service.string(for: .background)
        service.setString("Catppuccin Latte", for: .theme)
        service.setString(original, for: .background)
        XCTAssertEqual(service.resolvedColor(for: .background), original)
        XCTAssertEqual(service.diff()["background"], .scalar(original))
        XCTAssertEqual(service.colorSource(for: .background), .override)
    }

    func testPaletteOverridesArePerIndexAndMayEqualAppDefault() {
        let service = ConfigService()
        service.setString("Catppuccin Mocha", for: .theme)
        let untouched = service.effectivePalette[0]
        service.setPalette("#123456", at: 3)
        XCTAssertEqual(service.effectivePalette[0], untouched)
        XCTAssertEqual(service.effectivePalette[3], "#123456")
        XCTAssertEqual(service.diff()["palette"], .list(["3=#123456"]))
        service.resetPalette(at: 3)
        XCTAssertEqual(service.paletteSource(at: 3), .theme("Catppuccin Mocha"))
        XCTAssertNil(service.diff()["palette"])
        service.setPalette(service.array(for: .palette)[0], at: 0)
        XCTAssertEqual(service.paletteSource(at: 0), .override)
        XCTAssertNotNil(service.diff()["palette"])
    }

    func testDualThemePreviewNeverSerializesAppearanceState() {
        let service = ConfigService()
        service.setString("light:Catppuccin Latte,dark:Catppuccin Mocha", for: .theme)
        service.previewMode = .light
        XCTAssertEqual(service.resolvedColor(for: .background).lowercased(), "#eff1f5")
        service.previewMode = .dark
        XCTAssertEqual(service.resolvedColor(for: .background).lowercased(), "#1e1e2e")
        XCTAssertEqual(service.diff(), ["theme": .scalar("light:Catppuccin Latte,dark:Catppuccin Mocha")])
        service.previewMode = .system
        service.systemIsLight = true
        XCTAssertEqual(service.activeThemeName, "Catppuccin Latte")
    }

    func testImportedThemeIsPreviewedWithoutDownloadingOrMutatingColors() {
        let service = ConfigService()
        service.load(parsed: ConfigParserService.parse("theme = Catppuccin Latte"))
        XCTAssertEqual(service.activeThemeName, "Catppuccin Latte")
        XCTAssertEqual(service.diff().count, 1)
        service.setString("/custom/theme-path", for: .theme)
        XCTAssertNil(service.activeThemeName)
        XCTAssertEqual(service.string(for: .theme), "/custom/theme-path")
    }

    func testResettingThemeKeepsExplicitOverrides() {
        let service = ConfigService()
        service.setString("Catppuccin Latte", for: .theme)
        service.setString("#123456", for: .foreground)
        service.resetSetting(.theme)
        XCTAssertEqual(service.resolvedColor(for: .foreground), "#123456")
        XCTAssertTrue(service.isNonDefault(.foreground))
    }

    func testCellKeywordsResolveAcrossThemeAndExplicitLayers() {
        let service = ConfigService()
        service.setString("Catppuccin Mocha", for: .theme)
        service.setString("cell-background", for: .cursorText)
        service.setString("cell-foreground", for: .selectionBackground)
        XCTAssertEqual(service.resolvedColor(for: .cursorText), service.resolvedColor(for: .background))
        XCTAssertEqual(service.resolvedColor(for: .selectionBackground), service.resolvedColor(for: .foreground))
    }

    func testFeatureEditingPreservesUnknownTokensAndDefaults() throws {
        let definitions = try XCTUnwrap(PanelRegistry.settings[.shellIntegrationFeatures]?.widget.features)
        XCTAssertEqual(SettingCodecs.features("", definitions: definitions)["sudo"], false)
        let edited = SettingCodecs.settingFeature("sudo", enabled: true, raw: "new-feature,no-title", definitions: definitions)
        XCTAssertTrue(edited.contains("new-feature"))
        XCTAssertTrue(edited.contains("sudo"))
        XCTAssertTrue(edited.contains("no-title"))
        XCTAssertEqual(SettingCodecs.features("false", definitions: definitions).values.filter { $0 }.count, 0)
    }

    func testDurationsAndPairsValidateWithoutMutatingRawValues() {
        for raw in ["1h30m", "750ms", "0s", "10us"] { XCTAssertNil(SettingCodecs.durationError(raw, allowEmpty: false)) }
        for raw in ["1h1h", "12", "-2s", "nan"] { XCTAssertNotNil(SettingCodecs.durationError(raw, allowEmpty: false)) }
        XCTAssertNil(SettingCodecs.durationError("", allowEmpty: true))
        XCTAssertNotNil(SettingCodecs.durationError("", allowEmpty: false))
        let pair = SettingCodecs.pair("2,4")
        XCTAssertFalse(pair.linked)
        XCTAssertEqual(pair.raw, "2,4")
        XCTAssertEqual(SettingCodecs.scrollString(SettingCodecs.scrollPair("precision:1,discrete:3")), "precision:1,discrete:3")
    }

    func testImportReviewIncludesResetToDefaultWithoutMutatingCurrentConfig() {
        let service = ConfigService()
        service.setDouble(30, for: .fontSize)
        let parsed = ConfigParserService.parse("font-size = 13")
        let changes = service.importChanges(parsed)
        XCTAssertEqual(changes.count, 1)
        XCTAssertTrue(changes[0].overridesExisting)
        XCTAssertEqual(service.double(for: .fontSize), 30)
        service.load(parsed: parsed)
        XCTAssertEqual(service.double(for: .fontSize), 13)
        XCTAssertFalse(service.isNonDefault(.fontSize))
    }
    func testEveryScalarWidgetDefaultIsRepresentable() {
        for (key, setting) in PanelRegistry.definitions where !setting.repeatable {
            XCTAssertNil(SettingCodecs.validationError(setting.defaultValue.text, setting: setting), key.rawValue)
            if setting.type == .dropdown || setting.type == .pill {
                if !setting.defaultValue.text.isEmpty {
                    XCTAssertTrue(setting.options?.contains { $0.value == setting.defaultValue.text } ?? false, key.rawValue)
                }
            }
        }
    }

    func testFullSnapshotRoundTripIsCodable() throws {
        let values: [String: ConfigValue] = ["fontFamily": .list(["A", "", "B"]), "title": .scalar("0123")]
        let decoded = try JSONDecoder().decode([String: ConfigValue].self, from: JSONEncoder().encode(values))
        XCTAssertEqual(decoded, values)
    }

    func testAllFeatureChangesRetainUnknownFeatures() throws {
        let definitions = try XCTUnwrap(PanelRegistry.settings[.shellIntegrationFeatures]?.widget.features)
        var raw = "unknown-flag,no-unknown-other"
        for feature in definitions { raw = SettingCodecs.settingFeature(feature.id, enabled: true, raw: raw, definitions: definitions) }
        XCTAssertTrue(raw.contains("unknown-flag"))
        XCTAssertTrue(raw.contains("no-unknown-other"))
        for feature in definitions { XCTAssertEqual(SettingCodecs.features(raw, definitions: definitions)[feature.id], true) }
    }

    func testImportReviewIncludesEqualValueThatChangesThemeInheritance() {
        let service = ConfigService()
        service.setString("Catppuccin Latte", for: .theme)
        let original = service.string(for: .background)
        let changes = service.importChanges(["background": .scalar(original)])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(service.colorSource(for: .background), .theme("Catppuccin Latte"))
        service.load(parsed: ["background": .scalar(original)])
        XCTAssertEqual(service.colorSource(for: .background), .override)
    }

    func testEmptyAndUnknownInputHaveDistinctReviewBehavior() {
        let service = ConfigService()
        XCTAssertTrue(service.importChanges(ConfigParserService.parse("# comment only")).isEmpty)
        let values = ConfigParserService.parse("future-setting = 0123\nfuture-setting =")
        XCTAssertEqual(values["futureSetting"], .list(["0123", ""]))
        service.load(parsed: values)
        XCTAssertTrue(service.stringifyConfig().contains("future-setting = 0123\nfuture-setting = "))
    }

    func testScrollMultiplierWhitespaceAndInvalidParts() throws {
        let setting = try XCTUnwrap(PanelRegistry.settings[.mouseScrollMultiplier])
        let valid = "precision: 1, discrete: 3"
        XCTAssertNil(SettingCodecs.validationError(valid, setting: setting))
        XCTAssertEqual(SettingCodecs.scrollPair(valid).second, "3")
        for raw in ["precision:", "precision:3,", "future:2", "precision:nan", "-2", "1,3"] {
            XCTAssertNotNil(SettingCodecs.validationError(raw, setting: setting), raw)
        }
    }

}
