// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    weak var localConfigService: LocalConfigService?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let localConfigService, localConfigService.hasUnsavedChanges else { return .terminateNow }
        localConfigService.withDiscardConfirmation({ sender.reply(toApplicationShouldTerminate: true) }, cancel: { sender.reply(toApplicationShouldTerminate: false) })
        return .terminateLater
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        // AppKit can insert its own full-screen command independently of
        // SwiftUI's command groups, even for windows that cannot go full screen.
        for name in [NSMenu.didAddItemNotification, NSMenu.didChangeItemNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(menuItemsChanged(_:)), name: name, object: nil)
        }
        if let menu = NSApp.mainMenu { AppWindowConfiguration.hideFullScreenCommands(in: menu) }
    }

    @objc private func menuItemsChanged(_ notification: Notification) {
        guard let menu = notification.object as? NSMenu else { return }
        AppWindowConfiguration.hideFullScreenCommands(in: menu)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct GhosttyConfigApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var configService = ConfigService()
    @State private var toastService = ToastService()
    @State private var localConfigService = LocalConfigService()
    @State private var showLegalNotices = false

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.configService, configService)
                .environment(\.toastService, toastService)
                .environment(\.localConfigService, localConfigService)
                .frame(minWidth: 900, minHeight: 600)
                .background(AppWindowConfiguration(localConfigService: localConfigService, hasUnsavedChanges: localConfigService.hasUnsavedChanges))
                .modifier(AppWindowInteractionPolicy())
                .sheet(isPresented: $showLegalNotices) { LegalNoticesView() }
                .task {
                    localConfigService.attach(configService)
                    appDelegate.localConfigService = localConfigService
                }
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) {
                Button("Save Local Configuration") { localConfigService.save() }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(!localConfigService.isConnected || (!localConfigService.hasUnsavedChanges && localConfigService.snapshot?.existed == true))
            }
            CommandGroup(replacing: .appInfo) {
                Button("About Ghostty Config") { AppAttribution.showAbout() }
                Button("Licenses & Credits…") { showLegalNotices = true }
            }
        }
    }
}
