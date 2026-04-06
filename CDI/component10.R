################################################################################
# file: component10.R
#
# Build component 10 of the CDI
#
# Component: 10
#   Median Household income
# ACS Data Table:
#   B19013
# Table Name:
#   Median household income in the past 12 months
# Numerator Calculation:
#   B19013_001
# Denominator Calculation:
#   _not applicable_
# Value Calculation with Description:
#   Median household income in the past 12 months (B19013_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B19013")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = "B19013_001EA", M = "B19013_001MA")))

if (interactive()) {
  DT[, .N, keyby = .(B19013_001EA, B19013_001MA)]
  # Key: <B19013_001EA, B19013_001MA>
  #    B19013_001EA B19013_001MA       N
  #          <char>       <char>   <int>
  # 1:         <NA>         <NA> 1546754
  # 2:            -           **   94169
  # 3:       2,500-          ***     585
  # 4:     250,000+          ***   13408
}
DT[B19013_001EA == "-", B19013_001E := NA]
DT[!is.na(B19013_001MA), B19013_001M := NA]
stopifnot(
  DT[B19013_001EA == "2,500-", all(B19013_001E == 2499)],
  DT[B19013_001EA == "250,000+", all(B19013_001E == 250001)]
)

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B19013_%03d", 1)
dV <- NULL
DT <- steps_1_and_2(DT, 10, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B19013_001EA == "-", 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component10")

# Step 6: Standardize the component
DT[, component10 := scale(component10), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
# only need block group level data to be saved
DT <- subset(DT, !is.na(block_group))
data.table::fwrite(DT, file = "component10.csv")

################################################################################
#                                 End of File                                  #
################################################################################
