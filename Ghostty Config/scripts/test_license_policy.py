# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Damon Lu (@WhatDamon)
import copy
import json
from pathlib import Path
import tempfile
import unittest

from license_policy import apply_policy, reviewed_themes, render_legal

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parent
RESOURCES = PROJECT / 'Ghostty Config/Resources'


class ThemeLicensePolicyTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((RESOURCES / 'UpstreamSettings.json').read_text())
        self.manifest = json.loads((RESOURCES / 'ThemeLicenses.json').read_text())

    def test_every_bundled_theme_has_exact_license_and_color_evidence(self):
        result = reviewed_themes(self.data, self.manifest, ROOT)
        self.assertEqual(result, self.data['themes'])
        self.assertEqual(len(result), 56)
        self.assertEqual(len(self.manifest['sources']), 15)

    def test_new_unreviewed_theme_and_picker_option_cannot_reenter(self):
        self.data['themes']['Unreviewed Test Theme'] = {'palette': ['#123456']}
        self.data['registry']['theme']['widget']['options'].append({'name': 'Unreviewed Test Theme', 'value': 'Unreviewed Test Theme'})
        filtered = apply_policy(self.data, self.manifest, ROOT)
        self.assertNotIn('Unreviewed Test Theme', filtered['themes'])
        self.assertEqual({o['value'] for o in filtered['registry']['theme']['widget']['options']}, set(filtered['themes']))

    def test_changed_theme_colors_require_new_review(self):
        first = next(iter(self.data['themes']))
        self.data['themes'][first]['background'] = '#123456'
        with self.assertRaisesRegex(ValueError, 'colors changed'):
            reviewed_themes(self.data, self.manifest, ROOT)

    def test_unknown_or_nonfree_license_is_not_accepted(self):
        for license_name in ['unknown', 'nonfree', 'GPL-3.0-only']:
            manifest = copy.deepcopy(self.manifest)
            manifest['themes'][next(iter(manifest['themes']))]['license'] = license_name
            with self.assertRaisesRegex(ValueError, 'explicit policy review'):
                reviewed_themes(self.data, manifest, ROOT)

    def test_missing_license_cannot_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, 'missing/changed license'):
                reviewed_themes(self.data, self.manifest, Path(directory))

    def test_missing_theme_requires_deliberate_manifest_change(self):
        del self.data['themes'][next(iter(self.data['themes']))]
        with self.assertRaisesRegex(ValueError, 'reviewed theme missing'):
            reviewed_themes(self.data, self.manifest, ROOT)

    def test_mismatched_source_revision_cannot_pass(self):
        first = next(iter(self.manifest['themes']))
        self.manifest['themes'][first]['licenseRevision'] = 'not-reviewed'
        with self.assertRaisesRegex(ValueError, 'pinned source review'):
            reviewed_themes(self.data, self.manifest, ROOT)

    def test_bundled_notices_match_tracked_legal_files(self):
        generated = render_legal(ROOT)
        self.assertEqual(generated, (RESOURCES / 'LegalNotices.txt').read_text())
        self.assertIn('Copyright 2024 Zerebos', generated)
        self.assertIn('Copyright 2026 Damon Lu', generated)
        for path in (ROOT / 'LICENSES').glob('*.txt'):
            self.assertIn(path.read_text().rstrip(), generated)


if __name__ == '__main__':
    unittest.main()
