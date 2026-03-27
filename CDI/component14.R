################################################################################
# file: component14.R
#
# Build component 14 of the CDI
#
# Component: 14
#   One parent households, %
# ACS Data Table:
#   B11003
# Table Name:
#   Family type by prsence and age of own chlidren under 18 years
# Numerator Calculation:
#   B15003_010 + B15003_016
# Denominator Calculation:
#   B15003_001
# Value Calculation with Description:
#   [Male w children and no spouse present (B11003_010) + Female w children and no spouse present (B11003_016)]/Total (B11003_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B15003")
cfa <- check_for_annotations(DT)

# B15003_001MA exists
stopifnot(identical(cfa, list(E = character(0), M = "B15003_001MA")))

# all the annotations are the same:
stopifnot(
  DT[!is.na(B15003_001MA), all(B15003_001MA == "*****")]
)
# see notes in ../utilities/check_for_annotations.R; error can be treated as zero in these cases
DT[!is.na(B15003_001MA), B15003_001M := 0L]

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B15003_%03d", 2:16)
dV <- sprintf("B15003_%03d", 1)
steps_1_and_2(DT, 14, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B15003_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component14")

# Step 6: Standardize the component
DT[, component14 := scale(component14), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
data.table::fwrite(DT, file = "component14.csv")

################################################################################
#                                 End of File                                  #
################################################################################
