#!/usr/bin/env python3
"""Static repository preflight (stdlib only; does NOT run MATLAB or approve licensing)."""
from __future__ import annotations
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    'README.md', 'CONTRIBUTING.md', 'CHANGELOG.md', '.gitignore',
    'docs/QUICKSTART.md', 'docs/API_REFERENCE.md',
    'docs/VALIDATION.md', 'docs/PUBLIC_RELEASE_CHECKLIST.md',
    'docs/BENCHMARKS.md', 'benchmarks/README.md',
    'tests/run_all_tests.m', 'tests/run_rc_acceptance.m',
    'tests/TestM5ReleaseQuality.m',
    '+qsim/run.m', '+qsim/defaultConfig.m',
    '+qsim/+network/simulateNetwork.m',
    'examples/run_m41_integrated.m', 'examples/run_m5_performance.m',
    '.github/workflows/matlab-tests.yml',
    '.github/workflows/static-checks.yml',
]
LINK = re.compile(r'(?<!!)\[[^]]+\]\(([^)]+)\)')
# Deliberately conservative direct credential formats; not a secret scanner.
TOKEN = re.compile(r'(?<![\w])(?:ghp_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{50,}|sk-[A-Za-z0-9]{35,})(?![\w])')


def audit(public: bool) -> list[str]:
    problems: list[str] = []
    if (ROOT / 'legacy').exists():
        problems.append('Original course legacy/ source is not authorized for this staging edition')
    if (ROOT / 'tests' / 'TestLegacyRegression.m').exists():
        problems.append('Legacy regression test must not ship without its original fixture')
    for rel in REQUIRED:
        if not (ROOT / rel).is_file():
            problems.append(f'MISSING required file: {rel}')

    docs = [ROOT / 'README.md', *sorted((ROOT / 'docs').glob('*.md')),
            ROOT / 'CONTRIBUTING.md', ROOT / 'CHANGELOG.md',
            ROOT / 'benchmarks' / 'README.md']
    for file in docs:
        if not file.is_file():
            continue
        content = file.read_text(encoding='utf-8')
        for link in LINK.findall(content):
            url = link.split('#', 1)[0]
            if not url or url.startswith(('https:', 'http:', 'mailto:', '#')):
                continue
            if '://' in url:
                continue
            dest = (file.parent / url).resolve()
            if not dest.is_relative_to(ROOT) or not dest.exists():
                problems.append(f'BROKEN documentation link: {file.relative_to(ROOT)} -> {link}')

    ignore = (ROOT / '.gitignore').read_text(encoding='utf-8') if (ROOT / '.gitignore').exists() else ''
    if 'outputs/*' not in ignore:
        problems.append('Missing outputs/* from .gitignore')
    if not (ROOT / 'tests' / 'run_all_tests.m').exists():
        problems.append('No MATLAB regression entrypoint')

    # This GitHub-only rc1 snapshot has 89 tests, not the original 90.
    # Count source-declared test methods (static inventory, NOT MATLAB execution).
    tests_folder = ROOT / 'tests'
    if tests_folder.is_dir():
        count = sum(len(re.findall(r'^\s*function\s+\w+\(testCase\)',
                                   p.read_text(encoding='utf-8'), re.M))
                    for p in tests_folder.glob('Test*.m'))
        if count != 89:
            problems.append(f'RC1 test inventory drift: expected 89, found {count}')

    # Prevent accidental promotion of generated products as source material.
    for path in (ROOT / 'outputs').rglob('*') if (ROOT / 'outputs').exists() else []:
        if path.is_file() and path.name != '.gitkeep':
            problems.append(f'Generated output packaged in repository: {path.relative_to(ROOT)}')

    for path in ROOT.rglob('*'):
        if not path.is_file() or any(part in ('.git', 'outputs') for part in path.relative_to(ROOT).parts):
            continue
        if path.suffix.lower() not in ('.m', '.py', '.yml', '.yaml', '.json'):
            continue
        try:
            content = path.read_text(encoding='utf-8', errors='replace')
        except OSError:
            continue
        if TOKEN.search(content):
            problems.append(f'Possible embedded API token: {path.relative_to(ROOT)}')

    if public:
        if not any((ROOT / name).is_file() for name in ('LICENSE', 'LICENSE.md', 'LICENSE.txt')):
            problems.append('PUBLIC release blocked: LICENSE file missing')
        approval = ROOT / 'docs' / 'RELEASE_APPROVAL_RECORD_ZH.md'
        approved = approval.is_file() and bool(re.search(
            r'^PUBLIC_RELEASE_APPROVED: YES\s*$', approval.read_text(encoding='utf-8'), re.M))
        if not approved:
            problems.append('PUBLIC release blocked: owner approval not recorded (PUBLIC_RELEASE_APPROVED: YES required)')
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--public', action='store_true', help='Additional license-file gate (not legal clearance).')
    args = parser.parse_args()
    issues = audit(args.public)
    print(f'QueueSimLab preflight: {len(issues)} issue(s); MATLAB tests not run.')
    for problem in issues:
        print(' - ' + problem)
    return 1 if issues else 0


if __name__ == '__main__':
    sys.exit(main())
