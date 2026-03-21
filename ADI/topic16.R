################################################################################
# file: topic16.R
#
# Objective: build topic16 of the Area Depredation Index
#
#   Topic: 16
#   Topic Area: % Units Without Complete Plumbing
#   Detailed Table ID: B25047
#   Calculations:
#     Numerator: B25047_003
#     Denominator: B25047_001
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B25047")
cfa <- check_for_anotations(DT)
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

# missing only due to denominator
stopifnot(DT[is.na(topic16), all(B25047_001E == 0)])
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
