################################################################################
# file: topic13.R
#
# Objective: build topic13 of the Area Deprivation Index
#
#   Topic: 13
#   Topic Area: % One-Parent Households (Children < 18)
#   Detailed Table ID: B11003
#   Calculations:
#     Numerator: B11003_010 + B11003_016
#     Denominator: B11003_001
#
################################################################################
source("../utilities/import_census_table.R")
source("../utilities/check_for_annotations.R")
source("../utilities/verify_integer.R")
source("adi_utilities.R")
DT <- import_census_table("B11003")

# verify that columns you expect to be integers are integers
verify_integer(DT)

cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# build the topic
DT[
  ,
  topic13 := data.table::fifelse(
               B11003_001E > 0,
               rowSums(.SD, na.rm = TRUE) / B11003_001E,
               NA_real_
             ),
  .SDcols = sprintf("B11003_%03dE", c(10, 16))
  ]

# Sanity check, all the proportions should be less than 1
stopifnot(all(DT[["topic13"]] <= 1.00, na.rm = TRUE))

# all missing is due to B11003_001
stopifnot(DT[is.na(topic13), all(B11003_001E == 0, na.rm = TRUE)])
DT[is.na(topic13) & B11003_001E == 0, topic13_notes := "QDI-ZD"]

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic13", "topic13_notes")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic13.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
