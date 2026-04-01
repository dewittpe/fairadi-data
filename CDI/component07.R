################################################################################
# file: component07.R
#
# Build component 7 of the CDI
#
# Component: 7
#   Households with no vehicle, %
# ACS Data Table:
#   B25044
# Table Name:
#   Tenure by vehicles available
# Numerator Calculation:
#   B25044_003 + B25044_0010
# Denominator Calculation:
#   B25044_001
# Value Calculation with Description:
#   [Owner occupied: No vehicle available (B25044_003) + Renter occupied: No vehicle available (B25044_010)]/Total (B25044_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B25044")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B25044_%03d", c(3, 10))
dV <- sprintf("B25044_%03d", 1)
DT <- steps_1_and_2(DT, 7, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B25044_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component07")

# Step 6: Standardize the component
DT[, component07 := scale(component07), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# missing values? It might be due to no population?
if (interactive()) {
  B25044 <- import_census_table("B25044")
  B25044[DT[is.na(component07)], on = .NATURAL]
}

# save this data to disk
data.table::fwrite(DT, file = "component07.csv")

################################################################################
#                                 End of File                                  #
################################################################################
