# Provenance

This repository publishes a tracked annual release snapshot of the
`fairadi-data`
project. Provenance for a release is established by the combination of:

- the git release reference and repository history
- `MANIFEST.tsv`, which records tracked file paths, sizes, and SHA-256 digests
- the build scripts under `Makefile`, `ACS5/`, `Decennial/`, `FIPS/`, `ADI/`,
  `CDI/`, and `utilities/`
- release metadata in `metadata.json`, `CITATION.cff`, and
  `ro-crate-metadata.json`
- the DCAT-US catalog record in `dcat-us.json`
- the formal PROV-N serialization in `provenance.provn`
- the split-license statements in `LICENSE` and `LICENSE-data`

`MANIFEST.tsv` applies to the tracked repository release snapshot. It does not
describe the tarballs emitted for Zenodo upload. The Zenodo packaging workflow
produces a separate `SHA256SUMS` file for those packaged release artifacts.

The Zenodo DOI for the current release record is:

- `10.5281/zenodo.19222629`

The intended git release reference for this release is:

- `v1.0.0`

## Canonical Released Datasets

The canonical released ADI dataset artifact is:

- `ADI/fairadi.csv.gz`

The column definitions for this file are documented in:

- `ADI/fairadi_data_dictionary.tsv`
- `ADI/fairadi_schema.json`
- `ADI/fairadi_codelists.tsv`

The canonical released CDI dataset artifact is:

- `CDI/faircdi.csv.gz`

The column definitions and row schema for this file are documented in:

- `CDI/faircdi_data_dictionary.tsv`
- `CDI/faircdi_schema.json`

The CDI process documentation is:

- `CDI/README.md`

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
4. `CDI/` builds the total-population / housing-unit replacement flags, the
   18 CDI components, and the current `faircdi.csv.gz` output.
5. `MANIFEST.tsv` inventories the tracked release contents.

The top-level workflow is orchestrated by:

- `Makefile`

The final dataset builds are orchestrated by:

- `ADI/Makefile`
- `ADI/fairadi.R`
- `CDI/Makefile`
- `CDI/faircdi.R`

## Formal Provenance Serialization

The repository also publishes a formal provenance serialization in:

- `provenance.provn`

This file uses the W3C PROV-N notation to describe the release snapshot,
selected generated artifacts, principal build activities, creators, and core
derivation relationships. It is a concise machine-readable complement to this
human-oriented provenance document, not an exhaustive file-by-file execution
log.

Validate the provenance file with:

```sh
make validate-provenance
```

This runs `utilities/validate_provenance.py`, which performs repository-level
consistency checks. If `provconvert` happens to be installed locally, the
script also uses it as an optional extra parse check, but it is not required
for the repository workflow.

## RO-Crate Validation

Validate the RO-Crate metadata with:

```sh
make validate-ro-crate
```

This runs `utilities/validate_ro_crate.py`, which performs repository-level
checks on `ro-crate-metadata.json`, including the required root entities,
selected release resources, action entries, and referenced local paths.

## Integrity Verification

To refresh the tracked-file manifest:

```sh
make manifest
```

This refreshes the repository-snapshot manifest, not the Zenodo package
checksums.

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
