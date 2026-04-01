################################################################################
# file: component01.R
#
# Build component 1 of the CDI
#
# Component: 1
#   12 years or less of education, no diploma, %
# ACS Data Table:
#   B15003
# Table Name:
#   Educational attainment for the population over 25 years and over
# Numerator Calculation:
#   sum of the items B15003_002 to B15003_16
# Denominator Calculation:
#   B15003_001
# Value Calculation with Description:
#   [No schooling (B15003_002) + Nursery school (B15003_003) + … + 12th grade, no diploma (B15003_016)]/Total (B15003_001)
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B15003")
cfa <- check_for_annotations(DT)

# B15003_001MA exists
stopifnot(identical(cfa, list(E = character(0), M = "B15003_001MA")))

# all the annotations are the same:
stopifnot(
  DT[!is.na(B15003_001MA), all(B15003_001MA == "*****")]
)
# see notes in ../utilities/check_for_annotations.R; error can be treated as zero in these cases
DT[!is.na(B15003_001MA), B15003_001M := 0L]

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B15003_%03d", 2:16)
dV <- sprintf("B15003_%03d", 1)
DT <- steps_1_and_2(DT, 1, nV, dV)

# Step 3: flag for replacement
DT <- join_tphu(DT)
DT[
  ,
  flag_for_replacement := data.table::fcase(
    B15003_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
DT <- steps_4_and_5(DT, "component01")

# Step 6: Standardize the component
DT[, component01 := scale(component01), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
data.table::fwrite(DT, file = "component01.csv")

################################################################################
#                                 End of File                                  #
################################################################################
