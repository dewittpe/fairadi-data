################################################################################
# file: component06.R
#
# Build component 6 of the CDI
#
# Component: 6
#   Households without high-speed internet, %
# ACS Data Table:
#   B28002
# Table Name:
#   Presence and types of internet subscriptions in household
# Numerator Calculation:
#   B28002_003 + B28002_0013
# Denominator Calculation:
#   B28002_001
# Value Calculation with Description:
#   [Dial-up with no other type of Internet subscription (B28002_003) + No Internet access (B28002_013)]/Total (B28002_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B28002")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B28002_%03d", c(3, 13))
dV <- sprintf("B28002_%03d", 1)
steps_1_and_2(DT, 6, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B28002_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component06")

# Step 6: Standardize the component
DT[, component06 := scale(component06), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# missing values? It might be due to no population?
if (interactive()) {
  B28002 <- import_census_table("B28002")
  B28002[DT[is.na(component06)], on = .NATURAL]
}

# save this data to disk
data.table::fwrite(DT, file = "component06.csv")

################################################################################
#                                 End of File                                  #
################################################################################
