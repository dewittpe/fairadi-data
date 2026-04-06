################################################################################
# file: component11.R
#
# Build component 11 of the CDI
#
# Component: 11
#   Median Gross Rent ($)
# ACS Data Table:
#   B25064
# Table Name:
#   Median gross rent (dollars)
# Numerator Calculation:
#   B25064_001
# Denominator Calculation:
#   _not applicable_
# Value Calculation with Description:
#   Median gross rent (B25064_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B25064")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = "B25064_001EA", M = "B25064_001MA")))

if (interactive()) {
  DT[, .N, keyby = .(B25064_001EA, B25064_001MA)]
  # Key: <B25064_001EA, B25064_001MA>
  #    B25064_001EA B25064_001MA       N
  #          <char>       <char>   <int>
  # 1:         <NA>         <NA> 1271825
  # 2:            -           **  366203
  # 3:         100-          ***     233
  # 4:       3,500+          ***   16655
}
DT[B25064_001EA == "-", B25064_001E := NA]
DT[!is.na(B25064_001MA), B25064_001M := NA]
stopifnot(
  DT[B25064_001EA == "100-", all(B25064_001E == 99)],
  DT[B25064_001EA == "3,500+", all(B25064_001E == 3501)]
)

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B25064_%03d", 1)
dV <- NULL
DT <- steps_1_and_2(DT, 11, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B25064_001EA == "-", 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component11")

# Step 6: Standardize the component
DT[, component11 := scale(component11), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
# only need block group level data to be saved
DT <- subset(DT, !is.na(block_group))
data.table::fwrite(DT, file = "component11.csv")

################################################################################
#                                 End of File                                  #
################################################################################
