################################################################################
# file: component08.R
#
# Build component 8 of the CDI
#
# Component: 8
#   Households with incomplete plumbing, %
# ACS Data Table:
#   B25047
# Table Name:
#   Plumbing facilities for all housing units
# Numerator Calculation:
#   B25047_003
# Denominator Calculation:
#   B25047_001
# Value Calculation with Description:
#   Lacking complete plumbing facilities (B25047_003)/Total (B25047_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B25047")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B25047_%03d", 3)
dV <- sprintf("B25047_%03d", 1)
DT <- steps_1_and_2(DT, 8, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B25047_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component08")

# Step 6: Standardize the component
DT[, component08 := scale(component08), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# missing values? It might be due to no population?
if (interactive()) {
  B25047 <- import_census_table("B25047")
  B25047[DT[is.na(component08)], on = .NATURAL]
}

# save this data to disk
data.table::fwrite(DT, file = "component08.csv")

################################################################################
#                                 End of File                                  #
################################################################################
