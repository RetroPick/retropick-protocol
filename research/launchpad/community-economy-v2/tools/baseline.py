#!/usr/bin/env python3
"""Read-only source inventory and protected-path check; JSON goes to stdout.

Declaration extraction is a review aid, not a compiler ABI or a semantic audit.
Run from any directory. --check fails on protected changes or a changed baseline.
"""
import argparse
import difflib
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[4]
BASE = "28a4744dcc8005da285f9e924ba7841073daee0b"
PROTECTED = ["contracts/src/v1", "contracts/src/v2", "contracts/script", "deployments"]


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def declarations(text):
    # Retain newlines for source locations; do not interpret comments as code.
    clean = re.sub(r'/\*.*?\*/|//[^\n]*', lambda m: '\n' * m[0].count('\n'), text, flags=re.S)
    return [{"line": clean.count('\n', 0, m.start()) + 1,
             "declaration": ' '.join(m[0].split())}
            for m in re.finditer(r'\b(?:function|constructor|modifier|event|struct|enum)\s*[^;{]*', clean)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    a = ROOT / 'contracts/src/v2'
    b = ROOT / 'contracts/src/v2-research-experiment'
    pairs = []
    inventory = []
    for relative in sorted({p.relative_to(a) for p in a.rglob('*.sol')} |
                           {p.relative_to(b) for p in b.rglob('*.sol')}):
        x, y = a / relative, b / relative
        item = {"path": str(relative), "canonical_exists": x.exists(), "experiment_exists": y.exists()}
        if x.exists() and y.exists():
            xb, yb = x.read_bytes(), y.read_bytes()
            item.update(canonical_sha256=digest(xb), experiment_sha256=digest(yb), identical=xb == yb)
            if xb != yb:
                item['diff'] = list(difflib.unified_diff(xb.decode().splitlines(), yb.decode().splitlines()))
        pairs.append(item)
        for lane, path in [('canonical', x), ('experiment', y)]:
            if path.exists():
                t = path.read_text()
                inventory.append({"lane": lane, "path": str(path.relative_to(ROOT)),
                                  "sha256": digest(path.read_bytes()), "lines": len(t.splitlines()),
                                  "declarations": declarations(t)})
    changed = git('diff', '--name-only', BASE, '--', *PROTECTED).splitlines()
    untracked = git('ls-files', '--others', '--exclude-standard', '--', *PROTECTED).splitlines()
    changed_tests = [p for p in git('diff', '--name-only', BASE, '--', 'contracts/test/v2').splitlines()
                     if not p.startswith('contracts/test/v2/research-experiment/')]
    tests = sorted(str(p.relative_to(ROOT)) for p in (ROOT/'contracts/test/v2').rglob('*.sol'))
    scripts = sorted(str(p.relative_to(ROOT)) for p in (ROOT/'contracts/script').rglob('*') if p.is_file())
    consumers = subprocess.run(['git', '-C', str(ROOT), 'grep', '-l', '-E',
                               'src/v2/|RetroPickLaunchFactoryV2|RetroPickMemeHookV2', '--',
                               'packages', 'apps', 'contracts/test', 'contracts/script'],
                              capture_output=True, text=True, check=False)
    if consumers.returncode not in (0, 1):
        raise RuntimeError(consumers.stderr)
    data = {"baseline": BASE, "head": git('rev-parse', 'HEAD'),
            "branch": git('branch', '--show-current'), "protected_changed": changed,
            "protected_untracked": untracked, "pairs": pairs, "inventory": inventory,
            "original_tests_changed": changed_tests,
            "tests": tests, "scripts": scripts, "consumers": consumers.stdout.splitlines(),
            "limits": ['Declarations are lexical review aids; compiler ABI reconciliation remains required.',
                       'Source presence does not establish fork verification or deployed identity.']}
    print(json.dumps(data, indent=2))
    if args.check and (changed or untracked or changed_tests or git('merge-base', BASE, 'HEAD') != BASE):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
