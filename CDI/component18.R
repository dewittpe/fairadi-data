################################################################################
# file: component18.R
#
# Build component 18 of the CDI
#
# Component: 18
#   Uninsured, %
# ACS Data Table:
#   B27010
# Table Name:
#   Types of health insureance coverage by age
# Numerator Calculation:
#   B27010_017 + B27010_033 + B27010_050 + B27010_066
# Denominator Calculation:
#   B27010_001
# Value Calculation with Description:
#   No insurance under 19 (B27010_017) + No insurance 19-34 (B27010_033) + no insurance 35- 65 (B27010_050) + no insurance 65 and over (B27010_066)/ Total (B27010_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B27010")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B27010_%03d", c(17, 33, 50, 66))
dV <- sprintf("B27010_%03d", 1)
DT <- steps_1_and_2(DT, 18, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B27010_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component18")

# Step 6: Standardize the component
DT[, component18 := scale(component18), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
data.table::fwrite(DT, file = "component18.csv")

################################################################################
#                                 End of File                                  #
################################################################################
