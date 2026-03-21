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
## 7:  2023                    0                          1     42
## 8:  2023                    1                          1   6152
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
## 2:  2023 6,152 (2.5%) 236,102 (97.4%)    42 (0.0%)     0 (0.0%)
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
## 3:  2023                               QDI    42
```
The primary reaon for exclusion by Neighborhood Atlas is group quarters.


``` r
group_quarters <- data.table::fread("group_quarters.csv.gz")

bg_gh <-
  group_quarters[
    adi[exclude_from_ranking == 0 & neighborhood_atlas_exclude == 1],
    on = c("year", "state", "county", "tract", "block_group")
  ]
```

Sanity check, for those with a value for group quarters all of them are, in the
reproduction, under 1/3.

``` r
bg_gh[, .N, keyby = .(year, group_quarters < 1/3) ]
## Key: <year, group_quarters>
##     year group_quarters     N
##    <int>         <lgcl> <int>
## 1:  2020           TRUE   780
## 2:  2023             NA    42
```

If the exclusion by group quarters is based on the Decennial census values, then
a block group should be exlcuded in both 2020 and 2023.  However, only a few
block groups are excluded due to group quarters in both Neighborhood Atlas
data sets.

``` r
bg_gh[, .SD[duplicated(.SD, by = c("state", "county", "tract", "block_group"))]]
##     year state county  tract block_group group_quarters         FIPS   adi_raw
##    <int> <int>  <int>  <int>       <int>          <num>       <char>     <num>
## 1:  2023     8     57 955600           1             NA 080579556001 -30102.32
## 2:  2023     8     57 955600           2             NA 080579556002 -17424.09
## 3:  2023    48    443 950100           1             NA 484439501001 -16749.86
##    exclude_from_ranking exclude_reason national_rank state_rank ADI_NATRANK
##                   <int>         <char>         <int>      <int>       <num>
## 1:                    0                           47          9          NA
## 2:                    0                           81         10          NA
## 3:                    0                           83          8          NA
##    ADI_STATERNK neighborhood_atlas_exclude_reason neighborhood_atlas_exclude
##           <num>                            <char>                      <int>
## 1:           NA                               QDI                          1
## 2:           NA                               QDI                          1
## 3:           NA                               QDI                          1
```
This is not the case.

``` r
data.table::dcast(
  neighborhood_atlas[
    neighborhood_atlas[, .(N = length(unique(neighborhood_atlas_exclude_reason))), by = .(FIPS)][N > 1],
    on = "FIPS"
  ]
  ,
  FIPS ~ year,
  value.var = "neighborhood_atlas_exclude_reason"
)[, .N, keyby = .(`2020`, `2023`)] |>
print(nrow = Inf)
## Key: <2020, 2023>
##       2020   2023     N
##     <char> <char> <int>
##  1:            GQ   546
##  2:            PH   126
##  3:           QDI   225
##  4:     GQ          744
##  5:     GQ  GQ-PH    35
##  6:     GQ     PH     2
##  7:     GQ    QDI    25
##  8:  GQ-PH           10
##  9:  GQ-PH     GQ    54
## 10:  GQ-PH     PH    58
## 11:  GQ-PH    QDI     3
## 12:     PH          168
## 13:     PH     GQ     5
## 14:     PH  GQ-PH   127
## 15:     PH    QDI    10
## 16:    QDI          155
## 17:    QDI     GQ     9
## 18:    QDI     PH    11
```
We speculate that the reason the exclusion based on group quarters changes from
2020 to 2023 within the Neighborhood Atlas data is that they have access to the
non-public ACS5 block group level data.  That data can be acquired with a signed
data-use agreement.  For the reproduction, and using only publicly available
data, we are restricted to using the Decennial census values for both 2020 and
2023.



``` r
adi[bg_gh, on = "FIPS"]
##        year         FIPS state county  tract block_group    adi_raw
##       <int>       <char> <int>  <int>  <int>       <int>      <num>
##    1:  2020 010030105001     1      3  10500           1 -17948.976
##    2:  2023 010030105001     1      3  10500           1 -19330.433
##    3:  2020 010150012012     1     15   1201           2 -10523.215
##    4:  2023 010150012012     1     15   1201           2 -16310.839
##    5:  2020 010399625001     1     39 962500           1 -10447.992
##   ---                                                              
## 1633:  2023 483859501004    48    385 950100           4 -19698.002
## 1634:  2020 484439501001    48    443 950100           1 -12023.690
## 1635:  2023 484439501001    48    443 950100           1 -16749.861
## 1636:  2020 720851902012    72     85 190201           2  -9004.742
## 1637:  2023 720851902012    72     85 190201           2  -7061.400
##       exclude_from_ranking exclude_reason national_rank state_rank ADI_NATRANK
##                      <int>         <char>         <int>      <int>       <num>
##    1:                    0                           63          4          NA
##    2:                    0                           75          5          80
##    3:                    0                           91          8          NA
##    4:                    0                           84          7          82
##    5:                    0                           91          9          NA
##   ---                                                                         
## 1633:                    0                           74          7          NA
## 1634:                    0                           86          8          NA
## 1635:                    0                           83          8          NA
## 1636:                    0                           95          7          95
## 1637:                    0                          100         10          NA
##       ADI_STATERNK neighborhood_atlas_exclude_reason neighborhood_atlas_exclude
##              <num>                            <char>                      <int>
##    1:           NA                                GQ                          1
##    2:            6                                                            0
##    3:           NA                                GQ                          1
##    4:            6                                                            0
##    5:           NA                                GQ                          1
##   ---                                                                          
## 1633:           NA                               QDI                          1
## 1634:           NA                               QDI                          1
## 1635:           NA                               QDI                          1
## 1636:            7                                                            0
## 1637:           NA                               QDI                          1
##       i.year i.state i.county i.tract i.block_group group_quarters i.adi_raw
##        <int>   <int>    <int>   <int>         <int>          <num>     <num>
##    1:   2020       1        3   10500             1      0.3221818 -17948.98
##    2:   2020       1        3   10500             1      0.3221818 -17948.98
##    3:   2020       1       15    1201             2      0.2515231 -10523.21
##    4:   2020       1       15    1201             2      0.2515231 -10523.21
##    5:   2020       1       39  962500             1      0.1946779 -10447.99
##   ---                                                                       
## 1633:   2023      48      385  950100             4             NA -19698.00
## 1634:   2023      48      443  950100             1             NA -16749.86
## 1635:   2023      48      443  950100             1             NA -16749.86
## 1636:   2023      72       85  190201             2             NA  -7061.40
## 1637:   2023      72       85  190201             2             NA  -7061.40
##       i.exclude_from_ranking i.exclude_reason i.national_rank i.state_rank
##                        <int>           <char>           <int>        <int>
##    1:                      0                               63            4
##    2:                      0                               63            4
##    3:                      0                               91            8
##    4:                      0                               91            8
##    5:                      0                               91            9
##   ---                                                                     
## 1633:                      0                               74            7
## 1634:                      0                               83            8
## 1635:                      0                               83            8
## 1636:                      0                              100           10
## 1637:                      0                              100           10
##       i.ADI_NATRANK i.ADI_STATERNK i.neighborhood_atlas_exclude_reason
##               <num>          <num>                              <char>
##    1:            NA             NA                                  GQ
##    2:            NA             NA                                  GQ
##    3:            NA             NA                                  GQ
##    4:            NA             NA                                  GQ
##    5:            NA             NA                                  GQ
##   ---                                                                 
## 1633:            NA             NA                                 QDI
## 1634:            NA             NA                                 QDI
## 1635:            NA             NA                                 QDI
## 1636:            NA             NA                                 QDI
## 1637:            NA             NA                                 QDI
##       i.neighborhood_atlas_exclude
##                              <int>
##    1:                            1
##    2:                            1
##    3:                            1
##    4:                            1
##    5:                            1
##   ---                             
## 1633:                            1
## 1634:                            1
## 1635:                            1
## 1636:                            1
## 1637:                            1
```
Not that for the block groups that our reproduction excludes but Neighborhood
Atlas does not, it is all due to grouped quarters.

``` r
adi[exclude_from_ranking == 1 & neighborhood_atlas_exclude == 0, .N, by =
  .(year, exclude_reason)]
##     year exclude_reason     N
##    <int>         <char> <int>
## 1:  2020             GQ   552
```

### Correlations

<table>
 <thead>
<tr>
<th style="empty-cells: hide;border-bottom:hidden;" colspan="1"></th>
<th style="empty-cells: hide;border-bottom:hidden;" colspan="1"></th>
<th style="border-bottom:hidden;padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="3"><div style="border-bottom: 1px solid #ddd; padding-bottom: 5px; ">State Level</div></th>
<th style="border-bottom:hidden;padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="3"><div style="border-bottom: 1px solid #ddd; padding-bottom: 5px; ">National Level</div></th>
</tr>
  <tr>
   <th style="text-align:left;"> Year </th>
   <th style="text-align:right;"> Block Groups </th>
   <th style="text-align:right;"> Pearson </th>
   <th style="text-align:right;"> Spearman </th>
   <th style="text-align:right;"> Kendall </th>
   <th style="text-align:right;"> Pearson </th>
   <th style="text-align:right;"> Spearman </th>
   <th style="text-align:right;"> Kendall </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2020 &amp; 2023 </td>
   <td style="text-align:right;"> 471436 </td>
   <td style="text-align:right;"> 0.9687 </td>
   <td style="text-align:right;"> 0.9687 </td>
   <td style="text-align:right;"> 0.9140 </td>
   <td style="text-align:right;"> 0.9865 </td>
   <td style="text-align:right;"> 0.9865 </td>
   <td style="text-align:right;"> 0.9220 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2020 </td>
   <td style="text-align:right;"> 235334 </td>
   <td style="text-align:right;"> 0.9694 </td>
   <td style="text-align:right;"> 0.9694 </td>
   <td style="text-align:right;"> 0.9152 </td>
   <td style="text-align:right;"> 0.9865 </td>
   <td style="text-align:right;"> 0.9865 </td>
   <td style="text-align:right;"> 0.9219 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2023 </td>
   <td style="text-align:right;"> 236102 </td>
   <td style="text-align:right;"> 0.9680 </td>
   <td style="text-align:right;"> 0.9680 </td>
   <td style="text-align:right;"> 0.9127 </td>
   <td style="text-align:right;"> 0.9865 </td>
   <td style="text-align:right;"> 0.9865 </td>
   <td style="text-align:right;"> 0.9221 </td>
  </tr>
</tbody>
</table>



