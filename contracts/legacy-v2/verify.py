"""Read-only verification of archived files against recorded Git blobs."""
import hashlib
import json
from pathlib import Path
import subprocess


def main():
    root = Path(__file__).resolve().parent
    manifest = json.loads((root / "MANIFEST.json").read_text())
    repo = root.parent.parent
    checked = set()
    for record in manifest["files"]:
        path = root / record["archivePath"]
        data = path.read_bytes()
        expected = subprocess.check_output(
            ["git", "show", record["revision"] + ":" + record["originalPath"]], cwd=repo
        )
        blob = subprocess.check_output(
            ["git", "hash-object", "--stdin"], input=data, cwd=repo, text=False
        ).decode().strip()
        if (data != expected or blob != record["gitBlob"]
                or len(data) != record["bytes"]
                or hashlib.sha256(data).hexdigest() != record["sha256"]):
            raise SystemExit("FAIL: " + record["archivePath"])
        checked.add(record["archivePath"])
    actual_sources = {str(p.relative_to(root)) for p in (root / "src").rglob("*.sol")}
    expected_sources = {p for p in checked if p.startswith("src/")}
    if actual_sources != expected_sources or len(actual_sources) != manifest["sourceFiles"]:
        raise SystemExit("FAIL: source file inventory differs")
    print(f"PASS: {len(actual_sources)} Solidity files; {len(checked)} archived files match Git and SHA-256")
    print("Historical source preservation only; no fresh onchain verification or deployment.")


if __name__ == "__main__":
    main()
