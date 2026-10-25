# Ghostty Config — Unofficial SwiftUI Port

A native macOS configuration editor adapted from
[Ghostty Config by Zerebos](https://github.com/zerebos/ghostty-config).

**This is an independent, unofficial port**, maintained by
**Damon Lu (@WhatDamon)**. The planned project repository is
[WhatDamon/ghostty-config-swiftui](https://github.com/WhatDamon/ghostty-config-swiftui)
(not yet created). It is not an official
release of Ghostty or the upstream Web project and does not imply endorsement.
The Home page and standard About panel identify both the upstream author and
native maintainer; the application menu exposes **Licenses & Credits…**.

## Build and test

Requires Xcode 26.3 or later; deployment target macOS 14. Open
`Ghostty Config/Ghostty Config.xcodeproj`.

From the repository root:

```sh
xcodebuild build -project 'Ghostty Config/Ghostty Config.xcodeproj' \
  -scheme 'Ghostty Config' -configuration Release -destination 'platform=macOS' \
  -derivedDataPath /tmp/ghostty-config-release CODE_SIGN_IDENTITY=-

xcodebuild test -project 'Ghostty Config/Ghostty Config.xcodeproj' \
  -scheme 'Ghostty Config' -destination 'platform=macOS' \
  -derivedDataPath /tmp/ghostty-config-tests \
  -only-testing:'Ghostty ConfigTests' CODE_SIGN_IDENTITY=-

python3 -m unittest discover -s 'Ghostty Config/scripts' -p 'test_*.py'
```

Validation for this cleanup: 68 native unit tests and 8 Python license-policy
tests passed; Debug/Release builds succeeded. A fresh directory exported only
from the rebuilt Git index also regenerated resources and built Release without
any reference archive. Home, About and bundled legal notices were checked with
Computer Use.

No CI workflow is currently included. XCTest UI tests are retained, but this
host has had accessibility-runner timeouts; unit tests and Computer Use checks
are reported separately. System SDKs provide SwiftUI/AppKit; the app bundles no
font binaries or third-party Swift Package runtime libraries.

## Features

- Native editors for 181 settings across 9 categories, including Terminal.
- Repeatable-value lists, units, durations, linked padding and device-specific
  scroll multipliers, feature groups, and special color/blur choices.
- **56 offline themes from 15 reviewed MIT sources**; single/light-and-dark
  selection, explicit color overrides, and per-index palette overrides.
- Native search, setting help and metadata, reset controls, and Back/Forward
  navigation (`⌘[` / `⌘]`) with search-target restoration.
- Import review, line diagnostics, before/after changes, file/clipboard export
  and Web-compatible share links. Unknown settings are preserved.
- Font Playground and static visual previews; no simulated terminal or shell.

Changes remain in memory until exported. Saving uses a user-selected file; the
app does not silently overwrite the installed Ghostty config. Draft persistence,
direct config/reload integration, and guided key tables/command palette entries
remain future work. macOS 14 and dark appearance need broader runtime validation.

## Source data and theme distribution policy

`Ghostty Config/Ghostty Config/Resources/UpstreamSettings.json` records the pinned
Web source SHA, local modifications and the filtered theme set. The Web checkout
was **not** adopted as a third-party license authority: its current generator
packs all themes without individual-license filtering.

Only themes with a reviewed source project, pinned MIT text, and unchanged
color-data hash are included. `ThemeLicenses.json` records every included name,
source revision, license path/hash and color hash. Complete notices are tracked
in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [LICENSES/](LICENSES/).
Unknown, nonfree and other unreviewed themes have neither colors nor generated
picker options in the application resources. There is **no online theme fetch**.
Users can still enter an existing theme name or local path; colors outside the
bundled set cannot be previewed automatically.

Offline validation and deterministic regeneration:

```sh
python3 'Ghostty Config/scripts/sync-web-settings.py'
```

To update from a separately reviewed Web checkout (Bun required for extraction):

```sh
python3 'Ghostty Config/scripts/sync-web-settings.py' \
  --source-root /path/to/upstream --revision EXACT_CHECKOUT_HEAD_SHA
```

Regeneration filters to the reviewed theme manifest and fails on missing or
changed license/color evidence. Adding or changing a bundled theme requires a
deliberate source-license review and manifest update; it cannot silently restore
the upstream full collection. The bundled notices are generated from the tracked
legal files by the same command. Neither regeneration mode changes the real
Ghostty configuration.

## License and attribution

[Apache License 2.0](LICENSE), with **Copyright 2024 Zerebos** retained unchanged.
SwiftUI port and native modifications: **Copyright 2026 Damon Lu (@WhatDamon)**.
See [NOTICE](NOTICE) for the modification/independence notice. Ghostty preview
artwork and configuration documentation retain their MIT notice. The reviewed
themes retain their authors' MIT licenses; third-party content is not relabeled
as exclusively Apache-2.0. Complete texts are bundled in the app and accessible
under **Licenses & Credits…**.

The reference Web project, legacy Swift Package, engineering notes, agent logs,
old CI and build caches are preserved locally under `.local-reference/`, excluded
from Git and releases. This repository starts with an independent initial commit;
upstream Git history is preserved only in the excluded local recovery archive.
The `origin` remote points to `WhatDamon/ghostty-config-swiftui`, which is intended
to be created as a standalone repository, not a GitHub fork. Source attribution
and license notices remain intact.
