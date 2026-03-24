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
|                 | B19113       | Median family income in the past 12 months                  |
|                 | B23025       | Employment status                                           |
| H1              | B25001       | Housing Units                                               |
| H4              | B25003       | Tenure (owner-occupied vs renter-occupied)                  |
|                 | B25014       | Tenure by occupancy status                                  |
|                 | B25043       | Tenure by year structure built                              |
|                 | B25044       | Tenure by vehicles available                                |
|                 | B25047       | Plumbed facilities for occupied housing units               |
|                 | B25063       | Gross rent                                                  |
|                 | B25077       | Median value (owner-occupied housing units)                 |
|                 | B25087       | Mortgage status                                             |
| P18             | B26001       | Group Quarters                                              |
|                 | B28002       | Presence and type of Internet subscription in household     |
|                 | C17002       | Ratio of income to poverty level in the past 12 months      |
|                 | C24010       | Occupation by sex and median earnings in the past 12 months |
|                 | B19083       | Gini Index of Income Inequality                             |

## Running the Workflow

### System Requirements
* GNU Make
* R
* Python 3
* `dos2unix`

R packages used by the workflow and reporting include:
`data.table`, `knitr`, `digest`, `qwraps2`, `kableExtra`, `pcaPP`,
`ggplot2`, `scales`, `ggplotify`, and `gridExtra`.

### API Key
You will need an API key from the US Census to download data via the US Census
API.  You may request a key, free of charge, from
https://api.census.gov/data/key_signup.html

This workflow expects to find the key as a system environment variable
`USCENSUSAPIKEY`.

The API key is only required when fetching missing Census source files.
If the needed local files already exist in `FIPS/`, `ACS5/`, and `Decennial/`,
you can rebuild downstream outputs without setting `USCENSUSAPIKEY`.

## Repository Layout

- `FIPS/`: reference geography inventories used by the Census download workflow.
- `ACS5/`: ACS 5-year table extracts used to build the deprivation measures.
- `Decennial/`: Decennial Census extracts used for population, housing, and
  group quarters logic.
- `ADI/`: ADI topic scripts, score assembly, validation report, and selected
  derived outputs.
- `utilities/`: helper scripts for fetching and reshaping Census data.
