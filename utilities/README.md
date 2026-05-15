# Utilities

This directory contains helper scripts used by the Census download workflow,
file reshaping steps, and Zenodo packaging.

## build_manifest.py

Builds the repository-level `MANIFEST.tsv` file from the current git-tracked
project contents.

```sh
./utilities/build_manifest.py
```

You may optionally provide an alternate output path:

```sh
./utilities/build_manifest.py path/to/MANIFEST.tsv
```

The script uses `git ls-files` to enumerate tracked files and writes a
tab-separated manifest with these columns:

- `path`
- `type`
- `size_bytes`
- `sha256`

This is intended to support release documentation and integrity verification
without hand-maintaining a file inventory.

The generated manifest complements the FAIR-supporting root-level metadata
files:

- `CITATION.cff`
- `metadata.json`
- `PROVENANCE.md`
- `ro-crate-metadata.json`
- `provenance.provn`
- `ADI/fairadi_data_dictionary.tsv`

## validate_provenance.py

Validates the repository's formal provenance file, `provenance.provn`.

```sh
./utilities/validate_provenance.py
```

The validator checks:

- that the file has the expected PROV-N document wrapper
- that required agents, entities, activities, and core relations are present
- that referenced repository files and directories actually exist
- and, when available, that `provconvert` can parse the PROV-N file as an
  optional extra cross-check

The top-level `make validate-provenance` target runs this script. The
`manifest`, `zenodo`, and `release` workflows depend on it so provenance
validation is part of release metadata generation. Installing `provconvert` is
not required.

## validate_ro_crate.py

Validates the repository's `ro-crate-metadata.json` file.

```sh
./utilities/validate_ro_crate.py
```

The validator checks:

- that the RO-Crate JSON parses correctly
- that the RO-Crate 1.2 context and root entities are present
- that required release entities and `CreateAction` entries exist
- that referenced local files and directories actually exist

The top-level `make validate-ro-crate` target runs this script. The
`manifest`, `zenodo`, and `release` workflows depend on it so RO-Crate
validation is part of release metadata generation.

## validate_dcat_us.py

Validates the repository's `dcat-us.json` file.

```sh
./utilities/validate_dcat_us.py
```

The validator checks:

- that the DCAT-US JSON parses correctly
- that the catalog-level required fields are present
- that the main dataset entry is present and structurally complete
- that the expected ADI/CDI distributions are listed

The top-level `make validate-dcat-us` target runs this script. The `manifest`,
`zenodo`, and `release` workflows depend on it so DCAT-US validation is part
of release metadata generation.

## validate_zenodo_package.py

Validates the Zenodo packaging specification and, when present, the built
archive contents.

```sh
./utilities/validate_zenodo_package.py
```

The validator checks:

- that each expected packaging path pattern resolves to real repository files
- that none of the defined archives would be empty
- that any built archives in `zenodo-dist/` contain exactly the expected files
- that the Zenodo `SHA256SUMS` file matches the built archives and README

The `zenodo` target runs this validator after creating the archives.

## check_namespaces.R

R script that verifies the repository's required package namespaces.

```sh
Rscript --vanilla utilities/check_namespaces.R
```

It scans the R and R Markdown files in `ADI/` and `utilities/`, extracts
packages referenced with explicit `pkg::fun` calls, compares the discovered set
to the declared required namespaces, and checks that each required namespace is
installed with `requireNamespace()`.

The script exits nonzero if:

- a package is used via `pkg::` but missing from the declared list
- a package is declared but no longer used via explicit namespace calls
- a declared package is not installed

The current required namespace list is:

- `data.table`
- `digest`
- `ggh4x`
- `ggplot2`
- `kableExtra`
- `knitr`
- `pcaPP`
- `qwraps2`
- `scales`

## import_census_table.R
Defines a useful helper function for importing an ACS5 or Decennial Census
dataset into R.  Expected to be evaluated within either the ADI or CDI
directories.

## census_fetch.sh

Robust wrapper around `curl` for fetching Census files to a specific output
path.

- Usage: `./utilities/census_fetch.sh URL OUTPUT`
- Creates parent directories automatically.
- Retries transient failures.
- Writes successful downloads atomically via a temporary file.
- On failure, preserves the failed payload or error log as `OUTPUT.err`.

This script is intended for use from Makefiles so partially downloaded files do
not get mistaken for valid inputs.

## census_csv_tool.py

Small command-line CSV helper with two subcommands:

- `project`: select and reorder a subset of columns from an input CSV
- `filter`: write only rows where one column matches a requested value

Examples:

```sh
./utilities/census_csv_tool.py project \
  --input source.csv \
  --output subset.csv \
  --columns GEO_ID,NAME,B01003_001E
```

```sh
./utilities/census_csv_tool.py filter \
  --input counties.csv \
  --output colorado.csv \
  --column state \
  --value 08
```

Behavior notes:

- CSV output is written with quoted fields.
- Parent directories for outputs are created automatically.
- The command exits nonzero if required columns are missing.
- The `filter` command removes the output file if no rows match.

## stacktogether.R

R helper script for stacking many same-table `.csv.gz` files from a given year
into one combined CSV.

The script expects a single argument of the form `TABLE__YEAR`, for example:

```sh
Rscript --vanilla utilities/stacktogether.R H1__2020
```

It will:

- find matching `*.csv.gz` files recursively
- restrict matches to the requested year
- read and row-bind them with `data.table::fread`
- normalize selected column names such as `block group` to `block_group`
- drop columns that are entirely `"null"`
- add a numeric `year` column
- sort by geography columns when present
- write `TABLE__YEAR.csv` in the current working directory

This is useful when the workflow first creates many geography-specific extracts
and later needs one combined table.

## zenodo_package.sh
Builds the Zenodo upload bundle for the repository's annual release snapshot.

The recommended workflow is to produce:

- one curated source archive for reproducibility
- one ADI release archive
- one CDI release archive
- one derived-intermediates archive
- one docs-and-metadata archive
- a release README with unpacking instructions
- a `SHA256SUMS` file for integrity checks

Build the release bundle with:

```sh
./utilities/zenodo_package.sh --label vX.Y.Z
```

If `--label` is omitted, the script defaults to the release reference declared
in `metadata.json`, falling back to `git describe` only if that metadata is not
available.

To preview what will be packaged without creating the archives:

```sh
./utilities/zenodo_package.sh --label vX.Y.Z --dry-run
```

By default, the script writes the Zenodo upload set to `zenodo-dist/`.

The current outputs are:

- `fairadi-data-<label>-source.tar.gz`
- `fairadi-data-<label>-adi-release.tar.gz`
- `fairadi-data-<label>-cdi-release.tar.gz`
- `fairadi-data-<label>-derived-intermediates.tar.gz`
- `fairadi-data-<label>-docs-metadata.tar.gz`
- `fairadi-data-<label>-README.txt`
- `fairadi-data-<label>-SHA256SUMS.txt`

This approach is preferred over uploading the raw repository directory because
it:

- separates end-user release data from the reproducibility subset
- keeps the Zenodo file count small
- avoids forcing the Zenodo deposit to mirror the GitHub working layout
- makes checksum verification straightforward after upload and download

Ignored scratch files such as the detailed `FIPS/tracts/` and
`FIPS/block_groups/` working trees are not part of the archival release by
design. They are build-time intermediates rather than required deliverables for
use of the released dataset.

For a Zenodo release, upload the files emitted in `zenodo-dist/`.

## Using the Zenodo Archive

For released datasets, most users should start with:

- `fairadi-data-<label>-adi-release.tar.gz`
- `fairadi-data-<label>-cdi-release.tar.gz`
- `fairadi-data-<label>-docs-metadata.tar.gz`

For reproducibility work, also download:

- `fairadi-data-<label>-source.tar.gz`

If you want the published ADI topic files and CDI component files, also
download:

- `fairadi-data-<label>-derived-intermediates.tar.gz`

To extract one archive:

```sh
tar -xzf fairadi-data-<label>-adi-release.tar.gz
```

If you want to inspect the archive contents before extracting:

```sh
tar -tzf fairadi-data-<label>-adi-release.tar.gz | head
```
