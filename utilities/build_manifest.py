#!/usr/bin/env python3

import csv
import hashlib
import subprocess
import sys
from pathlib import Path


def sha256sum(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def git_root(start: Path) -> Path:
    proc = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=start,
        check=True,
        capture_output=True,
        text=True,
    )
    return Path(proc.stdout.strip())


def tracked_files(root: Path) -> list[Path]:
    proc = subprocess.run(
        ["git", "ls-files"],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    )
    files = []
    for line in proc.stdout.splitlines():
        if not line:
            continue
        path = Path(line)
        if path.name == "MANIFEST.tsv":
            continue
        files.append(path)
    return sorted(files)


def record_type(path: Path) -> str:
    if len(path.parts) == 1:
        return "project"
    head = path.parts[0]
    if head in {"ACS5", "ADI", "CDI", "Decennial", "FIPS", "utilities"}:
        return head.lower()
    return "other"


def build_manifest(root: Path, output: Path) -> int:
    rows = []
    for relpath in tracked_files(root):
        abspath = root / relpath
        if not abspath.is_file():
            continue
        rows.append(
            {
                "path": relpath.as_posix(),
                "type": record_type(relpath),
                "size_bytes": str(abspath.stat().st_size),
                "sha256": sha256sum(abspath),
            }
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["path", "type", "size_bytes", "sha256"],
            dialect="excel-tab",
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)

    return 0


def main() -> int:
    start = Path.cwd()
    root = git_root(start)
    output = root / "MANIFEST.tsv"
    if len(sys.argv) > 1:
        output = Path(sys.argv[1])
        if not output.is_absolute():
            output = root / output
    return build_manifest(root, output)


if __name__ == "__main__":
    raise SystemExit(main())
