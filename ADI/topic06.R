################################################################################
# file: topic06.R
#
# Objective: build topic06 of the Area Depredation Index
#
#   Topic: 6
#   Topic Area: Median Home Value
#   Detailed Table ID: B25077
#   Calculations:
#     Use B25077_001
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B25077")
cfa <- check_for_anotations(DT)

# there are annotations to deal with
if (interactive()) {
  DT[!is.na(B25077_001EA) & !is.na(B25077_001E)]
  DT[, .N, keyby = .(B25077_001EA, B25077_001MA)]
}

# Too few samples to compute standard error
DT[
  B25077_001E  == -666666666 &
  B25077_001EA == "-" &
  B25077_001M  == -222222222 &
  B25077_001MA == "**",
  `:=`(B25077_001E = NA_integer_, B25077_001M = NA_integer_, topic06_notes = "QDI-n")
]

# median value in lowest or highest range
DT[
  B25077_001E  == 9999 &
  B25077_001EA == "10,000-" &
  B25077_001M  == -333333333 &
  B25077_001MA == "***",
  `:=`(B25077_001E = NA_integer_, B25077_001M = NA_integer_, topic06_notes = "QDI-range")
]

DT[
  B25077_001E  == 2000001 &
  B25077_001EA == "2,000,000+" &
  B25077_001M  == -333333333 &
  B25077_001MA == "***",
  `:=`(B25077_001E = NA_integer_, B25077_001M = NA_integer_, topic06_notes = "QDI-range")
]

# There are missing values, we will use a geographic imputation.
# We also apply a shrinkage
DT <- shrink(DT, "B25077_001")

data.table::setnames(
  x = DT,
  old = c("B25077_001_shrunk", "B25077_001E",        "B25077_001E_geo"),
  new = c("topic06_shrunk",    "topic06_not_shrunk", "topic06_geo")
)

################################################################################
cols_to_keep <- c(COLS_TO_KEEP, "topic06_shrunk", "topic06_geo", "topic06_not_shrunk")
data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic06.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
