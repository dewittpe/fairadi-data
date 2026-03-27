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
nVE <- sprintf("B17010_%03dE", 2)
nVM <- sprintf("B17010_%03dM", 2)
DT[ ,
  component04E := rowSums(.SD) / B17010_001E,
  .SDcols = nVE
]

# Step 2: build the MOE
DT[
  ,
  component04M := 1/B17010_001E * sqrt(rowSums(.SD^2) - component04E / B17010_001E * B17010_001M^2),
  .SDcols = nVM
]

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
DT <- shrink(DT, "component04")

# Step 6: Standardize the component
data.table::set(
  x = DT,
  j = "component04",
  value = scale(DT[["component04"]])
)

if (interactive()) {
  # some missing values? -- seems to all be state 11, county 1
  B17010 <- import_census_table("B17010")
  B17010[DT[is.na(component04)], on = c("year", "state", "county", "tract", "block_group")][, .(year, state, county, tract, block_group, B17010_001E, B17010_001M, B17010_002E, B17010_002M)] |> summary()
}

# save this data to disk
data.table::fwrite(DT, file = "component04.csv")

################################################################################
#                                 End of File                                  #
################################################################################
