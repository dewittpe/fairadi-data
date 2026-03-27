################################################################################
# file: total_population_and_housing_units.R
#
# build a data set to flag geographies requiring replacement due to low
# population or housing units.
#
# Notes: 
#
#   Total population uses B01001_001E in the specification.  B01003_001E
#   provides the same information.  To be consistent with the specification we
#   use B01001_001E.
################################################################################
source("cdi_utilities.R")
B01001 <- import_census_table("B01001")
B25032 <- import_census_table("B25032")

# just a sanity check, B01003_001E and B01001_001E are equivalent.  This is not
# needed for the build but is of interest to me.
B01003 <- import_census_table("B01003")
sanity <- merge(B01001, B01003, all = TRUE, by = c("year", "GEO_ID"))
stopifnot(identical(sanity[["B01003_001E"]], sanity[["B01001_001E"]]))

# now build the data needed for the CDI
tphu <- merge(B01001, B25032, all = TRUE, by = c(COLS_TO_KEEP, "GEO_ID"))

# Address values with annotations
cfa <- check_for_annotations(tphu)
stopifnot(
  identical(
    cfa,
    list(E = character(0), M = c("B01001_001MA", "B01001_002MA", "B01001_003MA", "B01001_006MA", "B01001_007MA", "B01001_011MA", "B01001_012MA", "B01001_015MA", "B01001_016MA", "B01001_026MA", "B01001_027MA", "B01001_030MA", "B01001_031MA", "B01001_035MA", "B01001_036MA", "B01001_039MA", "B01001_040MA"))
  )
)

# | Estimate Value | Annotation Value | Meaning                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
# | -555555555     | *****            | A margin of error is not appropriate because the corresponding estimate is controlled to an independent population or housing estimate. Effectively, the corresponding estimate has no sampling error and the margin of error may be treated as zero.                                                                                                                                                                                                                                                                                                                                                                             |
tphu[!is.na(B01001_001MA), .N, keyby = .(B01001_001M, B01001_001MA)]
tphu[B01001_001MA == -555555555, `:=`(B01001_001M = 0)]
tphu[, flag_for_replacement := as.integer(B25032_001E < 30 | B01001_001E < 100)]

# retain only the needed columns
tphu <- tphu[, .SD, .SDcols = c("year", "GEO_ID", "flag_for_replacement")]

data.table::fwrite(
  x = tphu,
  file = "total_population_and_housing_units.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
