// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

struct RangeSettingView: View {
    let configKey: ConfigKey
    let minValue: Double
    let maxValue: Double
    let step: Double
    let showLabels: Bool
    @Environment(\.configService) private var configService

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                Slider(value: Binding(
                    get: { min(maxValue, max(minValue, configService.double(for: configKey))) },
                    set: { value in
                        let stepped = minValue + ((value - minValue) / step).rounded() * step
                        configService.setDouble((stepped * 10000).rounded() / 10000, for: configKey)
                    }
                ), in: minValue...maxValue)
                .accessibilityLabel(configKey.rawValue)
                Text(configService.double(for: configKey), format: .number.precision(.fractionLength(0...2)))
                    .monospacedDigit()
                    .font(.callout)
                    .frame(width: 44, alignment: .trailing)
            }
            if showLabels {
                HStack {
                    Text(minValue, format: .number)
                    Spacer()
                    Text(maxValue, format: .number)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .frame(width: 220)
    }
}
