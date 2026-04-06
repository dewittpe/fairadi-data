################################################################################
# file: component05.R
#
# Build component 5 of the CDI
#
# Component: 5
#   Crowding (households with more than 1 person ber room), %
# ACS Data Table:
#   B25014
# Table Name:
#   Tenure by occupants per roon
# Numerator Calculation:
#   B25014_005 + B25014_006 + B25014_007 + B25014_011 + B25014_012 + B25014_013
# Denominator Calculation:
#   B25014_001
# Value Calculation with Description:
#   [Owner occupied: 1.01 to 1.50 occupants per room (B25014_005) + Owner occupied: 1.51 to 2.00 occupants per room (B25014_006) + Owner occupied: 2.01 or more occupants per room (B25014_007) + Renter occupied: 1.01 to 1.50 occupants per room (B25014_011) + Renter occupied: 1.51 to 2.00 occupants per room (B25014_012) + Renter occupied: 2.01 or more occupants per room (B25014_013)]/Total (B25014_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B25014")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B25014_%03d", c(5:7, 11:13))
dV <- sprintf("B25014_%03d", 1)
DT <- steps_1_and_2(DT, 5, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B25014_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component05")

# Step 6: Standardize the component
DT[, component05 := scale(component05), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# missing values? It might be due to no population?
if (interactive()) {
  B25014 <- import_census_table("B25014")
  B25014[DT[is.na(component05)], on = .NATURAL]
}

# save this data to disk
# only need block group level data to be saved
DT <- subset(DT, !is.na(block_group))
data.table::fwrite(DT, file = "component05.csv")

################################################################################
#                                 End of File                                  #
################################################################################
