################################################################################
# file: adi_topic15.R
#
# Objective: build topic15 of the Area Deprivation Index
#
# There are two versions.  The original work used % households without a
# telephone, the newer version used % households without internet
#
#   Topic: 15_old
#   Topic Area: Households Without a Telephone
#   Detailed Table ID: B25043
#   Calculations:
#     Numerator: B25043_004
#     Denominator: B25043_001
#
#   Topic: 15
#   Topic Area: Households Without internet
#   Detailed Table ID: B28002
#   Calculations:
#     Numerator: B28002_013
#     Denominator: B28002_001
#
################################################################################
source("../utilities/import_census_table.R")
source("adi_utilities.R")
DT_old <- import_census_table("B25043")
DT_new <- import_census_table("B28002")
DT <- merge(DT_old, DT_new, all = TRUE)

cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

DT[
  ,
  `:=`(
    topic15_old = data.table::fifelse(B25043_001E > 0, B25043_004E / B25043_001E, NA_real_),
    topic15_new = data.table::fifelse(B28002_001E > 0, B28002_013E / B28002_001E, NA_real_)
  )
  ]

# Sanity check, all the proportions should be less than 1
stopifnot(
  all(DT[["topic15_old"]] <= 1.00, na.rm = TRUE),
  all(DT[["topic15_new"]] <= 1.00, na.rm = TRUE)
)

# all missing is due to the denominator
stopifnot(DT[is.na(topic15_old), all(is.na(B25043_001E) | B25043_001E == 0)])
stopifnot(DT[is.na(topic15_new), all(B28002_001E == 0)])

DT[is.na(topic15_old) & B25043_001E == 0, topic15_old_notes := "QDI-ZD"]
DT[is.na(topic15_new) & B28002_001E == 0, topic15_new_notes := "QDI-ZD"]

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic15_old", "topic15_new", "topic15_old_notes", "topic15_new_notes")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic15.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
