// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Home Page

struct HomePage: View {
    @State private var showLegalNotices = false

    var body: some View {
        PageView(title: "Ghostty Config") {
            VStack(alignment: .leading, spacing: 20) {
                logoSection
                noticeSection
                recentChangesSection
                roadmapSection
            }
            .frame(maxWidth: 580)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .sheet(isPresented: $showLegalNotices) { LegalNoticesView() }
    }

    private var logoSection: some View {
        VStack(spacing: 8) {
            Image("ConfigLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)

            Text("Ghostty Config")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Unofficial Port")
                .font(.headline)
            Text("Native port by WhatDamon | Upstream Project by Zerebos")
                .foregroundStyle(.secondary)
            Text("Independent port; not an official release of Ghostty or the upstream Web project.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Licenses & Credits…") { showLegalNotices = true }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var noticeSection: some View {
        GroupBox {
            Label {
                Text("Please report this native app issues to its maintainer rather than the upstream project.")
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recentChangesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                ChangeRow("Updated settings from the upstream registry")
                ChangeRow("\(PanelRegistry.snapshot.themes.count) reviewed MIT themes with light and dark choices")
                ChangeRow("Theme colors and custom overrides remain separate")
                ChangeRow("Native editors for lists, units, durations, and feature sets")
                ChangeRow("Settings can now be searched in the sidebar like on macOS")
                ChangeRow("Help documentation for individual settings")
                ChangeRow("Individual settings can now be reset to default")
                ChangeRow("New version badges showing when a setting was added")
                ChangeRow("New platform badges showing valid platforms")
                ChangeRow("New keybind builder with sequence support")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        } label: {
            Text("Recent Changes")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var roadmapSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                RoadmapRow("Command palette builder")
                RoadmapRow("Remember unfinished configuration between launches")
                RoadmapRow("Optional GTK and Linux configuration pages")
                RoadmapRow("Broader macOS version and accessibility testing")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        } label: {
            Text("Roadmap")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - List Rows

private struct ChangeRow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RoadmapRow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "circle")
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
