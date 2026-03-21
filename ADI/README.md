# Area Depredation Index



The Area Depredation Index (ADI)

* defined in Kind et.al. (2014) https://doi.org/10.7326/m13-2946

* A well referenced and commonly used source for the ADI is from [Neighborhood
  Atlas](https://www.neighborhoodatlas.medicine.wisc.edu/)

The work in this directory is an attempt to reproduce the ADI as published by
Neighborhood Atlas.

In general, the ADI is defined at the United States Census Block Group level
using data from the American Community Survey Five-Year (ACS5) data.

| Topic  | Topic Area                                 | ACS5 Detailed Table ID   | Specific Variables / Calculation                                                                  |
| ---    | ------------                               | -------------------      | ----------------------------------                                                                |
| 1      | % Pop ≥ 25 yrs with < 9 yrs Education      | B15003                   | Numerator: Sum _002 to _012. Denominator: B15003_001                                              |
| 2      | % Pop ≥ 25 yrs with >= High School Diploma | B15003                   | Numerator: Sum _002 to _016. Denominator: B15003_001. 1 - (sum() / D)                             |
| 3      | % Employed ≥ 16 yrs in White-Collar Occs.  | C24010                   | Numerator: Sum _003 to _013 (Male) and _039 to _049 (Female). Denominator: C24010_001             |
| 4      | Median Family Income                       | B19113                   | Use B19113_001                                                                                    |
| 5      | Income Disparity (Singh Index)             | B19001                   | Numerator: B19001_002. Denominator: Sum B19001_011 to B19001_017. Calculate: log(100 × Num / Den) |
| 6      | Median Home Value                          | B25077                   | Use B25077_001                                                                                    |
| 7      | Median Gross Rent                          | B25063                   | Use B25063_001                                                                                    |
| 8      | Median Monthly Mortgage                    | B25087                   | Use B25087_001                                                                                    |
| 9      | Home Ownership Rate (% Owner-Occupied)     | B25003                   | Numerator: B25003_002. Denominator: B25003_001                                                    |
| 10     | Unemployment Rate (% Civilian Labor Force) | B23025                   | Numerator: B23025_005. Denominator: B23025_002                                                    |
| 11     | % Families Below Poverty Level             | B17010                   | Numerator: B17010_002. Denominator: B17010_001                                                    |
| 12     | % Pop Below 150% of Poverty Threshold      | C17002                   | Numerator: Sum _002 through _005. Denominator: C17002_001                                         |
| 13     | % One-Parent Households (Children < 18)    | B11012                   | Numerator: B11012_010 + B11012_015. Denominator: B11012_001                                       |
| 14     | % Households Without a Motor Vehicle       | B25044                   | Numerator: B25044_003 + B25044_010. Denominator: B25044_001                                       |
| 15-old | % Households Without a Telephone           | B25043                   | Numerator: B25043_004. Denominator: B25043_001                                                    |
| 15-new | % Households Without internet              | B28002                   | Numerator: B28002_013. Denominator: B28002_001                                                    |
| 16     | % Units Without Complete Plumbing          | B25047                   | Numerator: B25047_003. Denominator: B25047_001                                                    |
| 17     | % Crowding (> 1.00 Person Per Room)        | B25014                   | Numerator: Sum _005, _006, _011, _012. Denominator: B25014_001                                    |

Neighborhood Atlas also [uses block group suppression](https://www.neighborhoodatlas.medicine.wisc.edu/changelog#:~:text=Changes%20between%20versions%20of%20the%20ADI%2C%2011/19/2020)
before building the state and national rankings.

> Block group suppression: We have applied the same Diez Roux suppression
> criteria used in the earlier 2013 and 2015 builds: any block group with fewer
> than 100 persons, fewer than 30 housing units, or greater than 33% of the
> population living in group quarters will not receive an ADI ranking. In
> addition, we have suppressed of a small number of block groups which include
> those with survey errors acknowledged by the US Census Bureau.

Tables from the United States Census used to build the suppression criteria
include those from the ACS5 and from the Decennial census.  In particular,
grouped quarters are available at the block group level in the Decennial census
but are not available at the block group level, only the tract level, for the
ACS5 data.

| Topic            | Decennial Table | ACS5 Table |
| :----            | :----:          | :----:     |
| Total Population | P1              | B01003     |
| Group Quaters    | P18             |            |
| Housing Units    |                 | B25001     |

## Workflow

In this directory there are R script for each of the ADI topics and one for
building the ADI score and rankings.

## Diagnostics of the Reproduction

### Neighborhood Atlas Data

You will need to get your own copy of the [Neighborhood
Atlas](https://www.neighborhoodatlas.medicine.wisc.edu/)
data sets. They are for public use.  However, Neighborhood Atlas asks that you
create an account with them before downloading the data.

- University of Wisconsin School of Medicine and Public Health. 2020 Area Deprivation Index v4.0.1. Downloaded from https://www.neighborhoodatlas.medicine.wisc.edu/ March 20 2026
- University of Wisconsin School of Medicine and Public Health. 2023 Area Deprivation Index v4.0.1. Downloaded from https://www.neighborhoodatlas.medicine.wisc.edu/ March 20 2026

For my work I have saved the path to thses files as envirnment variables.


``` r
stopifnot(
  file.exists(Sys.getenv("NEIGHBORHOOD_ATLAS_ADI_2020_V401")),
  file.exists(Sys.getenv("NEIGHBORHOOD_ATLAS_ADI_2023_V401"))
)
digest::digest(Sys.getenv("NEIGHBORHOOD_ATLAS_ADI_2020_V401"), algo = "sha256")
## [1] "a86448b07bd3d32dac4ee07d532924a6aa320ea445a665435f4aaf8139bad628"
digest::digest(Sys.getenv("NEIGHBORHOOD_ATLAS_ADI_2023_V401"), algo = "sha256")
## [1] "5a7532cf8e4e2e6168b8d0f0329ae7a0b557e7476669c8274b54d42ac2331c0d"
```
Import the Neighborhood Atlas 2020 and 2023 data.

``` r
neighborhood_atlas <-
  list(
    "2020" = data.table::fread(Sys.getenv("NEIGHBORHOOD_ATLAS_ADI_2020_V401"), colClasses = "character"),
    "2023" = data.table::fread(Sys.getenv("NEIGHBORHOOD_ATLAS_ADI_2023_V401"), colClasses = "character")
  ) |>
  data.table::rbindlist(idcol = "year", fill = TRUE, use.names = TRUE)
neighborhood_atlas[, year := as.integer(year)]
neighborhood_atlas[, V1 := NULL]
neighborhood_atlas[, GISJOIN := NULL]

# set the ADI_STATERNK and ADI_NATRANK to numeric values
neighborhood_atlas[, neighborhood_atlas_exclude_reason := data.table::fifelse(ADI_STATERNK %in% as.character(1:10), "", ADI_STATERNK)]
neighborhood_atlas[, neighborhood_atlas_exclude := as.integer(neighborhood_atlas_exclude_reason != "")]
neighborhood_atlas[, ADI_STATERNK := suppressWarnings(as.numeric(ADI_STATERNK))]
neighborhood_atlas[, ADI_NATRANK  := suppressWarnings(as.numeric(ADI_NATRANK))]
neighborhood_atlas
##          year         FIPS ADI_NATRANK ADI_STATERNK
##         <int>       <char>       <num>        <num>
##      1:  2020 010010201001          72            5
##      2:  2020 010010201002          61            3
##      3:  2020 010010202001          83            6
##      4:  2020 010010202002          87            7
##      5:  2020 010010203001          73            5
##     ---                                            
## 484667:  2023 361031462041          NA           NA
## 484668:  2023 361031462042          NA           NA
## 484669:  2023 361031462043          NA           NA
## 484670:  2023 361032012001          NA           NA
## 484671:  2023 361119544011          NA           NA
##         neighborhood_atlas_exclude_reason neighborhood_atlas_exclude
##                                    <char>                      <int>
##      1:                                                            0
##      2:                                                            0
##      3:                                                            0
##      4:                                                            0
##      5:                                                            0
##     ---                                                             
## 484667:                               QDI                          1
## 484668:                               QDI                          1
## 484669:                               QDI                          1
## 484670:                               QDI                          1
## 484671:                               QDI                          1
```

Read in the ADI as reproduced in this repo.

``` r
adi <- data.table::fread("adi.csv.gz", colClasses = c("FIPS" = "character"))
```
Subset to just years 2020 and 2023 and merge on the Neighborhood Atlas data.

``` r
adi <- subset(adi, year %in% c(2020, 2023))
adi <- merge(x = adi, y = neighborhood_atlas, all = TRUE, by = c("year", "FIPS"))
```
As noted above, Neighborhood Atlas does exclude some block groups from ranking.  
Here we report how similar our exclusion flagging is.

``` r
adi[, .N, keyby = .(year, exclude_from_ranking, neighborhood_atlas_exclude)]
## Key: <year, exclude_from_ranking, neighborhood_atlas_exclude>
##     year exclude_from_ranking neighborhood_atlas_exclude      N
##    <int>                <int>                      <int>  <int>
## 1:  2020                    0                          0 235334
## 2:  2020                    0                          1    780
## 3:  2020                    1                          0    552
## 4:  2020                    1                          1   5669
## 5:  2023                   NA                          1     40
## 6:  2023                    0                          0 236102
## 7:  2023                    0                          1   2511
## 8:  2023                    1                          1   3683
```

There are 40 GEOID in the 2023 Neighborhood Atlas only.
- In the 2023 Neighborhood Atlas file, all 40 are marked QDI for both
  ADI_NATRANK and ADI_STATERNK.
- Those same GEOIDs existed in local Census-derived outputs for earlier
  years:
   - present in FIPS/2022__block_groups.csv
   - present in ADI/adi.csv.gz for 2020 to 2022
- They are absent from the 2023 Census geography inventory you are building from:
   - absent from FIPS/2023__block_groups.csv
   - their parent tracts are also absent from FIPS/2023__tracts.csv

The 40 GEOIDs are concentrated in 15 tracts:

- 14 tracts in Suffolk County, NY
- 1 tract in Ulster County, NY

Examples:

- 361031224061 to 361031224064 are in Census Tract 1224.06, Suffolk County
- 361031460011 to 361031460012 are in Census Tract 1460.01, Suffolk County
- 361119544011 is in Census Tract 9544.01, Ulster County

What that means:

- Neighborhood Atlas kept these GEOIDs in its 2023 file as QDI placeholders.
- Your Census-based build only includes geographies that are returned by the
  current Census files for that year.
- So for 2023, these 40 GEOIDs drop out of your build because they are no longer
  in the Census geography inventory you are using.

So the reason for the mismatch is a geography-vintage mismatch between
Neighborhood Atlas 2023 and the 2023 Census geography returned by your workflow


``` r
# remove these 40 rows
adi <- subset(adi, !(is.na(exclude_from_ranking)))
```


``` r
adi[,
  .(
    both_exclude = qwraps2::n_perc(exclude_from_ranking == 1 & neighborhood_atlas_exclude == 1, digits = 1),
    both_include = qwraps2::n_perc(exclude_from_ranking == 0 & neighborhood_atlas_exclude == 0, digits = 1),
    r_in_ngbr_ex = qwraps2::n_perc(exclude_from_ranking == 0 & neighborhood_atlas_exclude == 1, digits = 1),
    r_ex_nghr_in = qwraps2::n_perc(exclude_from_ranking == 1 & neighborhood_atlas_exclude == 0, digits = 1)
  ),
  keyby = .(year)
  ]
## Key: <year>
##     year both_exclude    both_include r_in_ngbr_ex r_ex_nghr_in
##    <int>       <char>          <char>       <char>       <char>
## 1:  2020 5,669 (2.3%) 235,334 (97.1%)   780 (0.3%)   552 (0.2%)
## 2:  2023 3,683 (1.5%) 236,102 (97.4%) 2,511 (1.0%)     0 (0.0%)
```

Let's look at the block groups that are excluded in Neighborhood Atlas but not
in the reproduction.


``` r
adi[
  exclude_from_ranking == 0 & neighborhood_atlas_exclude == 1,
  .N,
  keyby = .(year, neighborhood_atlas_exclude_reason)
]
## Key: <year, neighborhood_atlas_exclude_reason>
##     year neighborhood_atlas_exclude_reason     N
##    <int>                            <char> <int>
## 1:  2020                                GQ   751
## 2:  2020                               QDI    29
## 3:  2023                                GQ  2469
## 4:  2023                               QDI    42
```
The primary reaon for exclusion by Neighborhood Atlas is group quarters.


``` r
group_quarters <- data.table::fread("group_quarters.csv.gz")

group_quarters[
  adi[exclude_from_ranking == 0 & neighborhood_atlas_exclude == 1],
  on = c("year", "state", "county", "tract", "block_group")
][
  ,
  .N,
  keyby = .(year, group_quarters < 1/3)
  ]
## Key: <year, group_quarters>
##     year group_quarters     N
##    <int>         <lgcl> <int>
## 1:  2020           TRUE   780
## 2:  2023             NA  2511
```



``` r
with(adi, cor(state_rank, ADI_STATERNK, method = "pearson", use = "pairwise.complete.obs"))
## [1] 0.9686852
with(adi, cor(state_rank, ADI_STATERNK, method = "spearman", use = "pairwise.complete.obs"))
## [1] 0.9686906
adi[complete.cases(adi[, .(state_rank, ADI_STATERNK)])][, pcaPP::cor.fk(state_rank, ADI_STATERNK)]
## [1] 0.9139497

with(adi[year == 2020], cor(state_rank, ADI_STATERNK, method = "pearson", use = "pairwise.complete.obs"))
## [1] 0.9693838
with(adi[year == 2020], cor(state_rank, ADI_STATERNK, method = "spearman", use = "pairwise.complete.obs"))
## [1] 0.9693893
adi[year == 2020 & complete.cases(adi[, .(state_rank, ADI_STATERNK)])][, pcaPP::cor.fk(state_rank, ADI_STATERNK)]
## [1] 0.9151964

with(adi[year == 2023], cor(state_rank, ADI_STATERNK, method = "pearson", use = "pairwise.complete.obs"))
## [1] 0.967989
with(adi[year == 2023], cor(state_rank, ADI_STATERNK, method = "spearman", use = "pairwise.complete.obs"))
## [1] 0.9679944
adi[year == 2023 & complete.cases(adi[, .(state_rank, ADI_STATERNK)])][, pcaPP::cor.fk(state_rank, ADI_STATERNK)]
## [1] 0.9127118

with(adi, cor(national_rank, ADI_NATRANK, method = "pearson", use = "pairwise.complete.obs"))
## [1] 0.9864722
with(adi, cor(national_rank, ADI_NATRANK, method = "spearman", use = "pairwise.complete.obs"))
## [1] 0.986479
adi[complete.cases(adi[, .(national_rank, ADI_NATRANK)])][, pcaPP::cor.fk(national_rank, ADI_NATRANK)]
## [1] 0.921997

with(adi[year == 2020], cor(national_rank, ADI_NATRANK, method = "pearson", use = "pairwise.complete.obs"))
## [1] 0.9864514
with(adi[year == 2020], cor(national_rank, ADI_NATRANK, method = "spearman", use = "pairwise.complete.obs"))
## [1] 0.9864559
adi[year == 2020 & complete.cases(adi[, .(national_rank, ADI_NATRANK)])][, pcaPP::cor.fk(national_rank, ADI_NATRANK)]
## [1] 0.9219371

with(adi[year == 2023], cor(national_rank, ADI_NATRANK, method = "pearson", use = "pairwise.complete.obs"))
## [1] 0.9864933
with(adi[year == 2023], cor(national_rank, ADI_NATRANK, method = "spearman", use = "pairwise.complete.obs"))
## [1] 0.9865021
adi[year == 2023 & complete.cases(adi[, .(national_rank, ADI_NATRANK)])][, pcaPP::cor.fk(national_rank, ADI_NATRANK)]
## [1] 0.9220846
```


