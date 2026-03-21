################################################################################
# file: adi.R
#
# Build the Area Deprivation Index data and US Census Data
#
# Inputs:
#   topic{01..17}.csv, each built by a similar named .R file
#
################################################################################
# For the moment, no spatial data, so use data.table
source("adi_utilities.R")

adi <-
  list.files(
    path = ".",
    pattern = "topic\\d{2}\\.csv\\.gz$",
    full.name = TRUE
  ) |>
  lapply(
    data.table::fread,
  ) |>
  lapply(data.table::setkeyv, COLS_TO_KEEP)

adi <- Reduce(f = function(x, y) {merge(x, y, all = TRUE)}, x = adi)

# only looking at block groups
adi <- subset(adi, !is.na(block_group))

adi[,
  adi_raw :=
    topic01 *  0.0849 +
    topic02 * -0.0970 +
    topic03 * -0.0874 +
    #topic04_not_shrunk * -0.0977 +
    topic04_shrunk * -0.0977 +
    #topic05_wo_epsilon *  0.0936 +
    topic05_w_epsilon *  0.0936 +
    #topic06_not_shrunk * -0.0688 +
    topic06_shrunk * -0.0688 +
    #topic07_not_shrunk * -0.0781 +
    topic07_shrunk * -0.0781 +
    #topic08_not_shrunk * -0.0770 +
    topic08_shrunk * -0.0770 +
    topic09 * -0.0615 +
    topic10 *  0.0806 +
    topic11 *  0.0977 +
    topic12 *  0.1037 +
    topic13 *  0.0719 +
    topic14 *  0.0694 +
    topic15_new *  0.0877 +
    topic16 *  0.0510 +
    topic17 *  0.0556
  ]

# The ADI uses some block group suppression
# https://www.neighborhoodatlas.medicine.wisc.edu/changelog#:~:text=Changes%20between%20versions%20of%20the%20ADI%2C%2011/19/2020
#
# > Block group suppression: We have applied the same Diez Roux suppression
# > criteria used in the earlier 2013 and 2015 builds: any block group with fewer
# > than 100 persons, fewer than 30 housing units, or greater than 33% of the
# > population living in group quarters will not receive an ADI ranking. In
# > addition, we have suppressed of a small number of block groups which include
# > those with survey errors acknowledged by the US Census Bureau.

total_population <- data.table::fread("total_population.csv.gz")
housing_units    <- data.table::fread("housing_units.csv.gz")
group_quarters   <- data.table::fread("group_quarters.csv.gz")

total_population <- subset(total_population, !is.na(block_group))
housing_units    <- subset(housing_units,    !is.na(block_group))
group_quarters   <- subset(group_quarters,   !is.na(block_group))

adi <-
  merge(
    x = adi,
    y = total_population,
    all.x = TRUE,
    by = COLS_TO_KEEP
  )

adi <-
  merge(
    x = adi,
    y = housing_units,
    all.x = TRUE,
    by = COLS_TO_KEEP
  )

adi <-
  merge(
    x = adi,
    y = group_quarters,
    all.x = TRUE,
    by = COLS_TO_KEEP
  )

# exclude reason
adi[
  ,
  exclude_reason :=
    data.table::fcase(
      (total_population < 100 | housing_units < 30) & group_quarters >= 1/3, "GQ-PH",
      (total_population < 100 | housing_units < 30),                         "PH",
      group_quarters >= 1/3,                                                 "GQ",
      is.na(adi_raw),                                                        "QDI",
      default = NA_character_
    )
]

adi[, exclude_from_ranking := as.integer(!is.na(exclude_reason))]

if (interactive()) {
  print(adi[, .N, keyby = .(exclude_from_ranking, exclude_reason)], nrow = Inf)
}

################################################################################
# set national ranks
# adi[!is.na(adi_raw) & exclude == 0, national_rank := as.integer(cut(adi_raw, breaks = 100))]
#
# possible ties methods: average, first, last, random, max, min, dense
adi[!is.na(adi_raw) & exclude_from_ranking == 0,
  national_rank := ceiling(100 * data.table::frank(adi_raw, ties.method = "average") / .N),
  by = .(year)
]

# set state rank
adi[!is.na(adi_raw) & exclude_from_ranking == 0,
  state_rank := ceiling(10 * data.table::frank(adi_raw, ties.method = "average") / .N),
  by = .(year, state)
]

################################################################################
# save to disk
adi[, FIPS := build_FIPS(state, county, tract, block_group)]
cols_to_keep <-
  c(
    COLS_TO_KEEP,
    "FIPS",
    "adi_raw",
    "exclude_from_ranking", "exclude_reason",
    "national_rank", "state_rank"
  )
adi <- adi[, .SD, .SDcols = cols_to_keep]
data.table::fwrite(x = adi, file = "adi.csv")

################################################################################
#                                 End of File                                  #
################################################################################
