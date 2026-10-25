// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Strongly-typed Color Value

struct ColorValue: Equatable, Codable, Hashable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var hexString: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }

    var nsColor: Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }

    var luminosity: Double {
        0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue)
    }

    var isDark: Bool { luminosity < 128 }

    var readableTextColor: Color {
        isDark ? .white : .black
    }

    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init?(hex: String) {
        let hexStr = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard hexStr.count == 6, hexStr.allSatisfy({ $0.isHexDigit }) else { return nil }
        let scanner = Scanner(string: hexStr)
        var intValue: UInt64 = 0
        guard scanner.scanHexInt64(&intValue) else { return nil }
        self.red = UInt8((intValue >> 16) & 0xFF)
        self.green = UInt8((intValue >> 8) & 0xFF)
        self.blue = UInt8(intValue & 0xFF)
    }

    static let `default` = ColorValue(red: 0x28, green: 0x2C, blue: 0x34)
    static let white = ColorValue(red: 0xFF, green: 0xFF, blue: 0xFF)
    static let black = ColorValue(red: 0x00, green: 0x00, blue: 0x00)
}

// MARK: - Color + ColorValue bridging

extension Color {
    init(colorValue: ColorValue) {
        self = colorValue.nsColor
    }
}
