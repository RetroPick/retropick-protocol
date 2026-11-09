#!/usr/bin/env python3
"""Reproduce a provisional, read-only inventory from a pinned Git commit.

No path is considered unused or authorized for deletion by this script.
"""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import subprocess


def git(*args):
    return subprocess.check_output(["git", *args])


def classify(path, kind):
    if kind == "commit":
        return "PINNED_SUBMODULE"
    prefixes = (
        ("evidence/", "HISTORICAL_EVIDENCE"),
        ("contracts/legacy-v2/", "PROTECTED_DEPLOYMENT_PROVENANCE"),
        ("contracts/legacy/v2-kuru/", "PROTECTED_DEPLOYMENT_PROVENANCE"),
        ("deployments/", "PROTECTED_DEPLOYMENT_PROVENANCE"),
        ("apps/web/", "READ_ONLY_REFERENCE"),
        ("apps/example-ui-ux/", "DESIGN_DONOR_REFERENCE"),
        ("research/", "RESEARCH_UNQUALIFIED"),
        ("docs/prism/", "RESEARCH_UNQUALIFIED"),
        ("contracts/src/v2-research-experiment/", "RESEARCH_UNQUALIFIED"),
        ("contracts/src/v3-research-experiment/", "RESEARCH_UNQUALIFIED"),
        ("contracts/lib/", "PINNED_DEPENDENCY"),
        ("contracts/src/v2/", "ACTIVE_CONTRACT_CHANGE_GATED"),
        ("apps/retro-ui/", "CANONICAL_IMPLEMENTATION_CANDIDATE"),
        ("apps/indexer/", "CANONICAL_IMPLEMENTATION_CANDIDATE"),
        ("apps/media-service/", "CANONICAL_IMPLEMENTATION_CANDIDATE"),
        ("apps/referral-service/", "CANONICAL_IMPLEMENTATION_CANDIDATE"),
        ("packages/launchpad-sdk/", "CANONICAL_IMPLEMENTATION_CANDIDATE"),
        ("apps/abi/", "CANONICAL_DERIVED_ABI"),
        (".github/", "TOOLING_INTEGRATION"),
        ("scripts/", "TOOLING_INTEGRATION"),
        ("integrations/", "TOOLING_INTEGRATION"),
        ("docs/", "DOCS_OR_CONTROL_PLANE"),
        ("development/", "DOCS_OR_CONTROL_PLANE"),
        ("decisions/", "DOCS_OR_CONTROL_PLANE"),
        ("goals/", "DOCS_OR_CONTROL_PLANE"),
        (".agent/", "DOCS_OR_CONTROL_PLANE"),
        (".agents/", "DOCS_OR_CONTROL_PLANE"),
    )
    for prefix, name in prefixes:
        if path.startswith(prefix):
            return name
    if path in ("LICENSE", "THIRD_PARTY_NOTICES.md", ".gitmodules"):
        return "PROTECTED_LICENSE_ATTRIBUTION"
    return "UNCERTAIN_NEEDS_REFERENCE_TRACE"


def inspect_tree(revision):
    rows = []
    for item in git("ls-tree", "-r", "-l", "-z", revision).split(b"\0"):
        if not item:
            continue
        meta, path_bytes = item.split(b"\t", 1)
        mode, kind, sha, size = meta.decode("ascii").split()
        path = path_bytes.decode("utf-8", "surrogateescape")
        rows.append((path, kind, sha, None if size == "-" else int(size), classify(path, kind)))
    return sorted(rows, key=lambda r: r[0])


def workspace_graph(rows):
    result = {}
    for path, kind, sha, _, _ in rows:
        if kind != "blob" or not path.endswith("package.json"):
            continue
        if path.startswith(("evidence/", "research/")):
            continue
        try:
            package = json.loads(git("cat-file", "blob", sha))
        except (subprocess.CalledProcessError, UnicodeError, json.JSONDecodeError):
            continue
        if not isinstance(package, dict) or not isinstance(package.get("name"), str):
            continue
        deps = {}
        for field in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
            value = package.get(field, {})
            if not isinstance(value, dict):
                continue
            deps.update({k: v for k, v in value.items() if isinstance(v, str) and v.startswith("workspace:")})
        result[path] = {"name": package["name"], "workspace_dependencies": deps,
                        "scripts": sorted(package.get("scripts", {}))}
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revision", default="HEAD")
    parser.add_argument("--out-dir", type=Path, required=True)
    args = parser.parse_args()
    sha = git("rev-parse", "--verify", args.revision + "^{commit}").decode().strip()
    rows = inspect_tree(sha)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    lines = ["# main_commit=" + sha,
             "# generated_from=git-tree-recursive; provisional path classification; not a delete authorization",
             "path_json\tgit_type\tgit_sha\tcommitted_size_bytes\tprovisional_class\treference_trace"]
    lines.extend("\t".join((json.dumps(path, ensure_ascii=True), kind, blob,
                            "-" if size is None else str(size), category, "NOT_VERIFIED"))
                 for path, kind, blob, size, category in rows)
    (args.out_dir / "TRACKED_FILE_CENSUS.tsv").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (args.out_dir / "WORKSPACE_GRAPH.json").write_text(
        json.dumps(workspace_graph(rows), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    counts = Counter(row[4] for row in rows)
    roots = defaultdict(int)
    blobs = defaultdict(list)
    for path, kind, blob, size, _ in rows:
        roots[path.split("/")[0]] += size or 0
        if kind == "blob":
            blobs[blob].append(path)
    summary = {"baseline_commit": sha, "entries": len(rows), "categories": counts,
               "bytes_by_root": roots, "duplicate_blob_groups": sum(len(v) > 1 for v in blobs.values()),
               "limitations": "Path-only classification; import/runtime/deployment references NOT VERIFIED"}
    (args.out_dir / "SUMMARY.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print("Audited " + str(len(rows)) + " tracked entries at " + sha)


if __name__ == "__main__":
    main()
