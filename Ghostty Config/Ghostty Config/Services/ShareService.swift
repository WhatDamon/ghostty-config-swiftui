// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

// MARK: - Share Service Errors

enum ShareServiceError: LocalizedError, Equatable {
    case encodingFailed
    case decodingFailed
    case configTooLong(Int, limit: Int)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .encodingFailed: "Failed to encode config"
        case .decodingFailed: "Failed to decode config"
        case .configTooLong(let length, let limit): "Config is \(length) characters, exceeds \(limit) character limit"
        case .invalidURL: "Could not create share URL"
        }
    }
}

// MARK: - Share Service

struct ShareService {
    static let shareHashKey = "share"
    static let maxShareUrlLength = 1800

    static func encodeConfig(_ config: String) -> String {
        let data = Data(config.utf8)
        let base64 = data.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func decodeConfig(_ encoded: String) -> Result<String, ShareServiceError> {
        var normalized = encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = normalized.count % 4
        if remainder != 0 {
            normalized += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: normalized),
              let decoded = String(data: data, encoding: .utf8) else {
            return .failure(.decodingFailed)
        }
        return .success(decoded)
    }

    static func buildShareUrl(encodedConfig: String) -> Result<URL, ShareServiceError> {
        var components = URLComponents(string: "https://ghostty.zerebos.com/app/import-export")!
        var payload = URLComponents()
        payload.queryItems = [URLQueryItem(name: shareHashKey, value: encodedConfig)]
        components.percentEncodedFragment = payload.percentEncodedQuery
        guard let url = components.url else {
            return .failure(.invalidURL)
        }
        guard url.absoluteString.count <= maxShareUrlLength else {
            return .failure(.configTooLong(url.absoluteString.count, limit: maxShareUrlLength))
        }
        return .success(url)
    }

    static func extractConfigFromURL(_ url: URL) -> Result<String, ShareServiceError> {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              ["https", "http", "ghosttyconfig"].contains(components.scheme ?? "") else { return .failure(.invalidURL) }
        var fragment = URLComponents()
        fragment.percentEncodedQuery = components.percentEncodedFragment
        guard let value = (fragment.queryItems ?? components.queryItems ?? []).first(where: { $0.name == shareHashKey })?.value,
              !value.isEmpty else { return .failure(.invalidURL) }
        return .success(value)
    }
}
