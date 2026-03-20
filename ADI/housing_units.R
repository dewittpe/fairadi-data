################################################################################
# file: housing_units.R
#
# Objective: build a data.table with the number of housing units
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B25001")
cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

data.table::setnames(DT, old = "B25001_001E", new = "housing_units")

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "housing_units")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "housing_units.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
