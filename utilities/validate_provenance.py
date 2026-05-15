#!/usr/bin/env python3

import re
import shutil
import subprocess
import sys
from pathlib import Path


PROVN_PATH = Path("provenance.provn")

REQUIRED_AGENTS = {
    "orcid:0000-0002-6391-0795",
    "orcid:0000-0001-7253-7171",
    "ex:org/zenodo",
}

REQUIRED_ENTITIES = {
    "ex:repo/v1.0.0",
    "doi:10.5281/zenodo.19222629",
    "ex:file/ADI/fairadi.csv.gz",
    "ex:file/ADI/fairadi_schema.json",
    "ex:file/ADI/fairadi_codelists.tsv",
    "ex:file/ADI/fairadi_data_dictionary.tsv",
    "ex:file/CDI/faircdi.csv.gz",
    "ex:file/CDI/faircdi_data_dictionary.tsv",
    "ex:file/CDI/faircdi_schema.json",
    "ex:file/MANIFEST.tsv",
    "ex:file/metadata.json",
    "ex:file/dcat-us.json",
    "ex:file/CITATION.cff",
    "ex:file/ro-crate-metadata.json",
    "ex:file/PROVENANCE.md",
    "ex:file/provenance.provn",
    "ex:file/Makefile",
    "ex:file/ADI/Makefile",
    "ex:file/ADI/fairadi.R",
    "ex:file/CDI/Makefile",
    "ex:file/CDI/faircdi.R",
    "ex:file/utilities/build_manifest.py",
    "ex:dir/FIPS",
    "ex:dir/ACS5",
    "ex:dir/Decennial",
    "ex:dir/ADI",
    "ex:dir/CDI",
    "ex:dir/utilities",
}

REQUIRED_ACTIVITIES = {
    "ex:activity/build-adi-v1.0.0",
    "ex:activity/build-cdi-v1.0.0",
    "ex:activity/build-manifest-v1.0.0",
    "ex:activity/package-release-v1.0.0",
    "ex:activity/register-doi-v1.0.0",
}

REQUIRED_RELATIONS = (
    "used(ex:activity/build-adi-v1.0.0, ex:dir/FIPS",
    "used(ex:activity/build-adi-v1.0.0, ex:dir/ACS5",
    "used(ex:activity/build-adi-v1.0.0, ex:dir/Decennial",
    "used(ex:activity/build-cdi-v1.0.0, ex:dir/ACS5",
    "wasGeneratedBy(ex:file/ADI/fairadi.csv.gz, ex:activity/build-adi-v1.0.0",
    "wasGeneratedBy(ex:file/CDI/faircdi.csv.gz, ex:activity/build-cdi-v1.0.0",
    "wasGeneratedBy(ex:file/MANIFEST.tsv, ex:activity/build-manifest-v1.0.0",
    "wasGeneratedBy(ex:repo/v1.0.0, ex:activity/package-release-v1.0.0",
    "wasGeneratedBy(doi:10.5281/zenodo.19222629, ex:activity/register-doi-v1.0.0",
    "wasAssociatedWith(ex:activity/package-release-v1.0.0, orcid:0000-0002-6391-0795)",
    "wasAssociatedWith(ex:activity/package-release-v1.0.0, orcid:0000-0001-7253-7171)",
)


def git_root(start: Path) -> Path:
    proc = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=start,
        check=True,
        capture_output=True,
        text=True,
    )
    return Path(proc.stdout.strip())


def parse_ids(text: str, keyword: str) -> set[str]:
    pattern = re.compile(rf"^\s*{re.escape(keyword)}\(([^,\s]+)", re.MULTILINE)
    return set(pattern.findall(text))


def repo_path_for_identifier(identifier: str) -> Path | None:
    if identifier.startswith("ex:file/"):
        return Path(identifier.removeprefix("ex:file/"))
    if identifier.startswith("ex:dir/"):
        return Path(identifier.removeprefix("ex:dir/"))
    return None


def validate_with_provconvert(root: Path) -> tuple[list[str], bool]:
    provconvert = shutil.which("provconvert")
    if not provconvert:
        return [], False

    proc = subprocess.run(
        [provconvert, "-infile", str(root / PROVN_PATH), "-informat", "provn", "-outfile", "/dev/null"],
        capture_output=True,
        text=True,
    )
    if proc.returncode == 0:
        return [], True

    message = proc.stderr.strip() or proc.stdout.strip() or "provconvert validation failed"
    return [message], True


def validate(root: Path) -> tuple[list[str], bool]:
    errors: list[str] = []
    provn_path = root / PROVN_PATH
    text = provn_path.read_text(encoding="utf-8")

    if not text.lstrip().startswith("document"):
        errors.append("provenance.provn does not start with 'document'")
    if not text.rstrip().endswith("endDocument"):
        errors.append("provenance.provn does not end with 'endDocument'")

    agents = parse_ids(text, "agent")
    entities = parse_ids(text, "entity")
    activities = parse_ids(text, "activity")

    missing_agents = REQUIRED_AGENTS - agents
    missing_entities = REQUIRED_ENTITIES - entities
    missing_activities = REQUIRED_ACTIVITIES - activities

    for identifier in sorted(missing_agents):
        errors.append(f"missing required agent: {identifier}")
    for identifier in sorted(missing_entities):
        errors.append(f"missing required entity: {identifier}")
    for identifier in sorted(missing_activities):
        errors.append(f"missing required activity: {identifier}")

    for relation in REQUIRED_RELATIONS:
        if relation not in text:
            errors.append(f"missing required relation: {relation}...)")

    for identifier in sorted(REQUIRED_ENTITIES):
        path = repo_path_for_identifier(identifier)
        if path is None:
            continue
        full_path = root / path
        if identifier.startswith("ex:file/") and not full_path.is_file():
            errors.append(f"referenced file does not exist: {path.as_posix()}")
        if identifier.startswith("ex:dir/") and not full_path.is_dir():
            errors.append(f"referenced directory does not exist: {path.as_posix()}")

    provconvert_errors, used_provconvert = validate_with_provconvert(root)
    errors.extend(provconvert_errors)
    return errors, used_provconvert


def main() -> int:
    root = git_root(Path.cwd())
    errors, used_provconvert = validate(root)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    if used_provconvert:
        print("Validated provenance.provn with repository checks and optional provconvert parsing.")
    else:
        print("Validated provenance.provn with repository checks.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
