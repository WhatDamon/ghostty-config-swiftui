import SwiftUI
import XCTest
@testable import Ghostty_Config

@MainActor
final class GhosttyConfigTests: XCTestCase {

    // MARK: - ColorValue Tests

    func testColorValueInit() {
        let cv = ColorValue(hex: "#282C34")
        XCTAssertNotNil(cv)
        XCTAssertEqual(cv?.red, 0x28)
        XCTAssertEqual(cv?.green, 0x2C)
        XCTAssertEqual(cv?.blue, 0x34)
        XCTAssertEqual(cv?.hexString, "#282C34")
    }

    func testColorValueInvalidHex() {
        XCTAssertNil(ColorValue(hex: "invalid"))
        XCTAssertNil(ColorValue(hex: "#XYZ"))
        XCTAssertNil(ColorValue(hex: ""))
        XCTAssertNil(ColorValue(hex: "#12345"))
    }

    func testColorValueHexWithoutHash() {
        let cv = ColorValue(hex: "FF0000")
        XCTAssertNotNil(cv)
        XCTAssertEqual(cv?.hexString, "#FF0000")
    }

    func testColorValueLuminosity() {
        let white = ColorValue(hex: "#FFFFFF")!
        let black = ColorValue(hex: "#000000")!
        let gray = ColorValue(hex: "#808080")!

        XCTAssertTrue(white.luminosity > 200)
        XCTAssertEqual(black.luminosity, 0)
        XCTAssertFalse(white.isDark)
        XCTAssertTrue(black.isDark)
        XCTAssertEqual(gray.luminosity, 128, accuracy: 0.5)
    }

    func testColorValueEquality() {
        let hexColor = ColorValue(hex: "#FF0000")
        let rgbColor = ColorValue(red: 255, green: 0, blue: 0)
        XCTAssertEqual(hexColor, rgbColor)
    }

    // MARK: - ConfigKey Tests

    func testConfigKeyRawValue() {
        XCTAssertEqual(ConfigKey(rawValue: "font-size"), .fontSize)
        XCTAssertEqual(ConfigKey(rawValue: "background"), .background)
        XCTAssertEqual(ConfigKey(rawValue: "cursor-style"), .cursorStyle)
        XCTAssertEqual(ConfigKey(rawValue: "nonexistent"), .unknown)
    }

    func testConfigKeyCamelCase() {
        XCTAssertEqual(ConfigKey.fontSize.camelCase, "fontSize")
        XCTAssertEqual(ConfigKey.fontFamilyBold.camelCase, "fontFamilyBold")
        XCTAssertEqual(ConfigKey.background.camelCase, "background")
        XCTAssertEqual(ConfigKey.selectionBackground.camelCase, "selectionBackground")
    }

    // MARK: - ConfigParserService Tests

    func testParseSimpleConfig() {
        let input = """
        font-size = 14
        background = #282c34
        foreground = #ffffff
        """
        let result = ConfigParserService.parse(input)
        XCTAssertEqual(result["fontSize"], .scalar("14"))
        XCTAssertEqual(result["background"], .scalar("#282C34"))
        XCTAssertEqual(result["foreground"], .scalar("#FFFFFF"))
    }

    func testParseWithComments() {
        let input = """
        # This is a comment
        font-size = 16
        # Another comment
        theme = dark
        """
        let result = ConfigParserService.parse(input)
        XCTAssertEqual(result["fontSize"], .scalar("16"))
        XCTAssertEqual(result["theme"], .scalar("dark"))
    }

    func testParseKeybind() {
        let input = """
        keybind = super+shift+d=close_surface
        keybind = ctrl+shift+alt+key_n=new_window
        """
        let result = ConfigParserService.parse(input)
        let keybinds = result["keybind"]?.entries
        XCTAssertEqual(keybinds?.count, 2)
        XCTAssertEqual(keybinds?.first, "super+shift+d=close_surface")
    }

    func testParsePalette() {
        let input = """
        palette = 0=#000000
        palette = 1=#cc0000
        palette = 15=#ffffff
        """
        let result = ConfigParserService.parse(input)
        let palette = result["palette"]?.entries
        XCTAssertEqual(palette?.count, 256)
        XCTAssertEqual(palette?[0], "#000000")
        XCTAssertEqual(palette?[1], "#CC0000")
        XCTAssertEqual(palette?[15], "#FFFFFF")
    }

    func testParseColorWithoutHash() {
        let input = """
        background = 282c34
        """
        let result = ConfigParserService.parse(input)
        XCTAssertEqual(result["background"], .scalar("#282C34"))
    }

    func testParseNumericValues() {
        let input = """
        font-size = 13
        background-opacity = 0.85
        scrollback-limit = 10000000
        """
        let result = ConfigParserService.parse(input)
        XCTAssertEqual(result["fontSize"], .scalar("13"))
        XCTAssertEqual(result["backgroundOpacity"], .scalar("0.85"))
        XCTAssertEqual(result["scrollbackLimit"], .scalar("10000000"))
    }

    func testParseEmptyInput() {
        let result = ConfigParserService.parse("")
        XCTAssertNotNil(result)
        XCTAssertNil(result["palette"])
        XCTAssertNil(result["keybind"])
    }

    func testParseKebabToCamel() {
        let input = """
        window-padding-x = 4
        clipboard-paste-protection = true
        mouse-hide-while-typing = true
        """
        let result = ConfigParserService.parse(input)
        XCTAssertEqual(result["windowPaddingX"], .scalar("4"))
        XCTAssertEqual(result["clipboardPasteProtection"], .scalar("true"))
        XCTAssertEqual(result["mouseHideWhileTyping"], .scalar("true"))
    }

    // MARK: - HTMLStripper Tests

    func testHTMLStripper() {
        XCTAssertEqual(HTMLStripper.strip("Hello <b>World</b>"), "Hello World")
        XCTAssertEqual(HTMLStripper.strip("No HTML"), "No HTML")
        XCTAssertEqual(HTMLStripper.strip("<p>Paragraph</p>"), "Paragraph")
        XCTAssertEqual(HTMLStripper.strip(""), "")
    }

    // MARK: - ShareService Tests

    func testShareServiceEncodeDecode() {
        let original = "font-size = 14\nbackground = #282c34"
        let encoded = ShareService.encodeConfig(original)

        let decodedResult = ShareService.decodeConfig(encoded)
        switch decodedResult {
        case .success(let decoded):
            XCTAssertEqual(decoded, original)
        case .failure(let error):
            XCTFail("Decoding failed: \(error)")
        }
    }

    func testShareServiceDecodeInvalidBase64() {
        let result = ShareService.decodeConfig("!!!invalid!!!")
        switch result {
        case .success:
            XCTFail("Should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .decodingFailed)
        }
    }

    func testShareServiceBuildURL() {
        let result = ShareService.buildShareUrl(encodedConfig: "dGVzdA==")
        switch result {
        case .success(let url):
            XCTAssertEqual(url.scheme, "https")
            XCTAssertEqual(url.host, "ghostty.zerebos.com")
            XCTAssertTrue(url.absoluteString.contains("share="))
        case .failure(let error):
            XCTFail("URL building failed: \(error)")
        }
    }

    func testShareServiceMaxLength() {
        let longConfig = String(repeating: "a", count: ShareService.maxShareUrlLength + 1)
        let encoded = ShareService.encodeConfig(longConfig)
        // Base64 expands the input. The complete URL must respect the limit.
        if case .success = ShareService.buildShareUrl(encodedConfig: encoded) { XCTFail("Oversize link should be rejected") }
    }
}
