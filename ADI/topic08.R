################################################################################
# file: topic08.R
#
# Objective: build topic08 of the Area Depredation Index
#
#   Topic: 8
#   Topic Area: Median Monthly Mortgage
#   Detailed Table ID: B25087
#   Calculations:
#     Use B25087_001
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B25087")

cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# There are missing values, we will use a geographic imputation.
# We also apply a shrinkage
DT <- shrink(DT, "B25087_001")

data.table::setnames(
  x = DT,
  old = c("B25087_001_shrunk", "B25087_001E",        "B25087_001E_geo"),
  new = c("topic08_shrunk",    "topic08_not_shrunk", "topic08_geo")
)

################################################################################
cols_to_keep <- c(COLS_TO_KEEP, "topic08_shrunk", "topic08_geo", "topic08_not_shrunk")
data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic08.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
