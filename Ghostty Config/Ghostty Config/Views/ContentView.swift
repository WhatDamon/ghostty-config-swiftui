// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @State private var navigation = NavigationHistory()
    @Environment(\.configService) private var configService
    @Environment(\.toastService) private var toastService
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchQuery = ""
    private var searchResults: [SearchResult] { matchingSettings(query: searchQuery) }
    @State private var focusTarget: SettingFocus?

    private let panels = PanelRegistry.all

    private var selectedPanel: String { navigation.current.panelID }

    private var sidebarSelection: Binding<String?> {
        Binding(get: { selectedPanel }, set: { panelID in
            guard let panelID else { return }
            // Re-selecting the visible category is not a new page visit, including
            // after a search has positioned us at one of its settings.
            guard panelID != selectedPanel else { return }
            navigate(to: NavigationDestination(panelID: panelID))
        })
    }

    private var pageTitle: String {
        switch selectedPanel {
        case "home": "Ghostty Config"
        case "import-export": "Import & Export"
        case "font-playground": "Font Playground"
        default: panels.first { $0.panelId == selectedPanel }?.name ?? "Ghostty Config"
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedPanel: sidebarSelection,
                searchQuery: $searchQuery,
                searchResults: searchResults,
                panels: panels,
                onSelect: { result in
                    navigate(to: NavigationDestination(panelID: result.categoryId, settingKey: result.settingKey))
                }
            )
            .frame(minWidth: 220)
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            DetailView(selectedPanel: selectedPanel, panels: panels, focusTarget: focusTarget)
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button(action: goBack) {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .disabled(!navigation.canGoBack)
                        .help("Go Back (⌘[)")
                        .keyboardShortcut("[", modifiers: .command)
                        .accessibilityIdentifier("navigation-back")

                        Button(action: goForward) {
                            Label("Forward", systemImage: "chevron.right")
                        }
                        .disabled(!navigation.canGoForward)
                        .help("Go Forward (⌘])")
                        .keyboardShortcut("]", modifiers: .command)
                        .accessibilityIdentifier("navigation-forward")
                    }
                    ToolbarItem(placement: .navigation) {
                        Text(pageTitle)
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
        }
        .onOpenURL { url in
            switch ShareService.extractConfigFromURL(url).flatMap(ShareService.decodeConfig) {
            case .success(let text):
                configService.pendingImportText = text
                navigate(to: NavigationDestination(panelID: "import-export"))
            case .failure(let error): toastService.error(error.localizedDescription)
            }
        }
        .onChange(of: colorScheme, initial: true) { _, scheme in configService.systemIsLight = scheme == .light }
        .overlay(alignment: .bottom) {
            ToastStack()
        }
    }

    // MARK: - Navigation

    private func navigate(to destination: NavigationDestination) {
        navigation.visit(destination)
        restoreDestination()
    }

    private func goBack() {
        guard navigation.canGoBack else { return }
        navigation.goBack()
        restoreDestination()
    }

    private func goForward() {
        guard navigation.canGoForward else { return }
        navigation.goForward()
        restoreDestination()
    }

    private func restoreDestination() {
        searchQuery = ""
        // A fresh focus token also retriggers a repeated search for the same row.
        focusTarget = navigation.current.settingKey.map { SettingFocus(key: $0) }
    }

    // MARK: - Search

    struct SearchResult: Identifiable {
        var id: String { "\(categoryId):\(settingKey.rawValue)" }
        let settingKey: ConfigKey
        let categoryId: String
        let categoryName: String
        let groupName: String
        let settingName: String
    }

    private func matchingSettings(query: String) -> [SearchResult] {
        let tokens = query.lowercased().split(whereSeparator: { $0.isWhitespace })
        guard !tokens.isEmpty else {
            return []
        }

        var results: [SearchResult] = []
        for panel in panels {
            for group in panel.groups {
                for setting in group.settings {
                    let searchText = "\(panel.name) \(group.name) \(setting.name) \(setting.configKey.rawValue) \(setting.note ?? "")".lowercased()
                    if tokens.allSatisfy({ searchText.contains($0) }) {
                        results.append(SearchResult(
                            settingKey: setting.configKey,
                            categoryId: panel.panelId,
                            categoryName: panel.name,
                            groupName: group.name,
                            settingName: setting.name
                        ))
                    }
                }
            }
        }
        return results
    }
}

// MARK: - Sidebar

private struct SidebarView: View {
    @Binding var selectedPanel: String?
    @Binding var searchQuery: String
    let searchResults: [ContentView.SearchResult]
    let panels: [SettingsPanel]
    let onSelect: (ContentView.SearchResult) -> Void

    var body: some View {
        List(selection: $selectedPanel) {
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Ghostty Config") { sidebarRow(title: "Home", icon: "house", tag: "home") }
                Section("Settings") {
                    ForEach(panels) { panel in
                        sidebarRow(title: panel.name, icon: iconForPanel(panel.panelId), tag: panel.panelId)
                    }
                }
                Section("Tools") {
                    sidebarRow(title: "Import & Export", icon: "arrow.triangle.2.circlepath", tag: "import-export")
                    sidebarRow(title: "Font Playground", icon: "textformat", tag: "font-playground")
                }
                Section("Links") {
                    linkButton(title: "Upstream Web", icon: "star", url: "https://github.com/zerebos/ghostty-config")
                    linkButton(title: "Native Port", icon: "chevron.left.forwardslash.chevron.right", url: "https://github.com/WhatDamon/ghostty-config-swiftui")
                    linkButton(title: "Ghostty", icon: "terminal", url: "https://ghostty.org")
                }
            } else {
                Section("Search Results") {
                    if searchResults.isEmpty {
                        Text("No matching settings").foregroundStyle(.secondary)
                    }
                    ForEach(searchResults) { result in
                        Button { onSelect(result) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.settingName)
                                Text(result.groupName.isEmpty ? result.categoryName : "\(result.categoryName) · \(result.groupName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchQuery, placement: .sidebar, prompt: "Search Settings…")
        .onSubmit(of: .search) {
            if let first = searchResults.first { onSelect(first) }
        }
    }

    private func sidebarRow(title: String, icon: String, tag: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .frame(width: 22, alignment: .center)
            Text(title)
        }
        .tag(tag)
    }

    private func linkButton(title: String, icon: String, url: String) -> some View {
        Button {
            NSWorkspace.shared.open(URL(string: url)!)
        } label: {
            Label(title, systemImage: icon)
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }
}

// MARK: - Detail

private struct DetailView: View {
    let selectedPanel: String?
    let panels: [SettingsPanel]
    let focusTarget: SettingFocus?

    var body: some View {
        switch selectedPanel {
        case "home":
            HomePage()
        case "import-export":
            ImportExportPage()
        case "font-playground":
            FontPlaygroundPage()
        case let panelId?:
            if let panel = panels.first(where: { $0.panelId == panelId }) {
                SettingsPage(panel: panel, focusTarget: focusTarget).id(panel.panelId)
            } else {
                Text("Unknown page")
                    .foregroundStyle(.secondary)
            }
        case nil:
            Text("Select a category")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Icon Mapping

private func iconForPanel(_ id: String) -> String {
    switch id {
    case "application": return "app.badge"
    case "terminal": return "terminal"
    case "clipboard": return "clipboard"
    case "window": return "macwindow"
    case "colors": return "paintpalette"
    case "fonts": return "textformat"
    case "keybinds": return "keyboard"
    case "mouse": return "computermouse"
    case "macos": return "apple.logo"
    default: return "gearshape"
    }
}
