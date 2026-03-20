################################################################################
# file: topic03.R
#
# Objective: build topic03 of the Area Depredation Index
#
#   Topic: 3
#   Topic Area: % Employed ≥ 16 yrs in White-Collar Occs.
#   Detailed Table ID: C24010
#   Calculations:
#      Numerator: Sum _003 to _013 (Male) and _039 to _049 (Female).
#      Denominator: C24010_001
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("C24010")
cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# focus on block_group
DT <- subset(DT, !is.na(block_group))

numerator_variables <- sprintf("C24010_%03dE", c(3:13, 39:49))

DT[
  ,
  topic03 := data.table::fifelse(
               C24010_001E > 0,
               rowSums(.SD, na.rm = TRUE) / C24010_001E,
               NA_real_
             ),
  .SDcols = numerator_variables
  ]

# what about the missing values?  Check that all the missing values are due to a
# zero denominator.
DT[C24010_001E == 0L, topic03_suppression := "QDI-ZD"]
stopifnot(
  DT[is.na(topic03), all(C24010_001E == 0)],
  DT[topic03_suppression == "QDI-ZD", all(is.na(topic03))],
  DT[is.na(topic03_suppression), !any(is.na(topic03))]
)

# save the output to disk
cols_to_keep <-
  c(COLS_TO_KEEP,
    "topic03",
    "topic03_suppression"
  )

DT <- DT[, .SD, .SDcols = cols_to_keep]
data.table::setcolorder(DT, neworder = cols_to_keep)
data.table::setkeyv(DT, cols = COLS_TO_KEEP)
data.table::fwrite(DT, file = "topic03.csv")

################################################################################
#                                 End of File                                  #
################################################################################
