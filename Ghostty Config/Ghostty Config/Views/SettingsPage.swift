// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Settings Page

struct SettingFocus: Equatable {
    let id = UUID()
    let key: ConfigKey
}

struct SettingsPage: View {
    let panel: SettingsPanel
    var focusTarget: SettingFocus? = nil
    @State private var highlighted: ConfigKey?
    @Environment(\.configService) private var configService
    private let maxContentWidth: CGFloat = 780

    var body: some View {
        ScrollViewReader { proxy in
            PageView(title: panel.name) {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(panel.groups) { group in settingsGroup(group: group) }
                }
                .padding(20)
                .frame(maxWidth: maxContentWidth, alignment: .leading)
            }
            .task(id: focusTarget) {
                guard let target = focusTarget, panel.groups.flatMap(\.settings).contains(where: { $0.configKey == target.key }) else { return }
                await Task.yield()
                withAnimation { proxy.scrollTo(target.key, anchor: .center); highlighted = target.key }
                try? await Task.sleep(for: .seconds(2))
                if !Task.isCancelled { withAnimation { highlighted = nil } }
            }
        }
    }

    @ViewBuilder
    private func settingsGroup(group: SettingGroup) -> some View {
        GroupBox {
            VStack(spacing: 0) {
                // Preview components
                if group.preview == "baseColor" {
                    BaseColorPreview()
                        .padding(.bottom, 12)
                    Divider()
                } else if group.preview == "cursor" {
                    CursorPreview()
                        .padding(.bottom, 12)
                    Divider()
                } else if group.preview == "palette" {
                    PalettePreview()
                        .padding(.bottom, 12)
                    Divider()
                } else if group.preview == "appIcon" {
                    AppIconPreview()
                        .padding(.bottom, 12)
                    Divider()
                }

                // Settings
                ForEach(Array(group.settings.enumerated()), id: \.element.id) { index, setting in
                    if index != 0 {
                        Divider()
                    }
                    SettingItemView(setting: setting)
                        .id(setting.configKey)
                        .background(highlighted == setting.configKey ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                if !group.name.isEmpty {
                    Text(group.name)
                        .font(.headline)
                }
                if let note = group.note, !note.isEmpty {
                    Text(HTMLStripper.strip(note))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.regular)
                }
            }
        }
    }
}
