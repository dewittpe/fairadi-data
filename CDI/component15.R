################################################################################
# file: component15.R
#
# Build component 15 of the CDI
#
# Component: 15
#   Owner occupied housing, %
# ACS Data Table:
#   B25003
# Table Name:
#   Tenure
# Numerator Calculation:
#   B25003_002
# Denominator Calculation:
#   B25003_001
# Value Calculation with Description:
#   Owner occupied (B25003_002)/Total (B25003_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B25003")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B25003_%03d", 2)
dV <- sprintf("B25003_%03d", 1)
steps_1_and_2(DT, 15, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B25003_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component15")

# Step 6: Standardize the component
DT[, component15 := scale(component15), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
data.table::fwrite(DT, file = "component15.csv")

################################################################################
#                                 End of File                                  #
################################################################################
