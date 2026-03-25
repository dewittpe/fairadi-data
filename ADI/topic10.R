################################################################################
# file: topic10.R
#
# Objective: build topic10 of the Area Deprivation Index
#
#   Topic: 10
#   Topic Area: Unemployment Rate (% Civilian Labor Force)
#   Detailed Table ID: B23025
#   Calculations:
#     Numerator: B23025_005
#     Denominator: B23025_002
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B23025")
cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# build the topic
DT[
  ,
  topic10 := data.table::fifelse(
               B23025_002E > 0,
               B23025_005E / B23025_002E,
               NA_real_
             )
  ]

# Sanity check, all the proportions should be less than 1
stopifnot(all(DT[["topic10"]] <= 1.00, na.rm = TRUE))

# all missing is due to B23025_002
stopifnot(DT[is.na(topic10), all(B23025_002E == 0)])
DT[is.na(topic10) & B23025_002E == 0, topic10_notes := "QDI-ZD"]

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic10", "topic10_notes")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic10.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
