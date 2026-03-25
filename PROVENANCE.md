# Provenance

This repository publishes a tracked annual release snapshot of the `fairadi`
project. Provenance for a release is established by the combination of:

- the git release reference and repository history
- `MANIFEST.tsv`, which records tracked file paths, sizes, and SHA-256 digests
- the build scripts under `Makefile`, `ACS5/`, `Decennial/`, `FIPS/`, `ADI/`,
  and `utilities/`
- release metadata in `metadata.json` and `CITATION.cff`
- the split-license statements in `LICENSE` and `LICENSE-data`

The reserved Zenodo DOI for the current release record is:

- `10.5281/zenodo.19222629`

The intended git release reference for this release is:

- `v1.0`

## Canonical Released Dataset

The canonical released dataset artifact is:

- `ADI/fairadi.csv.gz`

The column definitions for this file are documented in:

- `ADI/fairadi_data_dictionary.tsv`

## Primary Input Sources

The public-data workflow draws from:

- U.S. Census Bureau American Community Survey 5-year tables in `ACS5/`
- U.S. Census Bureau Decennial Census tables in `Decennial/`
- Census geography inventories and supporting reference files in `FIPS/`

For comparison diagnostics in `ADI/README.Rmd`, the project also references
Neighborhood Atlas files that are not redistributed in this repository.

## Build Relationships

At a high level:

1. `FIPS/` builds geography inventories.
2. `ACS5/` and `Decennial/` build the tracked Census table extracts.
3. `ADI/` builds topic-level derived files, suppression inputs, and the final
   `fairadi.csv.gz` dataset.
4. `MANIFEST.tsv` inventories the tracked release contents.

The top-level workflow is orchestrated by:

- `Makefile`

The final dataset build is orchestrated by:

- `ADI/Makefile`
- `ADI/fairadi.R`

## Integrity Verification

To refresh the tracked-file manifest:

```sh
make manifest
```

To verify any single tracked file against the manifest:

```sh
awk -F '\t' '$1 == "ADI/fairadi.csv.gz" {print $4 "  " $1}' MANIFEST.tsv | shasum -a 256 -c
```

To verify all tracked files listed in the manifest:

```sh
python3 - <<'PY'
import csv
with open("MANIFEST.tsv", newline="", encoding="utf-8") as f:
    r = csv.DictReader(f, dialect="excel-tab")
    for row in r:
        print(f"{row['sha256']}  {row['path']}")
PY
```

Pipe that output to `shasum -a 256 -c` if you want a full integrity check.
