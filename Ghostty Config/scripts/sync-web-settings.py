#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Damon Lu (@WhatDamon). Based on Ghostty Config, Copyright 2024 Zerebos.
"""Bundle the reviewed upstream registry and theme data without modifying Web files.

python3 scripts/sync-web-settings.py --source-root /path/to/upstream --revision SHA
The default regenerates from the checked-in normalized snapshot, offline.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
from license_policy import apply_policy, render_legal

project = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source-root', type=Path)
parser.add_argument('--revision')
args = parser.parse_args()
snapshot = project / 'Ghostty Config/Resources/UpstreamSettings.json'
if args.source_root:
    revision = subprocess.check_output(['git', '-C', str(args.source_root), 'rev-parse', 'HEAD'], text=True).strip()
    if not args.revision or revision != args.revision:
        raise SystemExit('Provide --revision matching the source checkout HEAD.')
    data = json.loads(subprocess.check_output(['bun', str(project / 'scripts/export-upstream.ts'), str(args.source_root.resolve()), revision], text=True))
else:
    data = json.loads(snapshot.read_text())
manifest = json.loads((snapshot.parent / 'ThemeLicenses.json').read_text())
data = apply_policy(data, manifest, project.parent)
registry = data['registry']
seen = []
for panel in data['navigation']:
    for group in panel['groups']:
        for key in group['settings']:
            if key not in registry: raise SystemExit(f'Unknown navigation key: {key}')
            seen.append(key)
if len(seen) != len(set(seen)): raise SystemExit('Duplicate navigation keys')
keyfile = project / 'Ghostty Config/Models/Domain/ConfigKey.swift'
text = keyfile.read_text()
existing = set(re.findall(r'^    case `?(\w+)', text, re.M))
cases = '\n'.join(f'    case {chr(96) + key + chr(96) if key == "class" else key} = {json.dumps(value["key"])}' for key,value in sorted(registry.items()) if key not in existing)
if cases:
    text = text.replace('    case unknown = ""', cases + '\n\n    case unknown = ""')
    keyfile.write_text(text)
snapshot.parent.mkdir(exist_ok=True)
snapshot.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
(snapshot.parent / 'LegalNotices.txt').write_text(render_legal(project.parent))
print(f'{len(registry)} definitions, {len(seen)} visible settings, {len(data["navigation"])} panels, {len(data["themes"])} offline themes; source {data["source"]["revision"]}')
