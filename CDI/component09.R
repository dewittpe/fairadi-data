################################################################################
# file: component09.R
#
# Build component 9 of the CDI
#
# Component: 9
#   Income disparity
# ACS Data Table:
#   B19001
# Table Name:
#   Household income in the paste 12 months
# Numerator Calculation:
#   sum of the items B19001_002 to B19001_004
# Denominator Calculation:
#   sum of the items B19001_014 to B19001_017
# Value Calculation with Description:
#   Log {100 * [Less than $20,000 (B19001_002 + … + B19001_004)/($100,000 to $124,999 (B19001_014) + …+ $200,000 or more (B19001_017))] }
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B19001")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
#
# The following special considerations are made for the income disparity
# component:
#
# • The income disparity component value conceptually represents the ratio of
#   low-income households (income ≤ $20,000) to high-income households
#   (income ≥ $100,000) in the specific block group.
# • A numerator of 0 indicates that there are no low-income households in the
#   block group.
# • A denominator of 0 indicates that there are no high-income households in the
#   block group.
# • To calculate the values of the income disparity component, follow the steps
#   below:
#   o Calculate the ratio for all block groups that have non-zero numerator
#     and denominator.
#   o Identify the highest disparity ratio and lowest disparity ratio calculated
#     in the previous step.
#   o For cases where the numerator of the income disparity component is 0 (i.e.
#     the ACS table indicates no households with low income), set the component
#     value to equal the minimum disparity ratio from the previous step.
#   o For cases where the denominator of the income disparity component is 0
#     (i.e. the ACS table indicates no households with high income), set the
#     component value to equal the maximum disparity ratio from the previous
#     step.
# • This approach captures the block groups with the greatest disparities by
#   setting those values to the minimum/maximum values, rather than replacing
#   those with the values for higher geographic levels.
DT[, numerator   := rowSums(.SD), .SDcols = sprintf("B19001_%03dE", 2:4)]
DT[, denominator := rowSums(.SD), .SDcols = sprintf("B19001_%03dE", 14:17)]
DT[, numeratorMOEsq   := rowSums(.SD^2), .SDcols = sprintf("B19001_%03dM", 2:4)]
DT[, denominatorMOEsq := rowSums(.SD^2), .SDcols = sprintf("B19001_%03dM", 14:17)]
DT[, component09E := numerator/denominator]
minmax_disparity_ratio <-
  DT[!is.na(block_group)][!is.na(component09E)][is.finite(component09E)][numerator > 0][denominator > 0][,
    .(min_disparity_ratio = min(component09E),
      max_disparity_ratio = max(component09E)),
    by = .(year)
  ]
DT <- merge(DT, minmax_disparity_ratio, all.x = TRUE, by = "year")
DT[numerator == 0,   component09E := min_disparity_ratio]
DT[denominator == 0, component09E := max_disparity_ratio]

# Step 2: Calculate the Margin of Error
DT[, component09M := 1/denominator * sqrt(numeratorMOEsq + (numerator/denominator)^2 * denominatorMOEsq)]
DT[numerator == 0 | denominator == 0, component09M := NA]

# Step 3: Flag values that need replacement
#
# Keep the component-09 min/max substitution for numerator == 0 or denominator
# == 0. For the remaining rows, use the shared low-population/low-housing rule
# from total_population_and_housing_units.csv.gz.
DT <- join_tphu(DT)

# Step 4: Apply Shrinkage
# Step 5: Replace invalid values from step 3
#
# Component 09 is special. For the numerator == 0 or denominator == 0 cases, the
# CMS specification uses min/max substitution on the block-group ratio instead
# of higher-geography replacement. For the remaining valid rows, apply shrinkage
# only when both the local MOE and the inter-geography variance are defined and
# positive; otherwise keep the local estimate (weight = 1).
DTa <- DT[numerator > 0 & denominator > 0 & flag_for_replacement == 0L]

bgshrunk <-
  merge(
    DTa[!is.na(block_group),                 .SD, .SDcols = c("year", "state", "county", "tract", "block_group", "component09E", "component09M")],
    DTa[ is.na(block_group) & !is.na(tract), .SD, .SDcols = c("year", "state", "county", "tract",                "component09E", "component09M")],
    all.x = TRUE,
    by = c("year", "state", "county", "tract"),
    suffixes = c("_x", "_z")
  )
tractshrunk <-
  merge(
    DTa[ is.na(block_group) & !is.na(tract),                  .SD, .SDcols = c("year", "state", "county", "tract", "component09E", "component09M")],
    DTa[ is.na(block_group) &  is.na(tract) & !is.na(county), .SD, .SDcols = c("year", "state", "county",          "component09E", "component09M")],
    all.x = TRUE,
    by = c("year", "state", "county"),
    suffixes = c("_x", "_z")
  )
countyshrunk <-
  merge(
    DTa[ is.na(block_group) &  is.na(tract) & !is.na(county),                 .SD, .SDcols = c("year", "state", "county", "component09E", "component09M")],
    DTa[ is.na(block_group) &  is.na(tract) &  is.na(county) & !is.na(state), .SD, .SDcols = c("year", "state",           "component09E", "component09M")],
    all.x = TRUE,
    by = c("year", "state"),
    suffixes = c("_x", "_z")
  )

bgshrunk[,     tsq := 1/(.N - 1) * sum((component09E_x - component09E_z)^2), keyby = .(year, state, county, tract)]
tractshrunk[,  tsq := 1/(.N - 1) * sum((component09E_x - component09E_z)^2), keyby = .(year, state, county)]
countyshrunk[, tsq := 1/(.N - 1) * sum((component09E_x - component09E_z)^2), keyby = .(year, state)]

bgshrunk[,     Ssq := (component09M_x / 1.645)^2]
tractshrunk[,  Ssq := (component09M_x / 1.645)^2]
countyshrunk[, Ssq := (component09M_x / 1.645)^2]

bgshrunk[,     component09E_shrunk_block_group := component09E_x]
tractshrunk[,  component09E_shrunk_tract := component09E_x]
countyshrunk[, component09E_shrunk_county := component09E_x]

bgshrunk[
  !is.na(component09E_z) & !is.na(Ssq) & Ssq > 0 & !is.na(tsq) & tsq > 0,
  `:=`(
    w = (1/Ssq) / (1/Ssq + 1/tsq),
    component09E_shrunk_block_group = ((1/Ssq) / (1/Ssq + 1/tsq)) * component09E_x +
      (1 - ((1/Ssq) / (1/Ssq + 1/tsq))) * component09E_z
  )
]
tractshrunk[
  !is.na(component09E_z) & !is.na(Ssq) & Ssq > 0 & !is.na(tsq) & tsq > 0,
  `:=`(
    w = (1/Ssq) / (1/Ssq + 1/tsq),
    component09E_shrunk_tract = ((1/Ssq) / (1/Ssq + 1/tsq)) * component09E_x +
      (1 - ((1/Ssq) / (1/Ssq + 1/tsq))) * component09E_z
  )
]
countyshrunk[
  !is.na(component09E_z) & !is.na(Ssq) & Ssq > 0 & !is.na(tsq) & tsq > 0,
  `:=`(
    w = (1/Ssq) / (1/Ssq + 1/tsq),
    component09E_shrunk_county = ((1/Ssq) / (1/Ssq + 1/tsq)) * component09E_x +
      (1 - ((1/Ssq) / (1/Ssq + 1/tsq))) * component09E_z
  )
]

DTa <-
  merge(
    merge(
      bgshrunk[,    .SD, .SDcols = c("year", "state", "county", "tract", "block_group", "component09E_shrunk_block_group")],
      tractshrunk[, .SD, .SDcols = c("year", "state", "county", "tract",                "component09E_shrunk_tract")],
      all.x = TRUE,
      by = c("year", "state", "county", "tract")
    ),
    countyshrunk[, .SD, .SDcols = c("year", "state", "county", "component09E_shrunk_county")],
    all.x = TRUE,
    by = c("year", "state", "county")
  )
DTa[
  ,
  component09 := data.table::fcoalesce(
    component09E_shrunk_block_group,
    component09E_shrunk_tract,
    component09E_shrunk_county
  )
]
DTa <- DTa[, .SD, .SDcols = c("year", "state", "county", "tract", "block_group", "component09")]

DTr <-
  merge(
    DT[numerator > 0 & denominator > 0 & flag_for_replacement == 1L, .(year, state, county, tract, block_group)],
    tractshrunk[, .SD, .SDcols = c("year", "state", "county", "tract", "component09E_shrunk_tract")],
    all.x = TRUE,
    by = c("year", "state", "county", "tract")
  )
DTr <-
  merge(
    DTr,
    countyshrunk[, .SD, .SDcols = c("year", "state", "county", "component09E_shrunk_county")],
    all.x = TRUE,
    by = c("year", "state", "county")
  )
DTr[
  ,
  component09 := data.table::fcoalesce(
    component09E_shrunk_tract,
    component09E_shrunk_county
  )
]
DTr <- DTr[, .SD, .SDcols = c("year", "state", "county", "tract", "block_group", "component09")]

DT <- rbind(
  DT[numerator == 0 | denominator == 0, .(year, state, county, tract, block_group, component09 = component09E)],
  DTr,
  DTa
)

DT[, component09 := log(100 * component09)]

# Step 6: Standardize the component
DT[, component09 := scale(component09), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
data.table::fwrite(DT, file = "component09.csv")

################################################################################
#                                 End of File                                  #
################################################################################
