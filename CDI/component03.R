################################################################################
# file: component03.R
#
# Build component 3 of the CDI
#
# Component: 3
#   Employed in white collar jobs, %
# ACS Data Table:
#   C24010
# Table Name:
#   Sex by occupation for the civilian employed population 16 years and over
# Numerator Calculation:
#   C24010_003 + C24010_027 + C24010_039 + C24010_063
# Denominator Calculation:
#   C24010_001
# Value Calculation with Description:
#   [Male: Management, business, science, and arts occupations (C24010_003) + Male: Sales and office occupations (C24010_027) + Female: Management, business, science, and arts occupations (C24010_039) + Female: Sales and office occupations (C24010_63)]/Total (C24010_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "C24010")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
nV <- sprintf("C24010_%03d", c(3, 27, 39, 63))
dV <- sprintf("C24010_%03d", 1)
DT <- steps_1_and_2(DT, 3, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    C24010_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component03")

# Step 6: Standardize the component
DT[, component03 := scale(component03), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
# only need block group level data to be saved
DT <- subset(DT, !is.na(block_group))
data.table::fwrite(DT, file = "component03.csv")

################################################################################
#                                 End of File                                  #
################################################################################
