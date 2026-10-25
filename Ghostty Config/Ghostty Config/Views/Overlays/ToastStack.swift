// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Toast Stack

struct ToastStack: View {
    @Environment(\.toastService) private var toastService

    var body: some View {
        VStack(spacing: 8) {
            ForEach(toastService.toasts) { toast in
                HStack(spacing: 8) {
                    Image(systemName: toast.type == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(toast.type == .success ? .green : .red)
                    Text(toast.message)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        withAnimation {
                            toastService.dismiss(toast)
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .animation(.spring, value: toastService.toasts.count)
    }
}
