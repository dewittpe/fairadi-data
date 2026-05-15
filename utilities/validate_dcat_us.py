#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path


DCAT_PATH = Path("dcat-us.json")


def git_root(start: Path) -> Path:
    proc = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=start,
        check=True,
        capture_output=True,
        text=True,
    )
    return Path(proc.stdout.strip())


def validate(root: Path) -> list[str]:
    errors: list[str] = []
    path = root / DCAT_PATH
    try:
      data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
      return [f"invalid JSON in {DCAT_PATH}: {exc}"]

    required_catalog_fields = [
        "@id",
        "@type",
        "conformsTo",
        "title",
        "description",
        "dataset",
    ]
    for field in required_catalog_fields:
        if field not in data:
            errors.append(f"dcat-us.json is missing required catalog field {field}")

    if data.get("@type") != "dcat:Catalog":
        errors.append("dcat-us.json should have @type dcat:Catalog")

    conforms_to = data.get("conformsTo", {})
    if conforms_to.get("identifier") != "https://resources.data.gov/dcat-us/3.0.0":
        errors.append("dcat-us.json should declare DCAT-US 3.0 in conformsTo.identifier")

    datasets = data.get("dataset")
    if not isinstance(datasets, list) or not datasets:
        errors.append("dcat-us.json should contain at least one dataset entry")
        return errors

    dataset = datasets[0]
    for field in ["@type", "title", "description", "identifier", "publisher", "contactPoint", "distribution"]:
        if field not in dataset:
            errors.append(f"dataset entry is missing required field {field}")

    if dataset.get("@type") != "Dataset":
        errors.append("dataset entry should have @type Dataset")

    distributions = dataset.get("distribution", [])
    if not isinstance(distributions, list) or not distributions:
        errors.append("dataset entry should contain at least one distribution")
        return errors

    distribution_titles = {dist.get("title") for dist in distributions if isinstance(dist, dict)}
    expected_titles = {
        "ADI release dataset",
        "ADI data dictionary",
        "ADI row schema",
        "CDI release dataset",
        "CDI data dictionary",
        "CDI row schema",
        "Repository release metadata bundle",
    }
    missing_titles = expected_titles - distribution_titles
    for title in sorted(missing_titles):
        errors.append(f"dcat-us.json is missing expected distribution {title}")

    for dist in distributions:
        if not isinstance(dist, dict):
            errors.append("dataset distribution contains a non-object entry")
            continue
        for field in ["@type", "title", "downloadURL", "license"]:
            if field not in dist:
                errors.append(f"distribution is missing required field {field}")

    return errors


def main() -> int:
    root = git_root(Path.cwd())
    errors = validate(root)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Validated dcat-us.json with repository checks.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
