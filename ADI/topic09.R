################################################################################
# file: topic09.R
#
# Objective: build topic09 of the Area Deprivation Index
#
#   Topic: 9
#   Topic Area: Home Ownership Rate (% Owner-Occupied)
#   Detailed Table ID: B25003
#   Calculations:
#     Numerator: B25003_002
#     Denominator: B25003_001
#
################################################################################
source("../utilities/import_census_table.R")
source("adi_utilities.R")
DT <- import_census_table("B25003")
cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# build the topic
DT[
  ,
  topic09 := data.table::fifelse(
               B25003_001E > 0,
               B25003_002E / B25003_001E,
               NA_real_
             )
  ]

# Sanity check, all the proportions should be less than 1
stopifnot(all(DT[["topic09"]] <= 1.00, na.rm = TRUE))

# all missing values are due to B25003_001 being zero
stopifnot(DT[is.na(topic09), all(B25003_001E == 0)])
DT[is.na(topic09) & B25003_001E == 0, topic09_notes := "QDI-ZD"]

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic09", "topic09_notes")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic09.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
