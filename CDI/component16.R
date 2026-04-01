################################################################################
# file: component16.R
#
# Build component 16 of the CDI
#
# Component: 16
#   Population living below 150% of the federal poverty line, %
# ACS Data Table:
#   C17002
# Table Name:
#   Ratio of income to poverty level in the past 12 months
# Numerator Calculation:
#   sum of the items C17002_002 to C17002_005
# Denominator Calculation:
#   C17002_001
# Value Calculation with Description:
#   [Under .50 (C17002_002) + .50 to .99 (C17002_003) + 1.00 to 1.24 (C17002_004) + 1.25 to 1.49 (C17002_005)] /Total (C17002_001) 
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "C17002")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("C17002_%03d", 2:5)
dV <- sprintf("C17002_%03d", 1)
DT <- steps_1_and_2(DT, 16, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    C17002_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component16")

# Step 6: Standardize the component
DT[, component16 := scale(component16), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
data.table::fwrite(DT, file = "component16.csv")

################################################################################
#                                 End of File                                  #
################################################################################
