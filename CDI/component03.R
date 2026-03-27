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
nVE <- sprintf("C24010_%03dE", c(3, 27, 39, 63))
nVM <- sprintf("C24010_%03dM", c(3, 27, 39, 63))
DT[ ,
  component03E := rowSums(.SD) / C24010_001E,
  .SDcols = nVE
]

# Step 2: build the MOE
DT[
  ,
  component03M := 1/C24010_001E * sqrt(rowSums(.SD^2) - component03E / C24010_001E * C24010_001M^2),
  .SDcols = nVM
]

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
DT <- shrink(DT, "component03")

# Step 6: Standardize the component
data.table::set(
  x = DT,
  j = "component03",
  value = scale(DT[["component03"]])
)

# save this data to disk
data.table::fwrite(DT, file = "component03.csv")

################################################################################
#                                 End of File                                  #
################################################################################
