################################################################################
# file: component17.R
#
# Build component 17 of the CDI
#
# Component: 17
#   Unemployment, %
# ACS Data Table:
#   B23025
# Table Name:
#   Employment status for the population 16 years and over
# Numerator Calculation:
#   B23025_005
# Denominator Calculation:
#   B23025_002
# Value Calculation with Description:
#   Unemployed (B23025_005)/Labor Force (B23025_002)
#
# NOTE: ACS-5-Year estimtes for B23025 first availablity is 2011
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B23025")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B23025_%03d", 5)
dV <- sprintf("B23025_%03d", 2)
DT <- steps_1_and_2(DT, 17, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B23025_002E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component17")

# Step 6: Standardize the component
DT[, component17 := scale(component17), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
# only need block group level data to be saved
DT <- subset(DT, !is.na(block_group))
data.table::fwrite(DT, file = "component17.csv")

################################################################################
#                                 End of File                                  #
################################################################################
