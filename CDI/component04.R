################################################################################
# file: component04.R
#
# Build component 4 of the CDI
#
# Component: 4
#   Families living below 100% of the federal poverty line, %
# ACS Data Table:
#   B17010
# Table Name:
#   Povery status in the past 12 months of families by familiy type by presence
#   of related children
# Numerator Calculation:
#   B17010_002
# Denominator Calculation:
#   B17010_001
# Value Calculation with Description:
#   Income in the past 12 months below poverty level (B17010_002) / Total (B17010_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B17010")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B17010_%03d", 2)
dV <- sprintf("B17010_%03d", 1)
DT <- steps_1_and_2(DT, 4, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B17010_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component04")

# Step 6: Standardize the component
DT[, component04 := scale(component04), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
# only need block group level data to be saved
DT <- subset(DT, !is.na(block_group))
data.table::fwrite(DT, file = "component04.csv")

################################################################################
#                                 End of File                                  #
################################################################################
