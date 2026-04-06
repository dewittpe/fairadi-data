################################################################################
# file: topic12.R
#
# Objective: build topic12 of the Area Deprivation Index
#
#   Topic: 12
#   Topic Area: % Pop Below 150% of Poverty Threshold
#   Detailed Table ID: C17002
#   Calculations:
#     Numerator: Sum _002 through _005
#     Denominator: C17002_001
#
################################################################################
source("../utilities/import_census_table.R")
source("../utilities/check_for_annotations.R")
source("../utilities/verify_integer.R")
source("adi_utilities.R")
DT <- import_census_table("C17002")

# verify that columns you expect to be integers are integers
verify_integer(DT)

cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))


# build the topic
DT[
  ,
  topic12 := data.table::fifelse(
               C17002_001E > 0,
               rowSums(.SD, na.rm = TRUE) / C17002_001E,
               NA_real_
             ),
  .SDcols = sprintf("C17002_%03dE", 2:5)
  ]

# Sanity check, all the proportions should be less than 1
stopifnot(all(DT[["topic12"]] <= 1.00, na.rm = TRUE))

# all missing is due to C17002_001
stopifnot(DT[is.na(topic12), all(C17002_001E == 0, na.rm = TRUE)])
DT[is.na(topic12) & C17002_001E == 0, topic12_notes := "QDI-ZD"]

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic12", "topic12_notes")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic12.csv"
)
################################################################################
#                                 End of File                                  #
################################################################################
