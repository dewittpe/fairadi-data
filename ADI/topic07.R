################################################################################
# file: topic07.R
#
# Objective: build topic07 of the Area Depredation Index
#
#   Topic: 7
#   Topic Area: Median Gross Rent
#   Detailed Table ID: B25063
#   Calculations:
#     Use B25063_001
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B25063")
cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# There are missing values, we will use a geographic imputation.
# We also apply a shrinkage
DT <- shrink(DT, "B25063_001")

data.table::setnames(
  x = DT,
  old = c("B25063_001_shrunk", "B25063_001E",        "B25063_001E_geo"),
  new = c("topic07_shrunk",    "topic07_not_shrunk", "topic07_geo")
)

################################################################################
cols_to_keep <- c(COLS_TO_KEEP, "topic07_shrunk", "topic07_geo", "topic07_not_shrunk")
data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic07.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
