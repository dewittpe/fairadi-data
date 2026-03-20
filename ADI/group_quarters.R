################################################################################
# file: group_quarters.R
#
# Objective: build a data.table with the % of population in group quarters
#
################################################################################
source("adi_utilities.R")
pop <- import_census_table("P1")
gq  <- import_census_table("P18")

DT <-
  merge(
    x = pop[, .SD, .SDcols = c(COLS_TO_KEEP, "P1_001N")],
    y = gq[,  .SD, .SDcols = c(COLS_TO_KEEP, "P18_001N")],
    all = TRUE,
    by = COLS_TO_KEEP
  )

DT[, group_quarters := P18_001N / P1_001N]

# Sanity checks: all the percent_group_quarters should be between 0 and 100. NA
# values are due to zero total population.
stopifnot(
  DT[is.na(group_quarters), all(P1_001N == 0)],
  DT[, all(group_quarters >=   0, na.rm = TRUE)],
  DT[, all(group_quarters <=   1, na.rm = TRUE)]
)

# the base cols_to_keep is defined in adi_utilities.R
cols_to_keep <- c(COLS_TO_KEEP, "group_quarters")

data.table::fwrite(
  x = DT[, .SD, .SDcols = cols_to_keep],
  file = "group_quarters.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
