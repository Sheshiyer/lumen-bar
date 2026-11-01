#!/bin/zsh
# Writes .local/release-manifest.json after a verified local package.
# It does not create a tag, upload assets, or call GitHub.
set -euo pipefail
here=${0:A:h:h}
cd "$here"

[[ -z "$(git status --porcelain)" ]] || { echo "release manifest needs a clean worktree"; exit 1; }
version=$(tr -d '[:space:]' < VERSION)
commit=$(git rev-parse HEAD)
mkdir -p .local

python3 - "$version" "$commit" <<'PY'
import hashlib
import json
import pathlib
import subprocess
import sys

version, commit = sys.argv[1:3]
root = pathlib.Path.cwd()
artifacts = []
for name in (f"LumenBar-{version}.zip", f"LumenBar-{version}.dmg"):
    path = root / "dist" / name
    if not path.is_file():
        raise SystemExit(f"missing artifact: {path.relative_to(root)}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    # The zip carries the stapled app; the disk image carries its own ticket.
    target = root / "dist" / "LumenBar.app" if name.endswith(".zip") else path
    stapled = subprocess.run(["xcrun", "stapler", "validate", str(target)], capture_output=True)
    trust = "stapled" if stapled.returncode == 0 else "signed"
    artifacts.append({"name": name, "bytes": path.stat().st_size, "sha256": digest, "trust": trust})

manifest = {
    "schema": "github-release-manifest.v1",
    "repository": "Sheshiyer/lumen-bar",
    "commit": commit,
    "baseRef": "origin/main",
    "version": version,
    "tag": f"v{version}",
    "changelogPath": "README.md",
    "dirty": False,
    "publication": "held",
    "artifacts": artifacts,
}
(root / ".local" / "release-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(".local/release-manifest.json")
PY
