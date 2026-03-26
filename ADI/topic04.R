################################################################################
# file: topic04.R
#
# Objective: build topic04 of the Area Deprivation Index
#
#   Topic: 4
#   Topic Area: Median Household Income
#   Detailed Table ID: B19013
#   Calculations:
#     Use B19013_001
#
# Note:
#   Median Household Income is B19013
#   Median Family    Income is B19113
#
# Singh (Am J Public Health. 2003;93:1137–1143) states in Table 1:
# "Median Family Income" which suggests the use of B19113.
#
# A different DI, the Community Deprivation Index uses "Median Household Income"
# with the same factor loading as Singh.
#   Health Affairs Scholar, 2024, 2(12), qxae161
#   https://doi.org/10.1093/haschl/qxae161
#   Advance access publication: November 27, 2024
#
# CMS CDI Uses B19013 explicitly.
#
# An experiment shows that B19013 will match Neighborhood Atlas better than
# B19113.  Evidence:
#
# commit 0184ebf69b26f9a9bfbb882c7f01ae6f2f76343a used B19113
# commit a7c363bac26043ca33f6d90ea0bea71e58ff7799 used B19013
#
# Using B19113:
#                      State Level               National Level
# Year(s)      Spearman  Pearson  Kendall  Spearman  Pearson  Kendall
# 2020 & 2023   0.9688    0.9688   0.9142   0.9866    0.9866   0.9223
# 2020          0.9695    0.9695   0.9155   0.9866    0.9865   0.9223
# 2023          0.9681    0.9681   0.9130   0.9866    0.9866   0.9224
#
# Using B19013
#
#                      State Level               National Level
# Year(s)      Spearman  Pearson  Kendall  Spearman  Pearson  Kendall
# 2020 & 2023   0.9808    0.9808   0.9467   0.9924    0.9924   0.9552
# 2020          0.9819    0.9819   0.9490   0.9927    0.9927   0.9563
# 2023          0.9797    0.9797   0.9444   0.9922    0.9922   0.9542
#
# Using B19113
#                     State Level Deciles         National Level Percentiles
#                               Within                 Within:
# Year(s)      Equal      1       2       3    Equal      1       2       3       4       5       6       7       8       9       10
# 2020 & 2023  0.6729  0.9664  0.9914  0.9967  0.1688  0.4256  0.6015  0.7248  0.8099  0.8669  0.9045  0.9296  0.9469  0.9590  0.9680
# 2020         0.6752  0.9675  0.9919  0.9970  0.1721  0.4264  0.6009  0.7239  0.8091  0.8662  0.9037  0.9286  0.9462  0.9583  0.9675
# 2023         0.6705  0.9654  0.9908  0.9965  0.1655  0.4248  0.6021  0.7258  0.8106  0.8676  0.9053  0.9307  0.9477  0.9598  0.9686
#
# Using B19013
#
#
#                     State Level Deciles         National Level Percentiles
#                               Within                 Within:
# Year(s)     Equal      1       2       3    Equal      1       2       3       4       5       6       7       8       9       10
# 2020 & 2023 0.8013  0.9839  0.9939  0.9973  0.3200  0.6748  0.8272  0.8986  0.9343  0.9541  0.9656  0.9733  0.9787  0.9823  0.9851
# 2020        0.8076  0.9852  0.9946  0.9976  0.3318  0.6816  0.8314  0.9012  0.9365  0.9559  0.9671  0.9745  0.9795  0.9829  0.9855
# 2023        0.7950  0.9827  0.9931  0.9970  0.3083  0.6679  0.8230  0.8961  0.9322  0.9523  0.9642  0.9722  0.9779  0.9817  0.9847
#
#
################################################################################
source("adi_utilities.R")
DT <- import_census_table("B19013")
cfa <- check_for_anotations(DT)

# there are annotations to deal with
if (interactive()) {
  DT[!is.na(B19013_001EA) & !is.na(B19013_001E)]
  DT[, .N, keyby = .(B19013_001EA, B19013_001MA)]
}

DT[, topic04_notes := NA_character_]

# Too few samples to compute standard error
DT[
  B19013_001E  == -666666666 &
  B19013_001EA == "-" &
  B19013_001M  == -222222222 &
  B19013_001MA == "**",
  `:=`(B19013_001E = NA_integer_, B19013_001M = NA_integer_, topic04_notes = "QDI-n")
]

# median value in lowest or highest range
DT[
  B19013_001E  == 2499 &
  B19013_001EA == "2,500-" &
  B19013_001M  == -333333333 &
  B19013_001MA == "***",
  `:=`(B19013_001E = NA_integer_, B19013_001M = NA_integer_, topic04_notes = "QDI-range")
]

DT[
  B19013_001E  == 250001 &
  B19013_001EA == "250,000+" &
  B19013_001M  == -333333333 &
  B19013_001MA == "***",
  `:=`(B19013_001E = NA_integer_, B19013_001M = NA_integer_, topic04_notes = "QDI-range")
]

# There are missing values, we will use a geographic imputation.
# We also apply a shrinkage.  Both are done using shrink()
DT <-
  merge(
    x = shrink(DT, "B19013_001"),
    DT[, .SD, .SDcols = c(COLS_TO_KEEP, "topic04_notes")],
    all = TRUE,
    by = COLS_TO_KEEP
  )

data.table::setnames(
  x = DT,
  old = c("B19013_001_shrunk", "B19013_001E",        "B19013_001E_geo"),
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
