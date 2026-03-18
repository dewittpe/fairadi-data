# US Census Data for Deprivation Indices

Workflow for downloading data from the US Census for building Deprivation
Indices.  The focus of this repo is only getting the needed tables from the US
Census and packaging the results in a format for upload to zenodo.

## Running the Workflow

### System Requirements
* GNU Make

### API Key
You will need an API key from the US Census.
Request a key from https://api.census.gov/data/key_signup.html

This workflow expects to find the key as a system environment variable
`USCENSUSAPIKEY`.

## Data Source

This dataset includes variables derived from the U.S. Census Bureau’s
American Community Survey (ACS) and Decennial Census.

These data are in the public domain. Source:
U.S. Census Bureau.

## Disclaimer

This dataset includes variables derived from the U.S. Census Bureau’s
American Community Survey (ACS). The derived indices are the author’s
own calculations and are not produced or endorsed by the Census Bureau.
