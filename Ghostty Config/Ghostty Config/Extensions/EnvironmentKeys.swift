// SPDX-License-Identifier: Apache-2.0
// Unofficial SwiftUI port and modifications: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

import SwiftUI

// MARK: - Environment Keys for Dependency Injection

extension EnvironmentValues {
    @Entry var configService: ConfigService = ConfigService()
    @Entry var toastService: ToastService = ToastService()
    @Entry var localConfigService: LocalConfigService = LocalConfigService()
}
