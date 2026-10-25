// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation

// MARK: - Keybind Parser

let validModifiers = ["shift", "ctrl", "alt", "super"]
let validPrefixes = ["all", "global", "unconsumed", "performable"]
let directionOptions = ["right", "down", "left", "up", "auto"]
let resizeDirectionOptions = ["up", "down", "left", "right"]
let inspectOptions = ["toggle", "show", "hide"]
let writeOptions = ["copy", "paste", "open", "copy,plain", "copy,vt", "copy,html",
                    "paste,plain", "paste,vt", "paste,html", "open,plain", "open,vt", "open,html"]
let gotoSplitOptions = directionOptions + ["previous", "next"]
let adjustSelectionOptions = ["left", "right", "up", "down", "page_up", "page_down",
                              "home", "end", "beginning_of_line", "end_of_line"]

let modifierAliases: [String: String] = [
    "control": "ctrl", "cmd": "super", "command": "super", "opt": "alt", "option": "alt"
]

struct ActionDefinition {
    let name: String
    let description: String?
    let type: ActionArgType
    let options: [String]?
    let allowEmpty: Bool
    let min: Int?

    init(name: String, description: String? = nil, type: ActionArgType,
         options: [String]? = nil, allowEmpty: Bool = false, min: Int? = nil) {
        self.name = name
        self.description = description
        self.type = type
        self.options = options
        self.allowEmpty = allowEmpty
        self.min = min
    }
}

enum ActionArgType {
    case none
    case number
    case integer
    case unsignedInteger
    case free
    case `enum`
    case direction
    case resize
    case text
}

struct ParsedTriggerStep {
    let key: String
    let modifiers: [String]
}

struct ParsedTrigger {
    let prefixes: [String]
    let steps: [ParsedTriggerStep]
}

struct ParsedKeybind {
    let trigger: ParsedTrigger?
    let action: String?
    let args: String?
    let errors: [String]
}

let actionDefinitions: [ActionDefinition] = [
    ActionDefinition(name: "ignore", description: "Ignore this key and do not forward it.", type: .none),
    ActionDefinition(name: "unbind", description: "Remove a previously defined keybind.", type: .none),
    ActionDefinition(name: "csi", description: "Send a CSI sequence without the ESC[ prefix.", type: .free),
    ActionDefinition(name: "esc", description: "Send a raw ESC sequence.", type: .free),
    ActionDefinition(name: "text", description: "Send literal text using Zig string literal syntax.", type: .text),
    ActionDefinition(name: "cursor_key", description: "Send cursor-key data.", type: .none),
    ActionDefinition(name: "reset", description: "Reset the terminal state.", type: .none),
    ActionDefinition(name: "copy_to_clipboard", description: "Copy selection to clipboard.", type: .enum,
                     options: ["plain", "vt", "html", "mixed"], allowEmpty: true),
    ActionDefinition(name: "paste_from_clipboard", description: "Paste from default clipboard.", type: .none),
    ActionDefinition(name: "paste_from_selection", description: "Paste from selection clipboard.", type: .none),
    ActionDefinition(name: "copy_url_to_clipboard", description: "Copy URL under cursor.", type: .none),
    ActionDefinition(name: "copy_title_to_clipboard", description: "Copy terminal title.", type: .none),
    ActionDefinition(name: "increase_font_size", description: "Increase font size.", type: .number),
    ActionDefinition(name: "decrease_font_size", description: "Decrease font size.", type: .number),
    ActionDefinition(name: "reset_font_size", description: "Reset font size to configured.", type: .none),
    ActionDefinition(name: "set_font_size", description: "Set font size to a point value.", type: .number),
    ActionDefinition(name: "search", description: "Start or replace search text.", type: .free),
    ActionDefinition(name: "search_selection", description: "Search using current selection.", type: .none),
    ActionDefinition(name: "navigate_search", description: "Jump to previous/next match.", type: .enum, options: ["previous", "next"]),
    ActionDefinition(name: "start_search", description: "Open search UI.", type: .none),
    ActionDefinition(name: "end_search", description: "End active search.", type: .none),
    ActionDefinition(name: "clear_screen", description: "Clear screen and scrollback.", type: .none),
    ActionDefinition(name: "select_all", description: "Select all terminal text.", type: .none),
    ActionDefinition(name: "scroll_to_top", description: "Scroll viewport to the top.", type: .none),
    ActionDefinition(name: "scroll_to_bottom", description: "Scroll viewport to the bottom.", type: .none),
    ActionDefinition(name: "scroll_to_selection", description: "Scroll to selection.", type: .none),
    ActionDefinition(name: "scroll_to_row", description: "Scroll to absolute row index.", type: .unsignedInteger),
    ActionDefinition(name: "scroll_page_up", description: "Scroll up by one page.", type: .none),
    ActionDefinition(name: "scroll_page_down", description: "Scroll down by one page.", type: .none),
    ActionDefinition(name: "scroll_page_fractional", description: "Scroll by fractional page.", type: .number),
    ActionDefinition(name: "scroll_page_lines", description: "Scroll by number of lines.", type: .integer),
    ActionDefinition(name: "adjust_selection", description: "Adjust current selection.", type: .enum, options: adjustSelectionOptions),
    ActionDefinition(name: "jump_to_prompt", description: "Jump by prompt count.", type: .integer),
    ActionDefinition(name: "write_scrollback_file", description: "Write scrollback to file.", type: .enum, options: writeOptions),
    ActionDefinition(name: "write_screen_file", description: "Write screen to file.", type: .enum, options: writeOptions),
    ActionDefinition(name: "write_selection_file", description: "Write selection to file.", type: .enum, options: writeOptions),
    ActionDefinition(name: "new_window", description: "Open a new window.", type: .none),
    ActionDefinition(name: "new_tab", description: "Open a new tab.", type: .none),
    ActionDefinition(name: "previous_tab", description: "Focus previous tab.", type: .none),
    ActionDefinition(name: "next_tab", description: "Focus next tab.", type: .none),
    ActionDefinition(name: "last_tab", description: "Focus last tab.", type: .none),
    ActionDefinition(name: "goto_tab", description: "Focus tab by index.", type: .unsignedInteger, min: 1),
    ActionDefinition(name: "move_tab", description: "Move tab by relative offset.", type: .integer),
    ActionDefinition(name: "toggle_tab_overview", description: "Toggle tab overview.", type: .none),
    ActionDefinition(name: "prompt_surface_title", description: "Prompt for surface title.", type: .none),
    ActionDefinition(name: "prompt_tab_title", description: "Prompt for tab title.", type: .none),
    ActionDefinition(name: "new_split", description: "Create a split.", type: .enum, options: directionOptions, allowEmpty: true),
    ActionDefinition(name: "goto_split", description: "Focus split by direction.", type: .enum, options: gotoSplitOptions),
    ActionDefinition(name: "goto_window", description: "Focus window.", type: .enum, options: ["previous", "next"]),
    ActionDefinition(name: "toggle_split_zoom", description: "Zoom/unzoom current split.", type: .none),
    ActionDefinition(name: "toggle_readonly", description: "Toggle read-only mode.", type: .none),
    ActionDefinition(name: "resize_split", description: "Resize split by direction and offset.", type: .resize),
    ActionDefinition(name: "equalize_splits", description: "Equalize split sizes.", type: .none),
    ActionDefinition(name: "reset_window_size", description: "Reset window size.", type: .none),
    ActionDefinition(name: "inspector", description: "Toggle/show/hide inspector.", type: .enum, options: inspectOptions),
    ActionDefinition(name: "show_gtk_inspector", description: "Open GTK inspector.", type: .none),
    ActionDefinition(name: "show_on_screen_keyboard", description: "Show on-screen keyboard.", type: .none),
    ActionDefinition(name: "open_config", description: "Open Ghostty config.", type: .none),
    ActionDefinition(name: "reload_config", description: "Reload config.", type: .none),
    ActionDefinition(name: "close_surface", description: "Close focused surface.", type: .none),
    ActionDefinition(name: "close_tab", description: "Close tab(s).", type: .enum, options: ["this", "other", "right"], allowEmpty: true),
    ActionDefinition(name: "close_window", description: "Close current window.", type: .none),
    ActionDefinition(name: "close_all_windows", description: "Close all windows.", type: .none),
    ActionDefinition(name: "toggle_maximize", description: "Toggle maximized state.", type: .none),
    ActionDefinition(name: "toggle_fullscreen", description: "Toggle fullscreen.", type: .none),
    ActionDefinition(name: "toggle_window_decorations", description: "Toggle window decorations.", type: .none),
    ActionDefinition(name: "toggle_window_float_on_top", description: "Toggle always-on-top.", type: .none),
    ActionDefinition(name: "toggle_secure_input", description: "Toggle secure input.", type: .none),
    ActionDefinition(name: "toggle_mouse_reporting", description: "Toggle mouse reporting.", type: .none),
    ActionDefinition(name: "toggle_command_palette", description: "Toggle command palette.", type: .none),
    ActionDefinition(name: "toggle_quick_terminal", description: "Toggle quick terminal.", type: .none),
    ActionDefinition(name: "toggle_visibility", description: "Show/hide all windows.", type: .none),
    ActionDefinition(name: "toggle_background_opacity", description: "Toggle background opacity.", type: .none),
    ActionDefinition(name: "check_for_updates", description: "Check for updates.", type: .none),
    ActionDefinition(name: "undo", description: "Undo last action.", type: .none),
    ActionDefinition(name: "redo", description: "Redo last action.", type: .none),
    ActionDefinition(name: "end_key_sequence", description: "End active key sequence.", type: .none),
    ActionDefinition(name: "activate_key_table", description: "Activate a named key table.", type: .free),
    ActionDefinition(name: "activate_key_table_once", description: "Activate key table for one use.", type: .free),
    ActionDefinition(name: "deactivate_key_table", description: "Deactivate key table.", type: .none),
    ActionDefinition(name: "deactivate_all_key_tables", description: "Deactivate all key tables.", type: .none),
    ActionDefinition(name: "quit", description: "Quit Ghostty.", type: .none),
    ActionDefinition(name: "crash", description: "Force a crash for testing.", type: .enum, options: ["main", "io", "render"])
]

let actionLookup: [String: ActionDefinition] = {
    var lookup: [String: ActionDefinition] = [:]
    for def in actionDefinitions {
        lookup[def.name] = def
    }
    return lookup
}()

let validKeys: Set<String> = {
    let keys: [String] = [
        "unidentified", "backquote", "backslash", "bracket_left", "bracket_right",
        "comma", "digit_0", "digit_1", "digit_2", "digit_3", "digit_4", "digit_5",
        "digit_6", "digit_7", "digit_8", "digit_9", "equal", "intl_backslash",
        "intl_ro", "intl_yen", "key_a", "key_b", "key_c", "key_d", "key_e", "key_f",
        "key_g", "key_h", "key_i", "key_j", "key_k", "key_l", "key_m", "key_n",
        "key_o", "key_p", "key_q", "key_r", "key_s", "key_t", "key_u", "key_v",
        "key_w", "key_x", "key_y", "key_z", "minus", "period", "quote", "semicolon",
        "slash", "alt_left", "alt_right", "backspace", "caps_lock", "context_menu",
        "control_left", "control_right", "enter", "meta_left", "meta_right",
        "shift_left", "shift_right", "space", "tab", "convert", "kana_mode",
        "non_convert", "delete", "end", "help", "home", "insert", "page_down",
        "page_up", "arrow_down", "arrow_left", "arrow_right", "arrow_up",
        "num_lock", "numpad_0", "numpad_1", "numpad_2", "numpad_3", "numpad_4",
        "numpad_5", "numpad_6", "numpad_7", "numpad_8", "numpad_9", "numpad_add",
        "numpad_backspace", "numpad_clear", "numpad_clear_entry", "numpad_comma",
        "numpad_decimal", "numpad_divide", "numpad_enter", "numpad_equal",
        "numpad_memory_add", "numpad_memory_clear", "numpad_memory_recall",
        "numpad_memory_store", "numpad_memory_subtract", "numpad_multiply",
        "numpad_paren_left", "numpad_paren_right", "numpad_subtract",
        "numpad_separator", "numpad_up", "numpad_down", "numpad_right",
        "numpad_left", "numpad_begin", "numpad_home", "numpad_end", "numpad_insert",
        "numpad_delete", "numpad_page_up", "numpad_page_down", "escape",
        "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
        "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23",
        "f24", "f25", "fn", "fn_lock", "print_screen", "scroll_lock", "pause",
        "browser_back", "browser_favorites", "browser_forward", "browser_home",
        "browser_refresh", "browser_search", "browser_stop", "eject",
        "launch_app_1", "launch_app_2", "launch_mail", "media_play_pause",
        "media_select", "media_stop", "media_track_next", "media_track_previous",
        "power", "sleep", "audio_volume_down", "audio_volume_mute",
        "audio_volume_up", "wake_up", "copy", "cut", "paste"
    ]
    return Set(keys)
}()

// MARK: - Parsing functions

func normalizeModifier(_ mod: String) -> String {
    let lower = mod.lowercased().trimmingCharacters(in: .whitespaces)
    return modifierAliases[lower] ?? lower
}

func parsePrefixes(from trigger: String) -> (prefixes: [String], remainder: String) {
    var prefixes: [String] = []
    var cursor = trigger
    var found = true
    while found {
        found = false
        for prefix in validPrefixes {
            if cursor.hasPrefix("\(prefix):") {
                prefixes.append(prefix)
                cursor = String(cursor.dropFirst(prefix.count + 1))
                found = true
                break
            }
        }
    }
    return (prefixes, cursor)
}

func normalizeKeyName(_ key: String) -> String {
    let compact = key.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    let lowered = compact.lowercased()

    if validKeys.contains(lowered) || lowered.hasPrefix("physical:") || lowered.count == 1 {
        return lowered
    }

    let snake = compact
        .replacingOccurrences(of: "([a-z0-9])([A-Z])", with: "$1_$2", options: .regularExpression)
        .replacingOccurrences(of: "([a-zA-Z])([0-9])", with: "$1_$2", options: .regularExpression)
        .replacingOccurrences(of: "([0-9])([a-zA-Z])", with: "$1_$2", options: .regularExpression)
        .lowercased()

    if validKeys.contains(snake) || snake.hasPrefix("physical:") { return snake }
    return lowered
}

func parseStep(_ rawStep: String) -> ParsedTriggerStep? {
    let step = rawStep.trimmingCharacters(in: .whitespaces)
    guard !step.isEmpty else { return nil }

    var key: String
    var modifierPart = ""

    if step == "+" {
        key = "+"
    } else if step.hasSuffix("++") {
        key = "+"
        modifierPart = String(step.dropLast(2))
    } else {
        guard let lastPlusIndex = step.lastIndex(of: "+") else {
            return ParsedTriggerStep(key: normalizeKeyName(step), modifiers: [])
        }

        if lastPlusIndex == step.startIndex {
            key = String(step)
            modifierPart = ""
        } else {
            key = String(step[step.index(after: lastPlusIndex)...])
            modifierPart = String(step[..<lastPlusIndex])
            if key.isEmpty { return nil }
        }
    }

    let normalizedKey = normalizeKeyName(key)
    let modifiers = modifierPart
        .split(separator: "+")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
        .map(normalizeModifier)
        .filter { !$0.isEmpty }

    return ParsedTriggerStep(key: normalizedKey, modifiers: modifiers)
}

func parseTrigger(_ triggerString: String) -> ParsedTrigger? {
    guard !triggerString.isEmpty else { return nil }

    let normalized = triggerString.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    let (prefixes, remainder) = parsePrefixes(from: normalized)

    let tokens = remainder.split(separator: ">", omittingEmptySubsequences: false).map(String.init)
    guard !tokens.isEmpty else { return nil }
    guard !tokens.contains(where: { $0.isEmpty }) else { return nil }

    var steps: [ParsedTriggerStep] = []
    for token in tokens {
        guard let step = parseStep(token) else { return nil }
        steps.append(step)
    }

    return ParsedTrigger(prefixes: prefixes, steps: steps)
}

func isValidKey(_ key: String) -> Bool {
    if validKeys.contains(key) { return true }
    if key.hasPrefix("physical:") { return true }
    return key.count == 1
}

func validateAction(_ action: String, args: String?) -> [String] {
    guard let definition = actionLookup[action] else {
        return ["unknown action '\(action)'"]
    }

    switch definition.type {
    case .none:
        if args != nil { return ["'\(action)' does not take arguments"] }
        return []
    case .free:
        if args == nil && !definition.allowEmpty { return ["'\(action)' requires arguments"] }
        return []
    case .text:
        if args == nil { return ["'\(action)' requires text argument"] }
        return []
    case .number:
        guard let a = args, !a.trimmingCharacters(in: .whitespaces).isEmpty else { return ["'\(action)' requires a numeric argument"] }
        if let number = Double(a), number.isFinite { return [] }
        return ["'\(action)' expects a number, got '\(a)'"]
    case .integer:
        guard let a = args, !a.trimmingCharacters(in: .whitespaces).isEmpty else { return ["'\(action)' requires an integer argument"] }
        if let intVal = Int(a) { if Double(intVal) == Double(a) { return [] } }
        return ["'\(action)' expects an integer, got '\(a)'"]
    case .unsignedInteger:
        guard let a = args, !a.trimmingCharacters(in: .whitespaces).isEmpty else { return ["'\(action)' requires a non-negative integer argument"] }
        let min = definition.min ?? 0
        if let intVal = Int(a), intVal >= min { return [] }
        return [min == 0 ? "'\(action)' expects a non-negative integer, got '\(a)'" : "'\(action)' expects an integer >= \(min), got '\(a)'"]
    case .enum:
        guard let a = args else {
            if definition.allowEmpty { return [] }
            return ["'\(action)' requires one of [\(definition.options?.joined(separator: ", ") ?? "")]"]
        }
        if let opts = definition.options, !opts.contains(a) {
            return ["Invalid value for '\(action)': '\(a)'"]
        }
        return []
    case .resize:
        guard let a = args else { return ["'\(action)' expects 'direction,offset'"] }
        let parts = a.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return ["'\(action)' expects 'direction,offset'"] }
        let dir = parts[0], amount = parts[1]
        if !resizeDirectionOptions.contains(dir) {
            return ["'\(action)' direction must be \(resizeDirectionOptions.joined(separator: ", "))"]
        }
        if amount.isEmpty || Int(amount) == nil || Int(amount)! < 0 {
            return ["'\(action)' requires a non-negative integer offset"]
        }
        return []
    case .direction:
        return []
    }
}

func parseKeybind(_ value: String) -> ParsedKeybind {
    if value == "clear" { return ParsedKeybind(trigger: nil, action: "clear", args: nil, errors: []) }
    if value.hasPrefix("chain=") {
        let action = String(value.dropFirst("chain=".count))
        let pieces = action.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let name = pieces.first.map(String.init) ?? ""
        let args = pieces.count > 1 ? String(pieces[1]) : nil
        return ParsedKeybind(trigger: nil, action: name, args: args, errors: validateAction(name, args: args))
    }
    guard let colonIndex = value.firstIndex(of: "=") else {
        return ParsedKeybind(trigger: nil, action: nil, args: nil, errors: ["missing '=' between trigger and action"])
    }

    let trigger = String(value[..<colonIndex]).trimmingCharacters(in: .whitespaces)
    let actionPart = String(value[value.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

    guard !trigger.isEmpty, !actionPart.isEmpty else {
        return ParsedKeybind(trigger: nil, action: nil, args: nil, errors: ["trigger or action missing"])
    }

    guard let parsedTrigger = parseTrigger(trigger) else {
        return ParsedKeybind(trigger: nil, action: nil, args: nil, errors: ["invalid trigger format"])
    }

    let argIndex = actionPart.firstIndex(of: ":")
    let action: String
    let args: String?
    if let ai = argIndex {
        action = String(actionPart[..<ai])
        args = String(actionPart[actionPart.index(after: ai)...])
    } else {
        action = actionPart
        args = nil
    }

    var errors: [String] = []
    if action.isEmpty { errors.append("action missing") }

    let prefixSet = Set(parsedTrigger.prefixes)
    if parsedTrigger.steps.count > 1 && (prefixSet.contains("global") || prefixSet.contains("all")) {
        errors.append("global/all keybinds cannot be sequences")
    }

    let actionErrors = action.isEmpty ? ["missing action"] : validateAction(action, args: args)
    errors.append(contentsOf: actionErrors)

    for step in parsedTrigger.steps {
        if !isValidKey(step.key) {
            errors.append("invalid key '\(step.key)'")
            break
        }
        for mod in step.modifiers {
            if !validModifiers.contains(mod) {
                errors.append("invalid modifier '\(mod)'")
                break
            }
        }
        if step.modifiers.count > 4 {
            errors.append("too many modifiers")
            break
        }
    }

    return ParsedKeybind(trigger: parsedTrigger, action: action, args: args, errors: errors)
}

func canonicalTrigger(_ parsed: ParsedTrigger) -> String {
    let steps = parsed.steps.map { step -> String in
        let sortedModifiers = step.modifiers.sorted()
        let modPart = sortedModifiers.joined(separator: "+")
        return modPart.isEmpty ? step.key : "\(modPart)+\(step.key)"
    }
    let prefixes = validPrefixes.filter { parsed.prefixes.contains($0) }.map { "\($0):" }.joined()
    return prefixes + steps.joined(separator: ">")
}

func getDiagnostics(_ keybinds: [String]) -> [(status: String, duplicate: Bool, errors: [String], canonical: String)] {
    let entries = keybinds.map(parseKeybind)
    var counts: [String: Int] = [:]
    for entry in entries {
        if let trigger = entry.trigger {
            let canon = canonicalTrigger(trigger)
            counts[canon, default: 0] += 1
        }
    }

    return entries.map { entry in
        let status = entry.errors.isEmpty ? "ok" : "invalid"
        if let trigger = entry.trigger {
            let canon = canonicalTrigger(trigger)
            let duplicate = (counts[canon] ?? 0) > 1
            return (status, duplicate, entry.errors, canon)
        }
        return (status, false, entry.errors, "")
    }
}

func formatTrigger(_ trigger: ParsedTrigger) -> String {
    let prefixes = validPrefixes.filter { trigger.prefixes.contains($0) }
    let prefixPart = prefixes.map { "\($0):" }.joined()
    let stepStrings = trigger.steps.map { step -> String in
        let sortedModifiers = step.modifiers.sorted()
        let modPart = sortedModifiers.joined(separator: "+")
        return modPart.isEmpty ? step.key : "\(modPart)+\(step.key)"
    }
    return "\(prefixPart)\(stepStrings.joined(separator: ">"))"
}