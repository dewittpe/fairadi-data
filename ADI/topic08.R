################################################################################
# file: topic08.R
#
# Objective: build topic08 of the Area Deprivation Index
#
#   Topic: 8
#   Topic Area: Median Monthly Mortgage
#   Detailed Table ID: B25088
#   Calculations:
#     Use B25088_001
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B25088")

cfa <- check_for_anotations(DT)
stopifnot(identical(cfa, list(E = c("B25088_001EA", "B25088_002EA", "B25088_003EA"), M = c("B25088_001MA", "B25088_002MA", "B25088_003MA"))))

if (interactive()) {
  DT[
    !is.na(B25088_001EA) | !is.na(B25088_001MA),
    .N,
    keyby = .(B25088_001E, B25088_001EA, B25088_001M, B25088_001MA)
  ]
}

# Too few samples to compute standard error
DT[
  B25088_001E  == -666666666 &
  B25088_001EA == "-" &
  B25088_001M  == -222222222 &
  B25088_001MA == "**",
  `:=`(B25088_001E = NA_integer_, B25088_001M = NA_integer_, topic08_notes = "QDI-n")
]

# median value in lowest or highest range
DT[
  B25088_001E  == 99 &
  B25088_001EA == "100-" &
  B25088_001M  == -333333333 &
  B25088_001MA == "***",
  `:=`(B25088_001E = NA_integer_, B25088_001M = NA_integer_, topic08_notes = "QDI-range")
]

DT[
  B25088_001E  == 4001 &
  B25088_001EA == "4,000+" &
  B25088_001M  == -333333333 &
  B25088_001MA == "***",
  `:=`(B25088_001E = NA_integer_, B25088_001M = NA_integer_, topic08_notes = "QDI-range")
]

# all annotations have been addressed
stopifnot(
  DT[
    !is.na(B25088_001EA) | !is.na(B25088_001MA),
    all(is.na(B25088_001E)) & all(is.na(B25088_001M))
    ]
)

# There are missing values, we will use a geographic imputation.
# We also apply a shrinkage
DT <- shrink(DT, "B25088_001")

data.table::setnames(
  x = DT,
  old = c("B25088_001_shrunk", "B25088_001E",        "B25088_001E_geo"),
  new = c("topic08_shrunk",    "topic08_not_shrunk", "topic08_geo")
)

################################################################################
cols_to_keep <- c(COLS_TO_KEEP, "topic08_shrunk", "topic08_geo", "topic08_not_shrunk")
data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "topic08.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
