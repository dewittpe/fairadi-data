################################################################################
# file: component12.R
#
# Build component 12 of the CDI
#
# Component: 12
#   Median home value ($)
# ACS Data Table:
#   B25077
# Table Name:
#   Median value (dollars)
# Numerator Calculation:
#   B25077_001
# Denominator Calculation:
#   _not applicable_
# Value Calculation with Description:
#   Median home value (B25077_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B25077")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = "B25077_001EA", M = "B25077_001MA")))

if (interactive()) {
  DT[, .N, keyby = .(B25077_001EA, B25077_001MA)]
  # Key: <B25077_001EA, B25077_001MA>
  #    B25077_001EA B25077_001MA       N
  #          <char>       <char>   <int>
  # 1:         <NA>         <NA> 1510665
  # 2:            -           **  132975
  # 3:      10,000-          ***    1321
  # 4:   2,000,000+          ***    9955
}
DT[B25077_001EA == "-", B25077_001E := NA]
DT[!is.na(B25077_001MA), B25077_001M := NA]
stopifnot(
  DT[B25077_001EA == "10,000-", all(B25077_001E == 9999)],
  DT[B25077_001EA == "1,000,000+", all(B25077_001E == 1000001)],
  DT[B25077_001EA == "2,000,000+", all(B25077_001E == 2000001)]
)

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B25077_%03d", 1)
dV <- NULL
DT <- steps_1_and_2(DT, 12, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B25077_001EA == "-", 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component12")

# Step 6: Standardize the component
DT[, component12 := scale(component12), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
# only need block group level data to be saved
DT <- subset(DT, !is.na(block_group))
data.table::fwrite(DT, file = "component12.csv")

################################################################################
#                                 End of File                                  #
################################################################################
