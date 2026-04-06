################################################################################
# file: component02.R
#
# Build component 2 of the CDI
#
# Component: 2
#   16+ years of schooling, %
# ACS Data Table:
#   B15003
# Table Name:
#   Educational attainment for the population over 25 years and over
# Numerator Calculation:
#   sum of the items B15003_022 to B15003_025
# Denominator Calculation:
#   B15003_001
# Value Calculation with Description:
#   [Bachelor's degree (B15003_022) + Master's degree (B15003_023) + Professional school degree (B15003_024) + Doctorate degree (B15003_025)]/Total (B15003_001)
#
# NOTE: ACS-5-Year Estimates for B15003 eariliest availablity is 2012.
# ACS-1-Year estimates do go back to 2010, but since we are working with
# ACS-5-year estiamtes we will not have this component for 2010 
# and 2011
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
nV <- sprintf("B15003_%03d", 22:25)
dV <- sprintf("B15003_%03d", 1)
DT <- steps_1_and_2(DT, 2, nV, dV)

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
DT <- steps_4_and_5(DT, "component02")

# Step 6: Standardize the component
DT[, component02 := scale(component02), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
# only need block group level data to be saved
DT <- subset(DT, !is.na(block_group))
data.table::fwrite(DT, file = "component02.csv")

################################################################################
#                                 End of File                                  #
################################################################################
