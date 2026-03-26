################################################################################
# file: topic07.R
#
# Objective: build topic07 of the Area Deprivation Index
#
#   Topic: 7
#   Topic Area: Median Gross Rent
#   Detailed Table ID: B25064
#   Calculations:
#     Use B25064_001
#
# Notes:
#   B25063_001 is Gross Rent
#   B25064_001 is Median Gross Rent (Dollars)
#
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B25064")
cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = "B25064_001EA", M = "B25064_001MA")))

if (interactive()) {
  DT[
    !is.na(B25064_001EA) | !is.na(B25064_001MA),
    .N,
    keyby = .(B25064_001E, B25064_001EA, B25064_001M, B25064_001MA)
  ]
}

DT[, topic07_notes := NA_character_]

# Too few samples to compute standard error
DT[
  B25064_001E  == -666666666 &
  B25064_001EA == "-" &
  B25064_001M  == -222222222 &
  B25064_001MA == "**",
  `:=`(B25064_001E = NA_integer_, B25064_001M = NA_integer_, topic07_notes = "QDI-n")
]

# median value in lowest or highest range
DT[
  B25064_001E  == 99 &
  B25064_001EA == "100-" &
  B25064_001M  == -333333333 &
  B25064_001MA == "***",
  `:=`(B25064_001E = NA_integer_, B25064_001M = NA_integer_, topic07_notes = "QDI-range")
]

DT[
  B25064_001E  == 3501 &
  B25064_001EA == "3,500+" &
  B25064_001M  == -333333333 &
  B25064_001MA == "***",
  `:=`(B25064_001E = NA_integer_, B25064_001M = NA_integer_, topic07_notes = "QDI-range")
]

# all annotations have been addressed
stopifnot(
  DT[
    !is.na(B25064_001EA) | !is.na(B25064_001MA),
    all(is.na(B25064_001E)) & all(is.na(B25064_001M))
    ]
)

# There are missing values, we will use a geographic imputation.
# We also apply a shrinkage
DT <-
  merge(
    x = shrink(DT, "B25064_001"),
    DT[, .SD, .SDcols = c(COLS_TO_KEEP, "topic07_notes")],
    all = TRUE,
    by = COLS_TO_KEEP
  )

data.table::setnames(
  x = DT,
  old = c("B25064_001_shrunk", "B25064_001E",        "B25064_001E_geo"),
  new = c("topic07_shrunk",    "topic07_not_shrunk", "topic07_geo")
)

################################################################################
cols_to_keep <- c(COLS_TO_KEEP, "topic07_shrunk", "topic07_geo", "topic07_not_shrunk", "topic07_notes")
data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic07.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
