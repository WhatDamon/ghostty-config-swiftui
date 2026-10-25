# Ghostty Config — Unofficial Native SwiftUI Port

A native macOS configuration editor adapted from
[Ghostty Config by Zerebos](https://github.com/zerebos/ghostty-config).

> [!IMPORTANT]
> **This is an independent, unofficial port**, maintained by **WhatDamon**. It is not an official release of Ghostty or the upstream Web project and does not imply endorsement.

## Build and test

Requires Xcode 26.3 or later; deployment target macOS 14. Open `Ghostty Config/Ghostty Config.xcodeproj`.

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

## License and attribution

[Apache License 2.0](LICENSE)

See [NOTICE](NOTICE) for the modification/independence notice. Ghostty previewartwork and configuration documentation retain their MIT notice. The reviewed themes retain their authors' MIT licenses; third-party content is not relabeled as exclusively Apache-2.0. Complete texts are bundled in the app and accessible under **Licenses & Credits…**.
