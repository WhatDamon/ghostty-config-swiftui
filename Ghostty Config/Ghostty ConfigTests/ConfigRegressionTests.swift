import XCTest
@testable import Ghostty_Config

@MainActor
final class ConfigRegressionTests: XCTestCase {
    func testImportUsesSettingTypesAndPreservesText() {
        let service = ConfigService()
        service.load(parsed: ConfigParserService.parse("mouse-hide-while-typing = true\nwindow-padding-x = 4\nbackground-opacity = 0.75\nfont-size = 14.5"))
        XCTAssertTrue(service.bool(for: .mouseHideWhileTyping))
        XCTAssertEqual(service.string(for: .windowPaddingX), "4")
        XCTAssertEqual(service.double(for: .backgroundOpacity), 0.75)
        XCTAssertEqual(service.double(for: .fontSize), 14.5)
    }

    func testPaletteImportExportRoundTripAndReset() {
        let service = ConfigService()
        XCTAssertEqual(service.array(for: .palette).count, 256)
        service.load(parsed: ConfigParserService.parse("palette = 1=#123456"))
        XCTAssertEqual(service.array(for: .palette)[1], "#123456")
        XCTAssertTrue(service.stringifyConfig().contains("palette = 1=#123456"))
        let copy = ConfigService()
        copy.load(parsed: ConfigParserService.parse(service.stringifyConfig()))
        XCTAssertEqual(copy.array(for: .palette), service.array(for: .palette))
        service.resetSetting(.palette)
        XCTAssertFalse(service.isNonDefault(.palette))
        XCTAssertFalse(service.stringifyConfig().contains("palette ="))
    }

    func testKeybindParserRejectsEmptySequenceStepsAndAcceptsW3CNames() {
        XCTAssertFalse(parseKeybind("ctrl+a>>b=ignore").errors.isEmpty)
        XCTAssertFalse(parseKeybind("ctrl+a>=ignore").errors.isEmpty)
        XCTAssertTrue(parseKeybind("ctrl+KeyA=ignore").errors.isEmpty)
    }

    func testRepeatedImportDoesNotDuplicateKeybinds() {
        let service = ConfigService()
        let parsed = ConfigParserService.parse("keybind = super+shift+f12=new_split:right")
        service.load(parsed: parsed)
        let first = service.array(for: .keybind)
        service.load(parsed: parsed)
        XCTAssertEqual(service.array(for: .keybind), first)
    }
    func testUnrecognizedAndRepeatedSettingsSurviveEditing() {
        let service = ConfigService()
        service.load(parsed: ConfigParserService.parse("font-family = A\nfont-family = B\nfuture-option = keep\nfuture-option = both"))
        let exported = service.stringifyConfig()
        XCTAssertTrue(exported.contains("font-family = A\nfont-family = B"))
        XCTAssertTrue(exported.contains("future-option = keep\nfuture-option = both"))
    }

    func testImportDiagnosticsAndNoPhantomChanges() {
        let parsed = ConfigParserService.inspect("invalid line\nmouse-hide-while-typing = perhaps\npalette = 256=#FFFFFF\nfont-size = nan")
        XCTAssertEqual(parsed.entryCount, 0)
        XCTAssertEqual(parsed.diagnostics.count, 4)
        XCTAssertTrue(parsed.values.isEmpty)
        let service = ConfigService()
        service.load(parsed: ConfigParserService.parse("# empty config"))
        XCTAssertTrue(service.diff().isEmpty)
    }

    func testNumericExportIsValidAndPrecise() {
        let service = ConfigService()
        service.setDouble(100, for: .windowWidth)
        service.setDouble(1.7, for: .minimumContrast)
        let output = service.stringifyConfig()
        XCTAssertTrue(output.contains("window-width = 100\n") || output.hasSuffix("window-width = 100"))
        XCTAssertTrue(output.contains("minimum-contrast = 1.7"))
        XCTAssertFalse(output.contains("100.0"))
    }

    func testDeletingDefaultKeybindExportsUnbind() {
        let service = ConfigService()
        var bindings = service.array(for: .keybind)
        let removed = bindings.removeFirst()
        service.set(bindings, for: .keybind)
        let trigger = parseKeybind(removed).trigger!
        XCTAssertTrue(service.stringifyConfig().contains("keybind = \(formatTrigger(trigger))=unbind"))
    }

    func testClearKeybindImportExportsAllFollowingEntries() {
        let service = ConfigService()
        service.load(parsed: ConfigParserService.parse("keybind = clear\nkeybind = super+c=copy_to_clipboard"))
        XCTAssertEqual(service.array(for: .keybind).count, 2)
        let exported = service.stringifyConfig()
        XCTAssertTrue(exported.contains("keybind = clear\nkeybind = super+c=copy_to_clipboard"))
    }

    func testWebShareUnicodeRoundTripAndEncodedLengthLimit() throws {
        let text = "font-family = 中文字体\nfont-size = 14.5"
        let payload = ShareService.encodeConfig(text)
        let url = try ShareService.buildShareUrl(encodedConfig: payload).get()
        XCTAssertEqual(try ShareService.extractConfigFromURL(url).flatMap(ShareService.decodeConfig).get(), text)
        let nativeURL = URL(string: "ghosttyconfig:?share=\(payload)")!
        XCTAssertEqual(try ShareService.extractConfigFromURL(nativeURL).flatMap(ShareService.decodeConfig).get(), text)
        let expanded = ShareService.encodeConfig(String(repeating: "字", count: 600))
        if case .success = ShareService.buildShareUrl(encodedConfig: expanded) { XCTFail("Encoded URL exceeds limit") }
    }

    func testRegistryHasEveryMacOSWebSettingAndMetadata() {
        XCTAssertEqual(PanelRegistry.settings.count, 181)
        XCTAssertEqual(PanelRegistry.settings[.macosOptionAsAlt]?.allowEmpty, true)
        XCTAssertNotNil(PanelRegistry.settings[.fontFamily]?.schemaDescription)
        XCTAssertNotNil(PanelRegistry.settings[.quickTerminalPosition])
        XCTAssertTrue(ConfigService().diff().isEmpty)
    }

    func testChainedActionsKeepTheirParentWhenExportedAndReimported() {
        let service = ConfigService()
        let source = "keybind = super+shift+f12=new_tab\nkeybind = chain=copy_to_clipboard"
        service.load(parsed: ConfigParserService.parse(source))
        let exported = service.stringifyConfig()
        XCTAssertTrue(exported.contains("keybind = clear"))
        XCTAssertTrue(exported.contains(source))
        service.load(parsed: ConfigParserService.parse(source))
        XCTAssertEqual(service.stringifyConfig(), exported)
        let copy = ConfigService()
        copy.load(parsed: ConfigParserService.parse(exported))
        XCTAssertEqual(copy.stringifyConfig(), exported)
    }

    func testPaddedSharePayloadIsNotDoubleEscaped() throws {
        let url = try ShareService.buildShareUrl(encodedConfig: "dGVzdA==").get()
        XCTAssertEqual(try ShareService.extractConfigFromURL(url).flatMap(ShareService.decodeConfig).get(), "test")
    }

}
