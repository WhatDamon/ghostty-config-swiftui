# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Damon Lu (@WhatDamon)
"""Fail-closed release checks for bundled theme data and attribution evidence."""
import hashlib
import json
from pathlib import Path


def digest_colors(colors):
    return hashlib.sha256(json.dumps(colors, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()).hexdigest()


def reviewed_themes(data, manifest, repository_root):
    if manifest.get('schemaVersion') != 1:
        raise ValueError('Unsupported theme license manifest schema')
    approved = manifest.get('themes', {})
    if not approved:
        raise ValueError('No independently reviewed theme sources')
    sources = {s['repository']: s for s in manifest['sources']}
    filtered = {}
    for name, record in approved.items():
        if record.get('license') != 'MIT':
            raise ValueError(f'{name}: license requires explicit policy review')
        repository = record['repository'].removeprefix('https://github.com/')
        source = sources.get(repository)
        if not source or source['revision'] != record['licenseRevision']:
            raise ValueError(f'{name}: no matching pinned source review')
        if source['licenseFile'] != record['licenseFile'] or source['licenseSHA256'] != record['licenseSHA256']:
            raise ValueError(f'{name}: mismatched license evidence')
        path = repository_root / record['licenseFile']
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != record['licenseSHA256']:
            raise ValueError(f'{name}: missing/changed license text: {path}')
        text = path.read_text()
        if 'Permission is hereby granted, free of charge' not in text or 'copyright' not in text.lower():
            raise ValueError(f'{name}: incomplete MIT notice')
        if name not in data['themes']:
            raise ValueError(f'{name}: reviewed theme missing from source; re-review before changing allowlist')
        colors = data['themes'][name]
        if digest_colors(colors) != record['colorsSHA256']:
            raise ValueError(f'{name}: colors changed since review; update evidence deliberately')
        filtered[name] = colors
    return {name: filtered[name] for name in sorted(filtered, key=str.casefold)}


def apply_policy(data, manifest, repository_root):
    data['themes'] = reviewed_themes(data, manifest, repository_root)
    data['registry']['theme']['widget']['options'] = [{'name': name, 'value': name} for name in data['themes']]
    data['source'].update({
        'upstreamCopyright': 'Copyright 2024 Zerebos',
        'upstreamLicense': 'Apache-2.0',
        'modifiedBy': 'Damon Lu (@WhatDamon), 2026',
        'modifications': 'Unofficial SwiftUI port; macOS registry adaptation; native clipboard-codepoint-map entry; theme data restricted to the reviewed MIT allowlist.',
        'themePolicy': 'Reviewed MIT sources only; exact theme set, color digests and license evidence are in ThemeLicenses.json. No runtime theme download.',
        'themeManifest': 'ThemeLicenses.json',
    })
    return data


def render_legal(repository_root):
    sections = [
        ('PROJECT NOTICE', repository_root / 'NOTICE'),
        ('PROJECT LICENSE — APACHE 2.0 (ORIGINAL COPYRIGHT RETAINED)', repository_root / 'LICENSE'),
        ('THIRD-PARTY ATTRIBUTIONS', repository_root / 'THIRD_PARTY_NOTICES.md'),
    ]
    sections += [(p.name, p) for p in sorted((repository_root / 'LICENSES').glob('*.txt'))]
    return '\n\n'.join(title + '\n' + '=' * len(title) + '\n\n' + path.read_text().rstrip() for title, path in sections) + '\n'
