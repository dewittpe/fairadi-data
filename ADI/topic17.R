################################################################################
# file: topic17.R
#
# Objective: build topic17 of the Area Depredation Index
#
#   Topic: 17
#   Topic Area: % Crowding (> 1.00 Person Per Room)
#   Detailed Table ID: B25014
#   Calculations:
#     Numerator: Sum _005, _006, _011, _012
#     Denominator: B25014_001
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B25014")
cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# build the topic
DT[
  ,
  topic17 := data.table::fifelse(
               B25014_001E > 0,
               rowSums(.SD, na.rm = TRUE) / B25014_001E,
               NA_real_
             ),
  .SDcols = sprintf("B25014_%03dE", c(5, 6, 11, 12))
  ]

# missing only due to denominator
stopifnot(DT[is.na(topic17), all(B25014_001E == 0)])
DT[is.na(topic17) & B25014_001E == 0, topic17_notes := "QDI-ZD"]

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic17", "topic17_notes")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic17.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
