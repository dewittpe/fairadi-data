#!/usr/bin/env python3

import argparse
import hashlib
import json
import subprocess
import sys
import tarfile
from pathlib import Path


DEFAULT_OUTPUT_DIR = "zenodo-dist"

SOURCE_PATTERNS = [
    "CHANGELOG.md",
    "README.md",
    "CITATION.cff",
    "metadata.json",
    "dcat-us.json",
    "ro-crate-metadata.json",
    "provenance.provn",
    "PROVENANCE.md",
    "LICENSE",
    "LICENSE-data",
    "Makefile",
    "Makevars",
    "FIPS/Makefile",
    "FIPS/README.md",
    "ACS5/Makefile",
    "ACS5/block_group/Makefile",
    "ACS5/county/Makefile",
    "ACS5/state/Makefile",
    "ACS5/tract/Makefile",
    "Decennial/Makefile",
    "Decennial/block_group/Makefile",
    "Decennial/county/Makefile",
    "Decennial/state/Makefile",
    "Decennial/tract/Makefile",
    "ADI/Makefile",
    "ADI/README.md",
    "ADI/README.Rmd",
    "ADI/fairadi_data_dictionary.tsv",
    "ADI/fairadi_schema.json",
    "ADI/*.R",
    "CDI/Makefile",
    "CDI/README.md",
    "CDI/README.Rmd",
    "CDI/2025-08-28-team-cdi-calculation-specifications.pdf",
    "CDI/faircdi_data_dictionary.tsv",
    "CDI/faircdi_schema.json",
    "CDI/*.R",
    "utilities/README.md",
    "utilities/*.R",
    "utilities/*.py",
    "utilities/*.sh",
]

ADI_RELEASE_PATTERNS = [
    "ADI/fairadi.csv.gz",
    "ADI/fairadi_data_dictionary.tsv",
    "ADI/fairadi_schema.json",
]

CDI_RELEASE_PATTERNS = [
    "CDI/faircdi.csv.gz",
    "CDI/faircdi_data_dictionary.tsv",
    "CDI/faircdi_schema.json",
]

DERIVED_PATTERNS = [
    "ADI/topic*.csv.gz",
    "CDI/component*.csv.gz",
]

DOCS_PATTERNS = [
    "README.md",
    "ADI/README.md",
    "CDI/README.md",
    "CITATION.cff",
    "metadata.json",
    "dcat-us.json",
    "ro-crate-metadata.json",
    "provenance.provn",
    "PROVENANCE.md",
    "LICENSE",
    "LICENSE-data",
    "MANIFEST.tsv",
]


def git_root(start: Path) -> Path:
    proc = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=start,
        check=True,
        capture_output=True,
        text=True,
    )
    return Path(proc.stdout.strip())


def default_label(root: Path) -> str:
    path = root / "metadata.json"
    if path.exists():
        metadata = json.loads(path.read_text(encoding="utf-8"))
        return metadata.get("provenance", {}).get("git_ref", f"v{metadata['version']}")
    proc = subprocess.run(
        ["git", "describe", "--tags", "--always", "--dirty"],
        cwd=root,
        capture_output=True,
        text=True,
        check=True,
    )
    return proc.stdout.strip()


def collect_paths(root: Path, patterns: list[str]) -> list[str]:
    seen = set()
    paths: list[str] = []
    for pattern in patterns:
        for path in sorted(root.glob(pattern)):
            rel = path.relative_to(root).as_posix()
            if rel not in seen:
                seen.add(rel)
                paths.append(rel)
    return paths


def expected_archives(root: Path, label: str) -> dict[str, list[str]]:
    prefix = f"fairadi-data-{label}"
    return {
        f"{prefix}-source.tar.gz": collect_paths(root, SOURCE_PATTERNS),
        f"{prefix}-adi-release.tar.gz": collect_paths(root, ADI_RELEASE_PATTERNS),
        f"{prefix}-cdi-release.tar.gz": collect_paths(root, CDI_RELEASE_PATTERNS),
        f"{prefix}-derived-intermediates.tar.gz": collect_paths(root, DERIVED_PATTERNS),
        f"{prefix}-docs-metadata.tar.gz": collect_paths(root, DOCS_PATTERNS),
    }


def sha256sum(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate(root: Path, output_dir: Path, label: str) -> list[str]:
    errors: list[str] = []
    expected = expected_archives(root, label)
    prefix = f"fairadi-data-{label}"

    for archive_name, members in expected.items():
        if not members:
            errors.append(f"{archive_name} would be empty")
        for member in members:
            if not (root / member).exists():
                errors.append(f"expected packaged path does not exist: {member}")

        archive_path = output_dir / archive_name
        if archive_path.exists():
            with tarfile.open(archive_path, "r:gz") as tf:
                actual = sorted(m.name for m in tf.getmembers() if m.isfile())
            if sorted(members) != actual:
                errors.append(f"{archive_name} contents do not match the packaging specification")

    readme_path = output_dir / f"{prefix}-README.txt"
    sha_path = output_dir / f"{prefix}-SHA256SUMS.txt"
    archive_paths = [output_dir / name for name in expected]

    if any(path.exists() for path in archive_paths):
        missing = [path.name for path in archive_paths if not path.exists()]
        if missing:
            errors.append(f"missing built archive(s): {', '.join(sorted(missing))}")
        if not readme_path.exists():
            errors.append(f"missing built README file: {readme_path.name}")
        if not sha_path.exists():
            errors.append(f"missing checksum file: {sha_path.name}")

    if sha_path.exists():
        expected_hashes = {}
        for line in sha_path.read_text(encoding="utf-8").splitlines():
            digest, filename = line.split("  ", 1)
            expected_hashes[filename] = digest
        for path in archive_paths + [readme_path]:
            if not path.exists():
                continue
            digest = sha256sum(path)
            if expected_hashes.get(path.name) != digest:
                errors.append(f"checksum mismatch for {path.name}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--label")
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    args = parser.parse_args()

    root = git_root(Path.cwd())
    label = args.label or default_label(root)
    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = root / output_dir

    errors = validate(root, output_dir, label)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Validated Zenodo package specification and any built archives.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
