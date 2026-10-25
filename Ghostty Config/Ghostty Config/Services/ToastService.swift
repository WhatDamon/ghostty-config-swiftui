// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import Foundation
import Observation

// MARK: - Toast Service

@MainActor
@Observable
final class ToastService {
    // Avoid the isolated-deinit back-deployment thunk on macOS 14/15.
    nonisolated deinit {}

    private(set) var toasts: [ToastMessage] = []

    struct ToastMessage: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let type: ToastType

        enum ToastType: Equatable {
            case success, error
        }
    }

    func success(_ message: String) {
        addToast(message, type: .success)
    }

    func error(_ message: String) {
        addToast(message, type: .error)
    }

    private func addToast(_ message: String, type: ToastMessage.ToastType) {
        let toast = ToastMessage(message: message, type: type)
        toasts.append(toast)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run { [weak self] in
                self?.dismiss(toast)
            }
        }
    }

    func dismiss(_ toast: ToastMessage) {
        toasts.removeAll { $0.id == toast.id }
    }
}
