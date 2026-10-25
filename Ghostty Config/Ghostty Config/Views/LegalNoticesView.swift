// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Damon Lu (@WhatDamon)

import SwiftUI

struct LegalNoticesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Licenses & Credits").font(.title2)
            Text(AppAttribution.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView {
                Text(AppAttribution.legalText)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(Color(.textBackgroundColor))
            .accessibilityIdentifier("legal-notices")
            HStack {
                Link("Original Web Project", destination: URL(string: "https://github.com/zerebos/ghostty-config")!)
                Link("SwiftUI Project", destination: URL(string: "https://github.com/WhatDamon/ghostty-config-swiftui")!)
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(minWidth: 620, idealWidth: 760, minHeight: 480, idealHeight: 600)
    }
}

/// Branding is explicit about the independent port; legal notices are bundled
/// so source and binary recipients both receive the complete third-party texts.
enum AppAttribution {
    static let summary = "Unofficial SwiftUI port by Damon Lu (@WhatDamon). Original Web project by Zerebos. This independent app is not an official release of Ghostty or the upstream Web project."

    static var legalText: String {
        guard let url = Bundle.main.url(forResource: "LegalNotices", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "License resource unavailable. Consult LICENSE, NOTICE and THIRD_PARTY_NOTICES.md in the source distribution."
        }
        return text
    }

    static func showAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "Ghostty Config",
            .credits: NSAttributedString(string: summary + "\n\nApache-2.0 native project; bundled third-party materials retain their own licenses. See Licenses & Credits… in the application menu.")
        ])
    }
}
