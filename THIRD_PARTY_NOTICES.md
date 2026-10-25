# Third-party notices

The native application code is distributed under Apache-2.0 with the original Zerebos copyright retained. Third-party material below retains its own license; it is not relicensed solely as Apache-2.0.

## Upstream Web implementation

- Project: [zerebos/ghostty-config](https://github.com/zerebos/ghostty-config).
- Copyright 2024 Zerebos. License: Apache-2.0; see root `LICENSE`.
- Adapted code, registry descriptions/navigation/defaults, theme conversion output and project logo are based on upstream.
- Reviewed data revision: `f2eac4de31a8b4eb924850c5f96f4a113c940773`.
- SwiftUI port, restructuring, value codecs, native navigation and other modifications: Damon Lu (@WhatDamon), 2026.

## Ghostty configuration documentation and preview artwork

- Project: [ghostty-org/ghostty](https://github.com/ghostty-org/ghostty).
- Copyright (c) 2024 Mitchell Hashimoto, Ghostty contributors.
- License: MIT; complete notice in `LICENSES/Ghostty-MIT.txt`.
- The 17 bundled preview PNGs match the copies vendored by the pinned Web source.
- Config descriptions ultimately derive from Ghostty configuration documentation.
- Preview icons illustrate Ghostty settings; they do not identify this app as an official Ghostty release.
- For resource hashes and precise provenance, see `Ghostty Config/Support/asset-provenance.json`.

## Offline theme collection

- Collection: [mbadolato/iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes).
- Copyright (c) 2011 to Present Mark Badolato.
- Collection license: MIT; full text in `LICENSES/iTerm2-Color-Schemes-MIT.txt`.
- That license explicitly leaves each individual theme copyright/license with its author.
- This release contains **56 themes from 15 independently reviewed MIT sources**, not the full upstream theme set.
- Themes with missing, unknown, nonfree, or additional copyleft/share-alike requirements were not included.
- Upstream Web currently packs all theme files without author-license filtering; that behavior was not adopted.
- `Ghostty Config/Ghostty Config/Resources/ThemeLicenses.json` records each name, source revision, license hash and color-data hash.
- Color conversions originate from the pinned Web snapshot; source license reviews are separately pinned below.
- The app does not fetch excluded theme colors. Users may still enter a theme name or local path they already have.

| Theme source | Copyright | License evidence revision | Included themes |
| --- | --- | --- | --- |
| [EdenEast/nightfox.nvim](https://github.com/EdenEast/nightfox.nvim) | Copyright (c) 2021 James Simpson | [`4dacd3f0185a`](https://raw.githubusercontent.com/EdenEast/nightfox.nvim/4dacd3f0185a2227bdf3b6c0975a8f0bf87cac9a/LICENSE) · [MIT](LICENSES/EdenEast--nightfox.nvim-MIT.txt) | Carbonfox, Dawnfox, Dayfox, Duskfox, Nightfox, Nordfox, Terafox |
| [catppuccin/palette](https://github.com/catppuccin/palette) | Copyright (c) 2021 Catppuccin | [`07d02aa110ef`](https://raw.githubusercontent.com/catppuccin/palette/07d02aa110ef9eb7e7427afca5c73ba9cf7f8ebd/LICENSE) · [MIT](LICENSES/catppuccin--palette-MIT.txt) | Catppuccin Frappe, Catppuccin Latte, Catppuccin Macchiato, Catppuccin Mocha |
| [zenbones-theme/zenbones.nvim](https://github.com/zenbones-theme/zenbones.nvim) | Copyright (c) 2022 Michael Chris Lopez | [`8304d8df9b82`](https://raw.githubusercontent.com/zenbones-theme/zenbones.nvim/8304d8df9b823ff11e103afa62f38c39f534abe6/LICENSE) · [MIT](LICENSES/zenbones-theme--zenbones.nvim-MIT.txt) | Duckbones, Kanagawabones, Neobones Dark, Neobones Light, Seoulbones Dark, Seoulbones Light, Vimbones, Zenbones, Zenbones Dark, Zenbones Light, Zenburned, Zenwritten Dark, Zenwritten Light |
| [sainnhe/gruvbox-material](https://github.com/sainnhe/gruvbox-material) | Copyright (c) 2020 sainnhe | [`11d779b26a9a`](https://raw.githubusercontent.com/sainnhe/gruvbox-material/11d779b26a9ab2b3db8c22c6ac9fb6e8ed4fea79/LICENSE) · [MIT](LICENSES/sainnhe--gruvbox-material-MIT.txt) | Gruvbox Material, Gruvbox Material Dark, Gruvbox Material Light |
| [sainnhe/sonokai](https://github.com/sainnhe/sonokai) | Copyright (c) 2020 sainnhe | [`b023c5280b16`](https://raw.githubusercontent.com/sainnhe/sonokai/b023c5280b16fe2366f5e779d8d2756b3e5ee9c3/LICENSE) · [MIT](LICENSES/sainnhe--sonokai-MIT.txt) | Sonokai |
| [rose-pine/build](https://github.com/rose-pine/build) | Copyright (c) mvllow | [`1111ed6c610e`](https://raw.githubusercontent.com/rose-pine/build/1111ed6c610e13eeec99a5112aa937942f663b1d/LICENSE) · [MIT](LICENSES/rose-pine--build-MIT.txt) | Rose Pine, Rose Pine Dawn, Rose Pine Moon |
| [rebelot/kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) | Copyright (c) 2021 Tommaso Laurenzi | [`bb85e4bfc8d8`](https://raw.githubusercontent.com/rebelot/kanagawa.nvim/bb85e4bfc8d89b0e62c8fa53ccdd13d12e2f77b3/LICENSE) · [MIT](LICENSES/rebelot--kanagawa.nvim-MIT.txt) | Kanagawa Dragon, Kanagawa Wave |
| [kepano/flexoki](https://github.com/kepano/flexoki) | Copyright (c) 2023 Steph Ango | [`8d723bac4a9a`](https://raw.githubusercontent.com/kepano/flexoki/8d723bac4a9ac46adfdf99d42155286977aac72a/LICENSE) · [MIT](LICENSES/kepano--flexoki-MIT.txt) | Flexoki Dark, Flexoki Light |
| [sonph/onehalf](https://github.com/sonph/onehalf) | Copyright (c) 2019 Son A. Pham <sp@sonpham.me> | [`75eb2e97acd7`](https://raw.githubusercontent.com/sonph/onehalf/75eb2e97acd74660779fed8380989ee7891eec56/LICENSE.txt) · [MIT](LICENSES/sonph--onehalf-MIT.txt) | One Half Dark, One Half Light |
| [chriskempson/tomorrow-theme](https://github.com/chriskempson/tomorrow-theme) | Copyright (C) 2011 [Chris Kempson](https://github.com/chriskempson) | [`ccf6666d8881`](https://raw.githubusercontent.com/chriskempson/tomorrow-theme/ccf6666d888198d341b26b3a99d0bc96500ad503/LICENSE.md) · [MIT](LICENSES/chriskempson--tomorrow-theme-MIT.txt) | Tomorrow, Tomorrow Night, Tomorrow Night Blue, Tomorrow Night Bright, Tomorrow Night Eighties |
| [cocopon/iceberg.vim](https://github.com/cocopon/iceberg.vim) | Copyright (c) 2014 cocopon <cocopon@me.com> | [`23835d5ed696`](https://raw.githubusercontent.com/cocopon/iceberg.vim/23835d5ed696436f716cbfdb56a93a7850fe3b18/LICENSE.txt) · [MIT](LICENSES/cocopon--iceberg.vim-MIT.txt) | Iceberg Dark, Iceberg Light |
| [sindresorhus/iterm2-snazzy](https://github.com/sindresorhus/iterm2-snazzy) | Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (https://sindresorhus.com) | [`27b3156992a8`](https://raw.githubusercontent.com/sindresorhus/iterm2-snazzy/27b3156992a87ccb36c44448592e85da70f61acc/license) · [MIT](LICENSES/sindresorhus--iterm2-snazzy-MIT.txt) | Snazzy |
| [raunofreiberg/vesper](https://github.com/raunofreiberg/vesper) | Copyright (c) 2023 Rauno Freiberg | [`9043f3849b77`](https://raw.githubusercontent.com/raunofreiberg/vesper/9043f3849b776949445f0cd4990365959cca35a3/LICENSE.md) · [MIT](LICENSES/raunofreiberg--vesper-MIT.txt) | Vesper |
| [microsoft/vscode](https://github.com/microsoft/vscode) | Copyright (c) 2015 - present Microsoft Corporation | [`ed40651055dc`](https://raw.githubusercontent.com/microsoft/vscode/ed40651055dc41f4cc669f33016b7724b78bb3b4/LICENSE.txt) · [MIT](LICENSES/microsoft--vscode-MIT.txt) | Dark Modern, Dark+ |
| [primer/github-vscode-theme](https://github.com/primer/github-vscode-theme) | Copyright (c) 2020 Primer | [`cd78e5e4e7bc`](https://raw.githubusercontent.com/primer/github-vscode-theme/cd78e5e4e7bcf132a6f428ae0f32264bb1b729cf/LICENSE) · [MIT](LICENSES/primer--github-vscode-theme-MIT.txt) | GitHub Dark, GitHub Dark Colorblind, GitHub Dark Default, GitHub Dark Dimmed, GitHub Dark High Contrast, GitHub Light Colorblind, GitHub Light Default, GitHub Light High Contrast |

## Distribution

All complete license texts and attribution records above are combined verbatim in the bundled `LegalNotices.txt`. The application exposes them through **Licenses & Credits…** and clearly identifies the independent port in Home and About.

The native app bundles no font binaries and has no third-party Swift Package runtime dependencies. System frameworks are provided by macOS. The excluded Web reference and its fonts/build dependencies are not part of this native source tree or app distribution.

The existing Git history still contains the upstream Web project. Local reference exclusion is not a history rewrite; anyone distributing those older revisions must consider the content of those revisions separately.
