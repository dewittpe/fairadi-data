################################################################################
# file: component13.R
#
# Build component 13 of the CDI
#
# Component: 13
#   Median monthly mortgage ($)
# ACS Data Table:
#   B25088
# Table Name:
#   Median Median selected monthly owner costs (dollars) by mortgage status
# Numerator Calculation:
#   B25088_002
# Denominator Calculation:
#   _not applicable_
# Value Calculation with Description:
#   Median selected monthly owner costs (dollars) -- Housing units with a mortgage (dollars) (B25088_002)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B25088")
cfa <- check_for_annotations(DT)
stopifnot(
  identical(
    cfa,
    list(E = c("B25088_001EA", "B25088_002EA", "B25088_003EA"), M = c("B25088_001MA", "B25088_002MA", "B25088_003MA"))
  )
)

if (interactive()) {
  DT[, .N, keyby = .(B25088_002EA, B25088_002MA)]
  # Key: <B25088_002EA, B25088_002MA>
  #    B25088_002EA B25088_002MA       N
  #          <char>       <char>   <int>
  # 1:         <NA>         <NA> 1417752
  # 2:            -           **  178796
  # 3:         100-          ***      19
  # 4:       4,000+          ***   58349
}
DT[B25088_002EA == "-", B25088_002E := NA]
DT[!is.na(B25088_002MA), B25088_002M := NA]
stopifnot(
  DT[B25088_002EA == "100-", all(B25088_002E == 99)],
  DT[B25088_002EA == "4,000+", all(B25088_002E == 4001)]
)

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B25088_%03d", 2)
dV <- NULL
DT <- steps_1_and_2(DT, 13, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B25088_002EA == "-", 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component13")

# Step 6: Standardize the component
DT[, component13 := scale(component13), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
data.table::fwrite(DT, file = "component13.csv")

################################################################################
#                                 End of File                                  #
################################################################################
