// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct GhosttyConfigApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var configService = ConfigService()
    @State private var toastService = ToastService()
    @State private var showLegalNotices = false

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.configService, configService)
                .environment(\.toastService, toastService)
                .frame(minWidth: 900, minHeight: 600)
                .background(AppWindowConfiguration())
                .sheet(isPresented: $showLegalNotices) { LegalNoticesView() }
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appInfo) {
                Button("About Ghostty Config") { AppAttribution.showAbout() }
                Button("Licenses & Credits…") { showLegalNotices = true }
            }
        }
    }
}
