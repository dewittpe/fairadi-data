################################################################################
# file: topic04.R
#
# Objective: build topic04 of the Area Deprivation Index
#
#   Topic: 4
#   Topic Area: Median Family Income
#   Detailed Table ID: B19113
#   Calculations:
#     Use B19113_001
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B19113")
cfa <- check_for_anotations(DT)

# there are annotations to deal with
if (interactive()) {
  DT[!is.na(B19113_001EA) & !is.na(B19113_001E)]
  DT[, .N, keyby = .(B19113_001EA, B19113_001MA)]
}

DT[, topic04_notes := NA_character_]

# Too few samples to compute standard error
DT[
  B19113_001E  == -666666666 &
  B19113_001EA == "-" &
  B19113_001M  == -222222222 &
  B19113_001MA == "**",
  `:=`(B19113_001E = NA_integer_, B19113_001M = NA_integer_, topic04_notes = "QDI-n")
]

# median value in lowest or highest range
DT[
  B19113_001E  == 2499 &
  B19113_001EA == "2,500-" &
  B19113_001M  == -333333333 &
  B19113_001MA == "***",
  `:=`(B19113_001E = NA_integer_, B19113_001M = NA_integer_, topic04_notes = "QDI-range")
]

DT[
  B19113_001E  == 250001 &
  B19113_001EA == "250,000+" &
  B19113_001M  == -333333333 &
  B19113_001MA == "***",
  `:=`(B19113_001E = NA_integer_, B19113_001M = NA_integer_, topic04_notes = "QDI-range")
]

# There are missing values, we will use a geographic imputation.
# We also apply a shrinkage.  Both are done using shrink()
DT <-
  merge(
    x = shrink(DT, "B19113_001"),
    DT[, .SD, .SDcols = c(COLS_TO_KEEP, "topic04_notes")],
    all = TRUE,
    by = COLS_TO_KEEP
  )

data.table::setnames(
  x = DT,
  old = c("B19113_001_shrunk", "B19113_001E",        "B19113_001E_geo"),
  new = c("topic04_shrunk",    "topic04_not_shrunk", "topic04_geo")
)

################################################################################
cols_to_keep <- c(COLS_TO_KEEP, "topic04_shrunk", "topic04_geo", "topic04_not_shrunk", "topic04_notes")
data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic04.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
