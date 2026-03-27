################################################################################
# file: total_population.R
#
# Objective:
#   build a data.table with the total population.  This will be used in
#   some topicXX.R scripts.
#
################################################################################
source("../utilities/import_census_table.R")
source("adi_utilities.R")
DT <- import_census_table("B01003")
cfa <- check_for_anotations(DT)

# B01003_001MA exists
stopifnot(identical(cfa, list(E = character(0), M = "B01003_001MA")))
# all the annotations are the same:
stopifnot(
  DT[!is.na(B01003_001MA), all(B01003_001MA == "*****")]
)
# see notes in adi_utilities.R; error can be treated as zero in these cases
DT[!is.na(B01003_001MA), B01003_001M := 0L]

data.table::setnames(DT, old = "B01003_001E", new = "total_population")

cols_to_keep <- c(COLS_TO_KEEP, "total_population")
data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "total_population.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
