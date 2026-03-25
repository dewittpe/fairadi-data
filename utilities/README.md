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
- `ADI/fairadi_data_dictionary.tsv`

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
The repository now tracks the annual release snapshot intended for downstream
use, so the Zenodo deposit can be a single source snapshot of the tagged git
state rather than a collection of separate data archives.

The recommended workflow is to produce:

- one source archive from the git-tracked tree
- a release README with unpacking instructions
- a `SHA256SUMS` file for integrity checks

Build the release bundle with:

```sh
./utilities/zenodo_package.sh --label vX.Y.Z
```

To preview what will be packaged without creating the archives:

```sh
./utilities/zenodo_package.sh --label vX.Y.Z --dry-run
```

By default, the script writes the Zenodo upload set to `zenodo-dist/`.

This approach is preferred over uploading the raw repository directory because
it:

- excludes `.git/` automatically from the source snapshot
- keeps the Zenodo upload set minimal
- makes checksum verification straightforward after upload and download

Ignored scratch files such as the detailed `FIPS/tracts/` and
`FIPS/block_groups/` working trees are not part of the archival release by
design. They are build-time intermediates rather than required deliverables for
use of the released dataset.

For a Zenodo release, upload the files emitted in `zenodo-dist/`.

## Using the Zenodo Archive

After downloading `fairadi-<label>-source.tar.gz` from Zenodo, extract it with:

```sh
tar -xzf fairadi-<label>-source.tar.gz
```

This will create a top-level directory named `fairadi-<label>/`.

If you want to inspect the archive contents before extracting:

```sh
tar -tzf fairadi-<label>-source.tar.gz | head
```

### File Structure After Extraction

After extraction, the tree will look like:

```text
fairadi-<label>/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── Makefile
├── Makevars
├── ACS5/
├── ADI/
├── Decennial/
├── FIPS/
└── utilities/
```

Directory summary:

- `ACS5/`: American Community Survey 5-year input tables and geography-level extracts.
- `ADI/`: deprivation index scripts, derived topic files, final ADI output, and figures.
- `Decennial/`: Decennial Census input tables and derived geography-level extracts.
- `FIPS/`: reference geography inventories and supporting lookup files used by the build workflow.
- `utilities/`: helper scripts for data fetch, reshaping, and packaging tasks.

The archive does not include the local `.git/` directory or ignored scratch files.
