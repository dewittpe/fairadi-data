################################################################################
# file: topic14.R
#
# Objective: build topic14 of the Area Depredation Index
#
#   Topic: 14
#   Topic Area: % Households Without a Motor Vehicle
#   Detailed Table ID: B25044
#   Calculations:
#     Numerator: B25044_003 + B25044_010
#     Denominator: B25044_001
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B25044")
cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# build the topic
DT[
  ,
  topic14 := data.table::fifelse(
               B25044_001E > 0,
               rowSums(.SD, na.rm = TRUE) / B25044_001E,
               NA_real_
             ),
  .SDcols = sprintf("B25044_%03dE", c(3, 10))
  ]

# all missing is due to B25044_001
stopifnot(DT[is.na(topic14), all(B25044_001E == 0)])
DT[is.na(topic14) & B25044_001E == 0, topic14_notes := "QDI-ZD"]

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic14", "topic14_notes")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic14.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
