################################################################################
# file: topic16.R
#
# Objective: build topic16 of the Area Deprivation Index
#
#   Topic: 16
#   Topic Area: % Units Without Complete Plumbing
#   Detailed Table ID: B25047
#   Calculations:
#     Numerator: B25047_003
#     Denominator: B25047_001
#
################################################################################
source("../utilities/import_census_table.R")
source("../utilities/check_for_annotations.R")
source("../utilities/verify_integer.R")
source("adi_utilities.R")
DT <- import_census_table("B25047")

# verify that columns you expect to be integers are integers
verify_integer(DT)

cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# build the topic
DT[
  ,
  topic16 := data.table::fifelse(
               B25047_001E > 0,
               B25047_003E / B25047_001E,
               NA_real_
             )
  ]

# Sanity check, all the proportions should be less than 1
stopifnot(all(DT[["topic16"]] <= 1.00, na.rm = TRUE))

# missing only due to denominator
stopifnot(DT[is.na(topic16), all(B25047_001E == 0, na.rm =  TRUE)])
DT[is.na(topic16) & B25047_001E == 0, topic16_notes := "QDI-ZD"]

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic16", "topic16_notes")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic16.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
