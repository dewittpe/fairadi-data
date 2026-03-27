################################################################################
# file: topic11.R
#
# Objective: build topic11 of the Area Deprivation Index
#
#   Topic: 11
#   Topic Area: % Families Below Poverty Level
#   Detailed Table ID: B17010
#   Calculations:
#     Numerator: B17010_002
#     Denominator: B17010_001
#
################################################################################
source("../utilities/import_census_table.R")
source("../utilities/check_for_annotations.R")
source("adi_utilities.R")
DT <- import_census_table("B17010")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# build the topic
DT[
  ,
  topic11 := data.table::fifelse(
               B17010_001E > 0,
               B17010_002E / B17010_001E,
               NA_real_
             ),
  ]

# Sanity check, all the proportions should be less than 1
stopifnot(all(DT[["topic11"]] <= 1.00, na.rm = TRUE))

# all missing is due to B17010_001
stopifnot(DT[is.na(topic11), all(B17010_001E == 0)])
DT[is.na(topic11) & B17010_001E == 0, topic11_notes := "QDI-ZD"]

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic11", "topic11_notes")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic11.csv"
)
################################################################################
#                                 End of File                                  #
################################################################################
