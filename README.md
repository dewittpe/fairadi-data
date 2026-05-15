# fairadi-data: FAIR-Oriented U.S. Deprivation Indices Datasets

Workflow for downloading data from the US Census for building Deprivation
Indices. The focus of this repo is getting the needed tables from the U.S.
Census and packaging release-grade ADI and CDI outputs, along with the
metadata and provenance needed for archiving and reuse.

GitHub is the working repository for the code, build scripts, documentation,
and selected tracked artifacts. Zenodo releases are intended to archive a
versioned snapshot of the project.

## Data Source

This dataset includes variables derived from the U.S. Census Bureau’s
American Community Survey (ACS) and Decennial Census.

These data are in the public domain. Source: U.S. Census Bureau.

| Decennial Year | Decennial Table | ACS5 Table   | ACS5 Years           | ADI Use             | CDI Use              | Description                                                 |
| :------------: | :-------------: | :----------: | :------------------- | :------------------ | :------------------- | :---------------------------------------------------------- |
| 2010, 2020     | P1              | B01003       | 2010-2024            | suppression         | Step 3 flag helper   | Total population                                            |
|                |                 | B15003       | 2012-2024            | topics 01, 02       | components 01, 02    | Educational attainment                                      |
|                |                 | B17010       | 2010-2024            | topic 11            | component 04         | Poverty status in the past 12 months by age                 |
|                |                 | B19001       | 2010-2024            | topic 05            | component 09         | Household income in the past 12 months                      |
|                |                 | B19013       | 2010-2024            | topic 04            | component 10         | Median household income in the past 12 months               |
|                |                 | B19083       | 2010-2024            | none                | none                 | Gini Index of Income Inequality                             |
|                |                 | B23025       | 2011-2024            | topic 10            | component 17         | Employment status                                           |
| 2010, 2020     | H1              | B25001       | 2010-2024            | suppression         | none                 | Housing units                                               |
| 2010, 2020     | H4              | B25003       | 2010-2024            | topic 09            | component 15         | Tenure (owner-occupied vs renter-occupied)                  |
|                |                 | B25014       | 2010-2024            | topic 17            | component 05         | Tenure by occupancy status                                  |
|                |                 | B25043       | 2010-2024            | topic 15 pre-2017   | component 06 pre-2017| Tenure by year structure built                              |
|                |                 | B25044       | 2010-2024            | topic 14            | component 07         | Tenure by vehicles available                                |
|                |                 | B25047       | 2010-2024            | topic 16            | component 08         | Plumbed facilities for occupied housing units               |
|                |                 | B25064       | 2010-2024            | topic 07            | component 11         | Median gross rent                                           |
|                |                 | B25077       | 2010-2024            | topic 06            | component 12         | Median value (owner-occupied housing units)                 |
|                |                 | B25088       | 2010-2024            | topic 08            | component 13         | Median monthly housing costs                                |
| 2020           | P18             | B26001       | 2010-2024            | suppression         | none                 | Group quarters population                                   |
| 2010           | P42             | B26001       | 2010-2024            | suppression         | none                 | Group quarters population                                   |
|                |                 | B27010       | 2013-2024            | none                | component 18         | Types of health insurance coverage by age                   |
|                |                 | B28002       | 2017-2024            | topic 15 2017+      | component 06 2017+   | Presence and type of Internet subscription in household     |
|                |                 | C17002       | 2010-2024            | topic 12            | component 16         | Ratio of income to poverty level in the past 12 months      |
|                |                 | C24010       | 2010-2024            | topic 03            | component 03         | Occupation by sex and median earnings in the past 12 months |

For the ADI suppression criteria, `fairadi` uses Decennial block-group
group-quarters population as the public-data source because public ACS 5-year
data do not provide group-quarters counts at the block-group level. The source
table differs by decennial year: `P42` for `2010` and `P18` for `2020`.

For ADI, `B15003` is required for topics `01` and `02`. In this workflow,
`B15003` is currently available starting in `2012`, so `2010` and `2011`
cannot produce full ADI coverage and are expected to contain mostly `QDI`
block groups rather than complete rankings.

## Running the Workflow

### System Requirements
* GNU Make
* R
* Python 3
* GDAL, including the `ogr2ogr` command-line tool
* `dos2unix`

Optional:
`provconvert` can be present as an additional provenance parse check, but it
is not required for normal repository builds or release validation.

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

For ACS5 block-group extracts, the public Census API workflow applies starting
in `2013`. For `2010` to `2012`, the public API does not support ACS5
block-group geography, so this repository uses the ACS5 Summary File workflow
for those years instead. State, county, and tract ACS5 downloads are not the
reason for that special-case handling.

Additional metadata-only targets are available when you want to refresh table
definitions without re-downloading Census extracts:

- `make acs5-metadata`
- `make decennial-metadata`
- `make census-metadata`
- `make validate-provenance`
- `make validate-ro-crate`
- `make validate-dcat-us`
- `make validate-zenodo-package`

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
- `dcat-us.json`: DCAT-US 3.0 catalog record for the release snapshot and its
  ADI/CDI distributions.
- `FAIR_TODO.md`: concrete next-step FAIR implementation checklist for the
  repository and release artifacts.
- `ro-crate-metadata.json`: attached RO-Crate JSON-LD metadata for the release
  snapshot and its key files, directories, identifiers, creators, and sources.
- `provenance.provn`: formal W3C PROV-N serialization for the release
  snapshot, selected artifacts, build activities, and derivation links.
- `PROVENANCE.md`: release provenance and integrity guidance.
- `MANIFEST.tsv`: generated inventory of tracked project files with file type,
  size in bytes, and SHA-256 digest.

## Metadata and Provenance Files

The repository intentionally uses several metadata and provenance files because
they serve different audiences and standards:

- `CITATION.cff`: citation-focused metadata for GitHub, humans, and citation
  managers.
- `metadata.json`: compact project-specific release summary used by this
  repository's own scripts and release workflow.
- `dcat-us.json`: DCAT-US discovery metadata for catalog-style dataset
  discovery and distribution listing.
- `ADI/fairadi_codelists.tsv`: machine-readable codelists for ADI exclusion,
  note, and replacement-level codes.
- `ro-crate-metadata.json`: standards-based machine-readable package metadata
  describing the release snapshot, its files, and their relationships.
- `MANIFEST.tsv`: integrity inventory of tracked release files with SHA-256
  digests and file sizes.
- `PROVENANCE.md`: human-readable explanation of where the release came from,
  what the canonical artifacts are, and how they relate.
- `provenance.provn`: formal machine-readable provenance graph for the release
  workflow and core derivation relationships.

These files overlap on purpose. The overlap keeps the release usable in
different contexts without forcing one file to do every job.

Validate the RO-Crate metadata with:

```sh
make validate-ro-crate
```

Validate the DCAT-US metadata with:

```sh
make validate-dcat-us
```

## Manifest

The project includes a generated manifest file, `MANIFEST.tsv`, that inventories
the tracked release contents of the repository. The manifest is built from
`git ls-files`, so it reflects the files that are part of the tracked project
snapshot rather than untracked local scratch files.

`MANIFEST.tsv` covers the tracked GitHub repository release snapshot, not the
Zenodo upload archives. The Zenodo packaging step produces its own
`SHA256SUMS.txt` file for the packaged upload artifacts in `zenodo-dist/`.

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

The Zenodo package includes archive-level checksums in
`fairadi-data-<label>-SHA256SUMS.txt`. Those checksums apply to the packaged
Zenodo release files, while `MANIFEST.tsv` applies to the tracked repository
snapshot itself.

This uses the release label declared in `metadata.json`, currently the git
reference `v1.0.0`, when naming the package files. To build the full project
and then package it for Zenodo, use:

```sh
make release
```

## FAIR Implementation Profile Mini-Questionnaire

The repository can answer most of the mini-questionnaire from current tracked
artifacts. Where the project does not yet implement a formal FAIR mechanism,
the answer below says so directly.

### Community Description

| Field | Current answer |
| :---- | :------------- |
| Name of Community | `fairadi` maintainers and reusers of U.S. deprivation index datasets |
| Description of Community | This project supports researchers, analysts, and data stewards building and reusing U.S. Area Deprivation Index (ADI) and Community Deprivation Index (CDI) datasets derived from public U.S. Census inputs. |
| Supporting Links | GitHub repository: `https://github.com/dewittpe/fairadi-data`; Zenodo DOI: `10.5281/zenodo.19222629` |
| Research Domain | Public health, health services research, social determinants of health, and census-derived deprivation measurement |
| Data Steward | Peter DeWitt (`https://orcid.org/0000-0002-6391-0795`); Ardelia Clarke (`https://orcid.org/0000-0001-7253-7171`) |
| Date of FIP creation | `2026-05-14` |

### Questionnaire Answers

| FAIR principle | Question | Current answer in this project | Evidence / notes |
| :------------- | :------- | :----------------------------- | :--------------- |
| `F1` | What globally unique, persistent, resolvable identifiers do you use for metadata records? | Zenodo DOI at the release level: `10.5281/zenodo.19222629` | Declared in `metadata.json`, `CITATION.cff`, `README.md`, and `PROVENANCE.md`. There is not yet a separate PID for each individual metadata file in the repository. |
| `F1` | What globally unique, persistent, resolvable identifiers do you use for datasets? | Zenodo DOI at the released dataset level: `10.5281/zenodo.19222629` | The canonical released datasets are `ADI/fairadi.csv.gz` and `CDI/faircdi.csv.gz`. Internal file paths are stable within a git release, but they are not global persistent identifiers by themselves. |
| `F2` | Which metadata schemas do you use for findability? | RO-Crate 1.2 (`ro-crate-metadata.json`), `CITATION.cff` 1.2.0, project `metadata.json`, and the Zenodo release record | RO-Crate provides standardized machine-readable release metadata. `CITATION.cff` supports repository citation and discovery. `metadata.json` remains a project-specific release summary. |
| `F3` | What is the technology that links the persistent identifiers of your data to the metadata description? | DOI landing page plus RO-Crate / repository metadata files linked by release version and file path | The DOI resolves to the archived release record, while `ro-crate-metadata.json`, `metadata.json`, `CITATION.cff`, `PROVENANCE.md`, and `MANIFEST.tsv` describe the released contents. |
| `F4` | In which search engines are your metadata records indexed? | GitHub repository search and Zenodo record search | Additional external indexing is not yet documented in this repository. |
| `F4` | In which search engines are your datasets indexed? | Zenodo record search and GitHub repository discovery | Dataset-specific search-engine coverage beyond repository/release hosting is not yet documented here. |
| `A1.1` | Which standardized communication protocol do you use for metadata records? | `HTTPS` | Repository, release metadata, and citation metadata are published over standard web protocols. |
| `A1.1` | Which standardized communication protocol do you use for datasets? | `HTTPS` | Released files are distributed through the repository and Zenodo release channel over `HTTPS`. |
| `A1.2` | Which authentication & authorisation technique do you use for metadata records? | None for public access | Repository metadata and release metadata are intended to be publicly readable. |
| `A1.2` | Which authentication & authorisation technique do you use for datasets? | None for public released artifacts; API key for rebuilding upstream source downloads | Released artifacts are public. Rebuilding from the Census API uses `USCENSUSAPIKEY` for source acquisition, but that requirement applies to workflow execution, not public reuse of released outputs. |
| `A2` | Which metadata longevity plan do you use? | Versioned git history, archived Zenodo release DOI, tracked manifest, RO-Crate metadata, and provenance documentation | See `PROVENANCE.md`, `MANIFEST.tsv`, `ro-crate-metadata.json`, `metadata.json`, `CITATION.cff`, and the git release reference `v1.0.0`. |
| `I1` | Which knowledge representation languages (allowing machine interoperation) do you use for metadata records? | JSON-LD, YAML, JSON, and tabular text | `ro-crate-metadata.json` is JSON-LD, `CITATION.cff` is YAML, `metadata.json` and Census metadata files are JSON, and `MANIFEST.tsv` is tabular text. |
| `I1` | Which knowledge representation languages (allowing machine interoperation) do you use for datasets? | CSV/TSV, typically compressed as `.csv.gz` | Primary released and intermediate datasets are tabular files documented by the data dictionary and Census metadata JSON. |
| `I2` | Which structured vocabularies do you use to annotate your metadata records? | DOI, ORCID, SPDX license identifiers, git release tags, Census table identifiers, and FIPS geography codes | These identifiers appear across `CITATION.cff`, `metadata.json`, file names, and repository documentation. |
| `I2` | Which structured vocabularies do you use to encode your datasets? | Census FIPS geography codes, Census table identifiers, and project-defined coded values | Examples include `state`, `county`, `tract`, `block_group`, table names such as `B01003`, and dataset codes such as `PH`, `GQ`, `GQ-PH`, and `QDI`. |
| `I3` | Which models, schema(s) do you use for your metadata records? | RO-Crate 1.2, `CITATION.cff` 1.2.0, project `metadata.json`, and `MANIFEST.tsv` | Provenance and release structure are further described in `PROVENANCE.md`. |
| `I3` | Which models, schema(s) do you use for your datasets? | Flat tabular schemas documented in `ADI/fairadi_data_dictionary.tsv` and `CDI/faircdi_data_dictionary.tsv`, plus `ADI/fairadi_schema.json`, `CDI/faircdi_schema.json`, and Census source table definitions in `ACS5/metadata/` and `Decennial/metadata/` | The canonical released dataset artifacts are `ADI/fairadi.csv.gz` and `CDI/faircdi.csv.gz`. |
| `R1.1` | Which usage license do you use for your metadata records? | `CC BY 4.0` for repository data/documentation metadata; `BSD-3-Clause` for code-related repository artifacts | The repository uses a split-license model documented in `LICENSE` and `LICENSE-data`. |
| `R1.1` | Which usage license do you use for your datasets? | `CC BY 4.0` for released derived datasets; upstream Census source data are public domain | See `LICENSE-data` and the licensing section below. |
| `R1.2` | Which metadata schemas do you use for describing the provenance of your metadata records? | W3C PROV-N (`provenance.provn`), RO-Crate 1.2, plus project-specific provenance documentation in `PROVENANCE.md`, `metadata.json`, `CITATION.cff`, git history, and `MANIFEST.tsv` | The PROV-N file provides a formal machine-readable provenance graph for the release snapshot and core relationships. |
| `R1.2` | Which metadata schemas do you use for describing the provenance of your datasets? | W3C PROV-N (`provenance.provn`), RO-Crate 1.2 with explicit build actions, and project-specific provenance documentation using build scripts, `PROVENANCE.md`, `MANIFEST.tsv`, and release metadata | Build relationships are documented in the top-level `Makefile`, subdirectory `Makefile`s, workflow scripts, the formal PROV-N serialization, and RO-Crate `CreateAction` entities. |

### Gaps and Recommended Additions

The questionnaire also highlights FAIR features that are only partially
implemented today. If the project wants stronger machine-actionable FAIR
support, the next additions should be:

- document any confirmed third-party indexing targets beyond GitHub and Zenodo
- decide whether individual released files need their own persistent
  identifiers in addition to the release-level DOI
- map project-defined dataset codes to a documented controlled vocabulary where
  appropriate

## Licensing and Reuse

Repository code is distributed under the BSD 3-Clause license in `LICENSE`.

The upstream U.S. Census Bureau source data used by this workflow are in the
public domain.

This repository uses a split-license model:

- code and build scripts: BSD 3-Clause License in `LICENSE`
- released data artifacts and documentation: CC BY 4.0 in `LICENSE-data`

The tracked derived release artifacts in this repository are distributed with
the repository, and release metadata for citation, provenance, and reuse are
provided in `CITATION.cff`, `metadata.json`, `PROVENANCE.md`,
`ADI/fairadi_data_dictionary.tsv`, `ADI/fairadi_schema.json`,
`CDI/faircdi_data_dictionary.tsv`, and `CDI/faircdi_schema.json`.

The Zenodo DOI for the current release is `10.5281/zenodo.19222629`.
