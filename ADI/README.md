# FAIR Area Deprivation Index



The Area Deprivation Index (ADI)

* defined in Kind et.al. (2014) https://doi.org/10.7326/m13-2946

* A well referenced and commonly used source for the ADI is from [Neighborhood
  Atlas](https://www.neighborhoodatlas.medicine.wisc.edu/)

The work in this directory is an attempt to reproduce the ADI as published by
Neighborhood Atlas. The reproduction is called `fairadi`, a **FAIR**-compliant
(Findability, Accessibility, Interoperability, and Reuse) **ADI**.

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
| Group Quarters   | P18             |            |
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
str(neighborhood_atlas)
## Classes 'data.table' and 'data.frame':	484671 obs. of  6 variables:
##  $ year                             : int  2020 2020 2020 2020 2020 2020 2020 2020 2020 2020 ...
##  $ FIPS                             : chr  "010010201001" "010010201002" "010010202001" "010010202002" ...
##  $ ADI_NATRANK                      : num  72 61 83 87 73 85 62 50 72 71 ...
##  $ ADI_STATERNK                     : num  5 3 6 7 5 7 3 2 5 5 ...
##  $ neighborhood_atlas_exclude_reason: chr  "" "" "" "" ...
##  $ neighborhood_atlas_exclude       : int  0 0 0 0 0 0 0 0 0 0 ...
##  - attr(*, ".internal.selfref")=<externalptr>
```

### `fairadi` Data
Read in the `fairadi` data.

``` r
fairadi <- data.table::fread("adi.csv.gz", colClasses = c("FIPS" = "character"))
str(fairadi)
## Classes 'data.table' and 'data.frame':	1211599 obs. of  11 variables:
##  $ year                : int  2020 2021 2022 2023 2024 2020 2021 2022 2023 2024 ...
##  $ state               : int  1 1 1 1 1 1 1 1 1 1 ...
##  $ county              : int  1 1 1 1 1 1 1 1 1 1 ...
##  $ tract               : int  20100 20100 20100 20100 20100 20100 20100 20100 20100 20100 ...
##  $ block_group         : int  1 1 1 1 1 2 2 2 2 2 ...
##  $ FIPS                : chr  "010010201001" "010010201001" "010010201001" "010010201001" ...
##  $ adi_raw             : num  -17048 -16411 -18557 -20126 -21200 ...
##  $ exclude_from_ranking: int  0 0 0 0 0 0 0 0 0 0 ...
##  $ exclude_reason      : chr  "" "" "" "" ...
##  $ national_rank       : int  67 73 73 73 73 67 73 74 74 73 ...
##  $ state_rank          : int  4 5 5 5 5 4 5 5 5 5 ...
##  - attr(*, ".internal.selfref")=<externalptr>
```

In this README we will subset to the two years of Neighborhood Atlas data.

``` r
fairadi <- subset(fairadi, year %in% c(2020, 2023))
adi <- merge(x = fairadi, y = neighborhood_atlas, all = TRUE, by = c("year", "FIPS"))
```

### Exclusion Criteria
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

There are 40 GEOIDs in the 2023 Neighborhood Atlas only.
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
exin <-
  adi[,
    .(
      both_exclude = qwraps2::n_perc(exclude_from_ranking == 1 & neighborhood_atlas_exclude == 1, digits = 1),
      both_include = qwraps2::n_perc(exclude_from_ranking == 0 & neighborhood_atlas_exclude == 0, digits = 1),
      in_fairadi_ngbr_ex = qwraps2::n_perc(exclude_from_ranking == 0 & neighborhood_atlas_exclude == 1, digits = 1),
      ex_fairadi_nghr_in = qwraps2::n_perc(exclude_from_ranking == 1 & neighborhood_atlas_exclude == 0, digits = 1)
    ),
    keyby = .(year)
  ]
```

<table>
 <thead>
  <tr>
   <th style="text-align:right;"> Year </th>
   <th style="text-align:left;"> Excluded in Both </th>
   <th style="text-align:left;"> Included in Both </th>
   <th style="text-align:left;"> In fairadi; Excluded from Neighborhood Atlas </th>
   <th style="text-align:left;"> Excluded from fairadi; Included in Neighborhood Atlas </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 2020 </td>
   <td style="text-align:left;"> 5,669 (2.3%) </td>
   <td style="text-align:left;"> 235,334 (97.1%) </td>
   <td style="text-align:left;"> 780 (0.3%) </td>
   <td style="text-align:left;"> 552 (0.2%) </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2023 </td>
   <td style="text-align:left;"> 6,152 (2.5%) </td>
   <td style="text-align:left;"> 236,102 (97.4%) </td>
   <td style="text-align:left;"> 42 (0.0%) </td>
   <td style="text-align:left;"> 0 (0.0%) </td>
  </tr>
</tbody>
</table>



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
The primary reason for exclusion by Neighborhood Atlas is group quarters.


``` r
group_quarters <- data.table::fread("group_quarters.csv.gz")
bg_gh <-
  group_quarters[
    adi[exclude_from_ranking == 0 & neighborhood_atlas_exclude == 1],
    on = c("year", "state", "county", "tract", "block_group")
  ]
```



If the exclusion by group quarters is based on the Decennial census values, then
a block group should be excluded in both 2020 and 2023.  However, only a few
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

There are many ways the reason for exclusion will change from 2020 to 2023
within the Neighborhood Atlas data.

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

Note that for the block groups that our reproduction excludes but Neighborhood
Atlas does not, it is all due to grouped quarters.

``` r
adi[
  exclude_from_ranking == 1 & neighborhood_atlas_exclude == 0,
  .N,
  by = .(year, exclude_reason)
]
##     year exclude_reason     N
##    <int>         <char> <int>
## 1:  2020             GQ   552
```

### Rank Correlations

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



### Differences in Ranks





#### State Level
<div class="figure" style="text-align: center">
<img src="figure/state-level-plots-1.png" alt="plot of chunk state-level-plots"  />
<p class="caption">plot of chunk state-level-plots</p>
</div><div class="figure" style="text-align: center">
<img src="figure/state-level-plots-2.png" alt="plot of chunk state-level-plots"  />
<p class="caption">plot of chunk state-level-plots</p>
</div><div class="figure" style="text-align: center">
<img src="figure/state-level-plots-3.png" alt="plot of chunk state-level-plots"  />
<p class="caption">plot of chunk state-level-plots</p>
</div>
#### National Level
<div class="figure" style="text-align: center">
<img src="figure/national-level-plots-1.png" alt="plot of chunk national-level-plots"  />
<p class="caption">plot of chunk national-level-plots</p>
</div><div class="figure" style="text-align: center">
<img src="figure/national-level-plots-2.png" alt="plot of chunk national-level-plots"  />
<p class="caption">plot of chunk national-level-plots</p>
</div><div class="figure" style="text-align: center">
<img src="figure/national-level-plots-3.png" alt="plot of chunk national-level-plots"  />
<p class="caption">plot of chunk national-level-plots</p>
</div>



## Session Info


``` r
sessionInfo()
## R version 4.5.3 (2026-03-11)
## Platform: x86_64-apple-darwin20
## Running under: macOS Sonoma 14.8.3
## 
## Matrix products: default
## BLAS:   /Library/Frameworks/R.framework/Versions/4.5-x86_64/Resources/lib/libRblas.0.dylib 
## LAPACK: /Library/Frameworks/R.framework/Versions/4.5-x86_64/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1
## 
## locale:
## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
## 
## time zone: America/Denver
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## loaded via a namespace (and not attached):
##  [1] gtable_0.3.6        dplyr_1.2.0         compiler_4.5.3     
##  [4] tidyselect_1.2.1    Rcpp_1.1.1          xml2_1.5.2         
##  [7] stringr_1.6.0       gridGraphics_0.5-1  gridExtra_2.3      
## [10] ggplotify_0.1.3     systemfonts_1.3.2   scales_1.4.0       
## [13] textshaping_1.0.5   fastmap_1.2.0       ggplot2_4.0.2      
## [16] R6_2.6.1            labeling_0.4.3      generics_0.1.4     
## [19] pcaPP_2.0-5         knitr_1.51          yulab.utils_0.2.4  
## [22] tibble_3.3.1        kableExtra_1.4.0    svglite_2.2.2      
## [25] pillar_1.11.1       RColorBrewer_1.1-3  qwraps2_0.6.2      
## [28] R.utils_2.13.0      rlang_1.1.7         stringi_1.8.7      
## [31] xfun_0.57           fs_1.6.7            S7_0.2.1           
## [34] otel_0.2.0          viridisLite_0.4.3   cli_3.6.5          
## [37] withr_3.0.2         magrittr_2.0.4      digest_0.6.39      
## [40] grid_4.5.3          rstudioapi_0.18.0   mvtnorm_1.3-5      
## [43] rappdirs_0.3.4      lifecycle_1.0.5     R.methodsS3_1.8.2  
## [46] R.oo_1.27.1         vctrs_0.7.2         evaluate_1.0.5     
## [49] glue_1.8.0          data.table_1.18.2.1 farver_2.1.2       
## [52] rmarkdown_2.30      pkgconfig_2.0.3     tools_4.5.3        
## [55] htmltools_0.5.9
```
