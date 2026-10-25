// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

// MARK: - Strongly-typed Configuration Keys

enum ConfigKey: String, CaseIterable, Codable, Hashable {
    // Fonts
    case fontFamily = "font-family"
    case fontFamilyBold = "font-family-bold"
    case fontFamilyItalic = "font-family-italic"
    case fontFamilyBoldItalic = "font-family-bold-italic"
    case fontSize = "font-size"
    case fontFeature = "font-feature"
    case fontThicken = "font-thicken"
    case fontThickenStrength = "font-thicken-strength"

    // Theme & Colors
    case theme
    case background
    case foreground
    case palette
    case paletteGenerate = "palette-generate"
    case paletteHarmonious = "palette-harmonious"
    case boldColor = "bold-color"
    case minimumContrast = "minimum-contrast"

    // Selection
    case selectionForeground = "selection-foreground"
    case selectionBackground = "selection-background"
    case selectionClearOnTyping = "selection-clear-on-typing"
    case selectionClearOnCopy = "selection-clear-on-copy"

    // Search
    case searchForeground = "search-foreground"
    case searchBackground = "search-background"
    case searchSelectedForeground = "search-selected-foreground"
    case searchSelectedBackground = "search-selected-background"

    // Cursor
    case cursorColor = "cursor-color"
    case cursorText = "cursor-text"
    case cursorStyle = "cursor-style"
    case cursorStyleBlink = "cursor-style-blink"
    case cursorOpacity = "cursor-opacity"
    case cursorClickToMove = "cursor-click-to-move"

    // Mouse
    case mouseHideWhileTyping = "mouse-hide-while-typing"
    case mouseShiftCapture = "mouse-shift-capture"
    case mouseReporting = "mouse-reporting"
    case mouseScrollMultiplier = "mouse-scroll-multiplier"

    // Window
    case windowPaddingX = "window-padding-x"
    case windowPaddingY = "window-padding-y"
    case windowPaddingBalance = "window-padding-balance"
    case windowPaddingColor = "window-padding-color"
    case backgroundOpacity = "background-opacity"
    case backgroundBlur = "background-blur"
    case windowTheme = "window-theme"
    case windowDecoration = "window-decoration"
    case windowVsync = "window-vsync"
    case windowStepResize = "window-step-resize"
    case windowSaveState = "window-save-state"
    case windowNewTabPosition = "window-new-tab-position"
    case windowTitleFontFamily = "window-title-font-family"
    case windowColorspace = "window-colorspace"
    case windowHeight = "window-height"
    case windowWidth = "window-width"
    case windowPositionX = "window-position-x"
    case windowPositionY = "window-position-y"
    case windowInheritWorkingDirectory = "window-inherit-working-directory"
    case tabInheritWorkingDirectory = "tab-inherit-working-directory"
    case splitInheritWorkingDirectory = "split-inherit-working-directory"
    case windowInheritFontSize = "window-inherit-font-size"
    case windowSubtitle = "window-subtitle"
    case windowTitlebarBackground = "window-titlebar-background"
    case windowTitlebarForeground = "window-titlebar-foreground"
    case resizeOverlay = "resize-overlay"
    case resizeOverlayPosition = "resize-overlay-position"
    case resizeOverlayDuration = "resize-overlay-duration"

    // Background Image
    case backgroundImage = "background-image"
    case backgroundImageOpacity = "background-image-opacity"
    case backgroundImagePosition = "background-image-position"
    case backgroundImageFit = "background-image-fit"
    case backgroundImageRepeat = "background-image-repeat"

    // Application
    case title
    case keybind
    case link = "link"
    case linkUrl = "link-url"
    case linkPreviews = "link-previews"
    case configFile = "config-file"
    case configDefaultFiles = "config-default-files"
    case shellIntegration = "shell-integration"
    case shellIntegrationFeatures = "shell-integration-features"
    case term = "term"

    // Clipboard
    case clipboardRead = "clipboard-read"
    case clipboardWrite = "clipboard-write"
    case copyOnSelect = "copy-on-select"
    case clipboardTrimTrailingSpaces = "clipboard-trim-trailing-spaces"
    case clipboardPasteProtection = "clipboard-paste-protection"
    case clipboardPasteBracketedSafe = "clipboard-paste-bracketed-safe"
    case clipboardCodepointMap = "clipboard-codepoint-map"

    // macOS Icon
    case macosIcon = "macos-icon"
    case macosIconGhostColor = "macos-icon-ghost-color"
    case macosIconScreenColor = "macos-icon-screen-color"
    case macosIconFrame = "macos-icon-frame"

    // Other
    case command
    case initialCommand = "initial-command"
    case env = "env"
    case maximize
    case fullscreen
    case quitAfterLastWindowClosed = "quit-after-last-window-closed"
    case confirmCloseSurface = "confirm-close-surface"
    case initialWindow = "initial-window"
    case undoTimeout = "undo-timeout"
    case waitAfterCommand = "wait-after-command"
    case scrollbackLimit = "scrollback-limit"
    case scrollbar
    case workingDirectory = "working-directory"

    // Additional settings synchronized from the Web implementation.
    case abnormalCommandExitRuntime = "abnormal-command-exit-runtime"
    case adjustBoxThickness = "adjust-box-thickness"
    case adjustCellHeight = "adjust-cell-height"
    case adjustCellWidth = "adjust-cell-width"
    case adjustCursorHeight = "adjust-cursor-height"
    case adjustCursorThickness = "adjust-cursor-thickness"
    case adjustFontBaseline = "adjust-font-baseline"
    case adjustIconHeight = "adjust-icon-height"
    case adjustOverlinePosition = "adjust-overline-position"
    case adjustOverlineThickness = "adjust-overline-thickness"
    case adjustStrikethroughPosition = "adjust-strikethrough-position"
    case adjustStrikethroughThickness = "adjust-strikethrough-thickness"
    case adjustUnderlinePosition = "adjust-underline-position"
    case adjustUnderlineThickness = "adjust-underline-thickness"
    case alphaBlending = "alpha-blending"
    case autoUpdate = "auto-update"
    case autoUpdateChannel = "auto-update-channel"
    case backgroundOpacityCells = "background-opacity-cells"
    case bellAudioPath = "bell-audio-path"
    case bellAudioVolume = "bell-audio-volume"
    case bellFeatures = "bell-features"
    case clickRepeatInterval = "click-repeat-interval"
    case customShader = "custom-shader"
    case customShaderAnimation = "custom-shader-animation"
    case desktopNotifications = "desktop-notifications"
    case enquiryResponse = "enquiry-response"
    case faintOpacity = "faint-opacity"
    case focusFollowsMouse = "focus-follows-mouse"
    case fontCodepointMap = "font-codepoint-map"
    case fontShapingBreak = "font-shaping-break"
    case fontStyle = "font-style"
    case fontStyleBold = "font-style-bold"
    case fontStyleBoldItalic = "font-style-bold-italic"
    case fontStyleItalic = "font-style-italic"
    case fontSyntheticStyle = "font-synthetic-style"
    case fontVariation = "font-variation"
    case fontVariationBold = "font-variation-bold"
    case fontVariationBoldItalic = "font-variation-bold-italic"
    case fontVariationItalic = "font-variation-italic"
    case freetypeLoadFlags = "freetype-load-flags"
    case graphemeWidthMethod = "grapheme-width-method"
    case imageStorageLimit = "image-storage-limit"
    case input = "input"
    case macosApplescript = "macos-applescript"
    case macosAutoSecureInput = "macos-auto-secure-input"
    case macosCustomIcon = "macos-custom-icon"
    case macosDockDropBehavior = "macos-dock-drop-behavior"
    case macosHidden = "macos-hidden"
    case macosNonNativeFullscreen = "macos-non-native-fullscreen"
    case macosOptionAsAlt = "macos-option-as-alt"
    case macosSecureInputIndication = "macos-secure-input-indication"
    case macosShortcuts = "macos-shortcuts"
    case macosTitlebarProxyIcon = "macos-titlebar-proxy-icon"
    case macosTitlebarStyle = "macos-titlebar-style"
    case macosWindowButtons = "macos-window-buttons"
    case macosWindowShadow = "macos-window-shadow"
    case middleClickAction = "middle-click-action"
    case notifyOnCommandFinish = "notify-on-command-finish"
    case notifyOnCommandFinishAction = "notify-on-command-finish-action"
    case notifyOnCommandFinishAfter = "notify-on-command-finish-after"
    case oscColorReportFormat = "osc-color-report-format"
    case progressStyle = "progress-style"
    case quickTerminalAnimationDuration = "quick-terminal-animation-duration"
    case quickTerminalAutohide = "quick-terminal-autohide"
    case quickTerminalKeyboardInteractivity = "quick-terminal-keyboard-interactivity"
    case quickTerminalPosition = "quick-terminal-position"
    case quickTerminalScreen = "quick-terminal-screen"
    case quickTerminalSize = "quick-terminal-size"
    case quickTerminalSpaceBehavior = "quick-terminal-space-behavior"
    case quitAfterLastWindowClosedDelay = "quit-after-last-window-closed-delay"
    case rightClickAction = "right-click-action"
    case scrollToBottom = "scroll-to-bottom"
    case selectionWordChars = "selection-word-chars"
    case splitDividerColor = "split-divider-color"
    case splitPreserveZoom = "split-preserve-zoom"
    case titleReport = "title-report"
    case unfocusedSplitFill = "unfocused-split-fill"
    case unfocusedSplitOpacity = "unfocused-split-opacity"
    case vtKamAllowed = "vt-kam-allowed"
    case windowShowTabBar = "window-show-tab-bar"

    case appNotifications = "app-notifications"
    case asyncBackend = "async-backend"
    case `class` = "class"
    case gtkCustomCss = "gtk-custom-css"
    case gtkOpenglDebug = "gtk-opengl-debug"
    case gtkQuickTerminalLayer = "gtk-quick-terminal-layer"
    case gtkQuickTerminalNamespace = "gtk-quick-terminal-namespace"
    case gtkSingleInstance = "gtk-single-instance"
    case gtkTabsLocation = "gtk-tabs-location"
    case gtkTitlebar = "gtk-titlebar"
    case gtkTitlebarHideWhenMaximized = "gtk-titlebar-hide-when-maximized"
    case gtkTitlebarStyle = "gtk-titlebar-style"
    case gtkToolbarStyle = "gtk-toolbar-style"
    case gtkWideTabs = "gtk-wide-tabs"
    case language = "language"
    case linuxCgroup = "linux-cgroup"
    case linuxCgroupHardFail = "linux-cgroup-hard-fail"
    case linuxCgroupMemoryLimit = "linux-cgroup-memory-limit"
    case linuxCgroupProcessesLimit = "linux-cgroup-processes-limit"
    case x11InstanceName = "x11-instance-name"

    case unknown = ""

    init(rawValue: String) {
        self = ConfigKey.allCases.first { $0.rawValue == rawValue } ?? .unknown
    }

    var camelCase: String {
        let parts = rawValue.split(separator: "-")
        guard let first = parts.first else { return "" }
        var result = String(first)
        for part in parts.dropFirst() {
            result += part.prefix(1).uppercased() + part.dropFirst()
        }
        return result
    }
}
