################################################################################
# file: topic05.R
#
# Objective: build topic05 of the Area Deprivation Index
#
#   Topic: 5
#   Topic Area: Income Disparity (Singh Index)
#   Detailed Table ID: B19001
#   Calculations:
#     Numerator: B19001_002.
#     Denominator: Sum B19001_011 to B19001_017.
#     Calculate: log(100 × Num / Den)
#
# NOTES:
#   * the numerator and denominator use 1/total_population as a buffer to ensure
#     that ratio is non-zero and the log does not return Inf.
#
################################################################################
source("../utilities/import_census_table.R")
source("../utilities/check_for_annotations.R")
source("adi_utilities.R")
DT <- import_census_table("B19001")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

total_population <- data.table::fread("total_population.csv.gz")

DT <- merge(DT, total_population, all.x = TRUE, by = COLS_TO_KEEP)

# build the topic
DT[
  ,
  `:=`(
    topic05_wo_epsilon = log(100 * B19001_002E / rowSums(.SD, na.rm = TRUE)),
    topic05_w_epsilon  = log(100 * (B19001_002E + (1/total_population)) / (rowSums(.SD, na.rm = TRUE) + (1/total_population)))
  )
  ,
  .SDcols = sprintf("B19001_%03dE", c(2, 11:17))
]

# what about the missing values?  All due to a zero total population
stopifnot(DT[is.na(topic05_w_epsilon), all(total_population == 0)])

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "topic05_wo_epsilon", "topic05_w_epsilon")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic05.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
