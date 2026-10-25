// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation
import SwiftUI

// MARK: - Color Utilities

typealias RgbArray = (UInt8, UInt8, UInt8)
typealias HsvArray = (hue: Double, saturation: Double, value: Double)

func luminosity(of hex: String) -> Double {
    let hexStr = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard hexStr.count == 6 else { return 0 }
    let rgb = hexToRgb(hex)
    return 0.2126 * Double(rgb.0) + 0.7152 * Double(rgb.1) + 0.0722 * Double(rgb.2)
}

func isDark(_ hex: String) -> Bool {
    luminosity(of: hex) < 128
}

func hsvToRgb(hue: Double, saturation: Double, value: Double) -> RgbArray {
    let sectorIndex = Int(hue * 6)
    let fractionalOffset = hue * 6 - Double(sectorIndex)
    let shadowVal = value * (1 - saturation)
    let quarterVal = value * (1 - fractionalOffset * saturation)
    let threeQuarterVal = value * (1 - (1 - fractionalOffset) * saturation)

    let (red, green, blue): (Double, Double, Double)
    switch sectorIndex % 6 {
    case 0: (red, green, blue) = (value, threeQuarterVal, shadowVal)
    case 1: (red, green, blue) = (quarterVal, value, shadowVal)
    case 2: (red, green, blue) = (shadowVal, value, threeQuarterVal)
    case 3: (red, green, blue) = (shadowVal, quarterVal, value)
    case 4: (red, green, blue) = (threeQuarterVal, shadowVal, value)
    default: (red, green, blue) = (value, shadowVal, quarterVal)
    }

    return (UInt8(red * 255), UInt8(green * 255), UInt8(blue * 255))
}

func rgbToHsv(red: UInt8, green: UInt8, blue: UInt8) -> HsvArray {
    let redNorm = Double(red) / 255
    let greenNorm = Double(green) / 255
    let blueNorm = Double(blue) / 255
    let cMax = max(redNorm, greenNorm, blueNorm)
    let cMin = min(redNorm, greenNorm, blueNorm)
    let delta = cMax - cMin

    var hue: Double = 0
    if delta != 0 {
        if redNorm == cMax {
            hue = 60 * (((greenNorm - blueNorm) / delta).truncatingRemainder(dividingBy: 6)) / 360
        } else if greenNorm == cMax {
            hue = 60 * (((blueNorm - redNorm) / delta) + 2) / 360
        } else {
            hue = 60 * (((redNorm - greenNorm) / delta) + 4) / 360
        }
        if hue < 0 { hue += 1.0 }
    }

    let saturation = cMax == 0 ? 0 : delta / cMax
    return (hue, saturation, cMax)
}

func rgbToHex(red: UInt8, green: UInt8, blue: UInt8) -> String {
    String(format: "#%02X%02X%02X", red, green, blue)
}

func hexToRgb(_ hex: String) -> RgbArray {
    let hexStr = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard hexStr.count == 6 else { return (0, 0, 0) }
    let scanner = Scanner(string: hexStr)
    var intValue: UInt64 = 0
    scanner.scanHexInt64(&intValue)
    return (UInt8((intValue >> 16) & 0xFF), UInt8((intValue >> 8) & 0xFF), UInt8(intValue & 0xFF))
}

func hexToColor(_ hex: String) -> Color {
    let rgb = hexToRgb(hex)
    return Color(red: Double(rgb.0) / 255, green: Double(rgb.1) / 255, blue: Double(rgb.2) / 255)
}

func isValidHex(_ hex: String) -> Bool {
    let hexStr = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard hexStr.count == 6 else { return false }
    return hexStr.allSatisfy { $0.isHexDigit }
}

func readableTextColor(for hex: String) -> Color {
    isDark(hex) ? .white : .black
}
