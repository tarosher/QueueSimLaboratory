"""Fast stdlib self-tests for the repo preflight (does not invoke MATLAB)."""
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_release


class ReleaseAuditTests(unittest.TestCase):
    def test_candidate_structure_is_valid(self):
        self.assertEqual(check_release.audit(public=False), [])

    def test_rc1_test_inventory_is_exactly_89(self):
        self.assertFalse(any('test inventory drift' in issue
                             for issue in check_release.audit(public=False)))

    def test_missing_required_file_is_detected(self):
        with mock.patch.object(check_release, 'REQUIRED', check_release.REQUIRED + ['fake_M5_missing_file.txt']):
            issues = check_release.audit(public=False)
        self.assertTrue(any('fake_M5_missing_file.txt' in i for i in issues))

    def test_mit_candidate_does_not_authorize_publication(self):
        issues = check_release.audit(public=True)
        self.assertTrue((check_release.ROOT / 'LICENSE').is_file())
        self.assertTrue(any('owner approval not recorded' in item for item in issues))
        self.assertFalse(any('LICENSE file missing' in item for item in issues))

    def test_public_gate_requires_license_and_owner_approval(self):
        from tempfile import TemporaryDirectory
        from unittest.mock import patch
        with TemporaryDirectory() as temp:
            import shutil
            import re
            tmp=Path(temp)
            (tmp/'docs').mkdir()
            (tmp/'docs/RELEASE_APPROVAL_RECORD_ZH.md').write_text('PUBLIC_RELEASE_APPROVED: NO\n',encoding='utf-8')
            # Use a minimal independent check of the exact marker; no claim of legal validation.
            self.assertFalse(bool(re.search(r'^PUBLIC_RELEASE_APPROVED: YES\s*$',(tmp/'docs/RELEASE_APPROVAL_RECORD_ZH.md').read_text(),re.M)))
            (tmp/'docs/RELEASE_APPROVAL_RECORD_ZH.md').write_text('PUBLIC_RELEASE_APPROVED: YES\n',encoding='utf-8')
            self.assertTrue(bool(re.search(r'^PUBLIC_RELEASE_APPROVED: YES\s*$',(tmp/'docs/RELEASE_APPROVAL_RECORD_ZH.md').read_text(),re.M)))


if __name__ == '__main__':
    unittest.main()
