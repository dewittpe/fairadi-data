# fairadi: A FAIR-Compliant U.S. Deprivation Indices Dataset

Workflow for downloading data from the US Census for building Deprivation
Indices.  The focus of this repo is only getting the needed tables from the US
Census and packaging the results in a format for upload to zenodo.

GitHub is the working repository for the code, build scripts, documentation,
and selected tracked artifacts. Zenodo releases are intended to archive a
versioned snapshot of the project.

## Data Source

This dataset includes variables derived from the U.S. Census Bureau’s
American Community Survey (ACS) and Decennial Census.

These data are in the public domain. Source: U.S. Census Bureau.

| Decennial Table | ACS5 Table   | Description                                                 |
| :-------------: | :----------: | :---------------------------------------------------------- |
| P1              | B01003       | Total population                                            |
| P16             | B11012       | Households by type                                          |
|                 | B15003       | Educational attainment                                      |
|                 | B17010       | Poverty status in the past 12 months by age                 |
|                 | B19001       | Household income in the past 12 months                      |
|                 | B19013       | Median household income in the past 12 months               |
|                 | B19083       | Gini Index of Income Inequality                             |
|                 | B19113       | Median family income in the past 12 months                  |
|                 | B23025       | Employment status                                           |
| H1              | B25001       | Housing Units                                               |
| H4              | B25003       | Tenure (owner-occupied vs renter-occupied)                  |
|                 | B25014       | Tenure by occupancy status                                  |
|                 | B25043       | Tenure by year structure built                              |
|                 | B25044       | Tenure by vehicles available                                |
|                 | B25047       | Plumbed facilities for occupied housing units               |
|                 | B25063       | Gross rent                                                  |
|                 | B25064       | Median gross rent                                           |
|                 | B25077       | Median value (owner-occupied housing units)                 |
|                 | B25087       | Mortgage status                                             |
|                 | B25088       | Median monthly housing costs                                |
| P18             | B26001       | Group Quarters                                              |
|                 | B27010       | Types of health insurance coverage by age                   |
|                 | B28002       | Presence and type of Internet subscription in household     |
|                 | C17002       | Ratio of income to poverty level in the past 12 months      |
|                 | C24010       | Occupation by sex and median earnings in the past 12 months |

For the ADI suppression criteria, `fairadi` uses Decennial 2020 block-group
group-quarters values across all modeled years. Public ACS 5-year data do not
provide group-quarters counts at the block-group level, only at the tract
level, so the 2020 Decennial Census is the public source that preserves the
block-group resolution needed for this exclusion rule.

## Running the Workflow

### System Requirements
* GNU Make
* R
* Python 3
* `dos2unix`

R packages used by the workflow and reporting include:
`data.table`, `knitr`, `digest`, `qwraps2`, `kableExtra`, `pcaPP`,
`ggplot2`, `ggh4x`, and `scales`.

### API Key
You will need an API key from the US Census to download data via the US Census
API.  You may request a key, free of charge, from
https://api.census.gov/data/key_signup.html

This workflow expects to find the key as a system environment variable
`USCENSUSAPIKEY`.

The API key is only required when fetching missing Census source files.
If the needed local files already exist in `FIPS/`, `ACS5/`, and `Decennial/`,
you can rebuild downstream outputs without setting `USCENSUSAPIKEY`.

Table metadata JSON downloads do not require an API key, but they are fetched
from the same Census API and are included in the `make acs5`,
`make decennial`, and `make all` workflows.

Additional metadata-only targets are available when you want to refresh table
definitions without re-downloading Census extracts:

- `make acs5-metadata`
- `make decennial-metadata`
- `make census-metadata`

## Repository Layout

- `FIPS/`: reference geography inventories used by the Census download workflow.
- `ACS5/`: ACS 5-year table extracts plus `metadata/<year>/<table>.json`
  definitions fetched from the Census API.
- `Decennial/`: Decennial Census extracts plus
  `metadata/<year>/<table>.json` definitions used for population, housing, and
  group quarters logic.
- `ADI/`: ADI topic scripts, score assembly, validation report, and selected
  derived outputs.
- `utilities/`: helper scripts for fetching and reshaping Census data.
- `CITATION.cff`: citation metadata for the repository and released dataset.
- `metadata.json`: machine-readable dataset metadata for release and archiving.
- `PROVENANCE.md`: release provenance and integrity guidance.
- `MANIFEST.tsv`: generated inventory of tracked project files with file type,
  size in bytes, and SHA-256 digest.

## Manifest

The project includes a generated manifest file, `MANIFEST.tsv`, that inventories
the tracked release contents of the repository. The manifest is built from
`git ls-files`, so it reflects the files that are part of the tracked project
snapshot rather than untracked local scratch files.

Columns in the manifest:

- `path`: path relative to the repository root
- `type`: coarse file grouping inferred from the top-level directory
- `size_bytes`: file size in bytes
- `sha256`: SHA-256 digest of the file contents

Build or refresh the manifest with:

```sh
make manifest
```

The top-level `make all` target also refreshes `MANIFEST.tsv`.

Build the Zenodo upload package with:

```sh
make zenodo
```

This uses the release label declared in `metadata.json`, currently the git
reference `v1.0.0`, when naming the package files. To build the full project
and then package it for Zenodo, use:

```sh
make release
```

## Licensing and Reuse

Repository code is distributed under the BSD 3-Clause license in `LICENSE`.

The upstream U.S. Census Bureau source data used by this workflow are in the
public domain.

This repository uses a split-license model:

- code and build scripts: BSD 3-Clause License in `LICENSE`
- released data artifacts and documentation: CC BY 4.0 in `LICENSE-data`

The tracked derived release artifacts in this repository are distributed with
the repository, and release metadata for citation, provenance, and reuse are
provided in `CITATION.cff`, `metadata.json`, `PROVENANCE.md`, and
`ADI/fairadi_data_dictionary.tsv`.

The reserved Zenodo DOI for the current release is `10.5281/zenodo.19222629`.
