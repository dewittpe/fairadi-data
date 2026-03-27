################################################################################
# file: adi_topic02.R
#
# Objective: build topic02 of the Area Deprivation Index
#
#   Topic: 2
#   Topic Area: % Pop ≥ 25 yrs with >= High School Diploma
#   Detailed Table ID: B15003
#   Calculations:
#     Numerator: Sum _017 to _025
#     Denominator: B15003_001
#
# Notes:
#
# | Variable   | Meaning                                    | Part of topic02 |
# | :--------- | :----------------------------------------- | :-------------: |
# | B15003_001 | Total                                      | Denominator     |
# | B15003_002 | No schooling completed                     |                 |
# | B15003_003 | Nursery school                             |                 |
# | B15003_004 | Kindergarten                               |                 |
# | B15003_005 | 1st grade                                  |                 |
# | B15003_006 | 2nd grade                                  |                 |
# | B15003_007 | 3rd grade                                  |                 |
# | B15003_008 | 4th grade                                  |                 |
# | B15003_009 | 5th grade                                  |                 |
# | B15003_010 | 6th grade                                  |                 |
# | B15003_011 | 7th grade                                  |                 |
# | B15003_012 | 8th grade                                  |                 |
# | B15003_013 | 9th grade                                  |                 |
# | B15003_014 | 10th grade                                 |                 |
# | B15003_015 | 11th grade                                 |                 |
# | B15003_016 | 12th grade, no diploma                     |                 |
# | B15003_017 | Regular high school diploma                | Numerator       |
# | B15003_018 | GED or alternative credential              | Numerator       |
# | B15003_019 | Some college, less than 1 year             | Numerator       |
# | B15003_020 | Some college, 1 or more years, no degree   | Numerator       |
# | B15003_021 | Associate's degree                         | Numerator       |
# | B15003_022 | Bachelor's degree                          | Numerator       |
# | B15003_023 | Master's degree                            | Numerator       |
# | B15003_024 | Professional school degree                 | Numerator       |
# | B15003_025 | Doctorate degree                           | Numerator       |
#
################################################################################
source("../utilities/import_census_table.R")
source("../utilities/check_for_annotations.R")
source("adi_utilities.R")

# import needed data
DT <- import_census_table(table = "B15003")
cfa <- check_for_annotations(DT)

# B15003_001MA exists
stopifnot(identical(cfa, list(E = character(0), M = "B15003_001MA")))
# all the annotations are the same:
stopifnot(
  DT[!is.na(B15003_001MA), all(B15003_001MA == "*****")]
)
# see notes in adi_utilities.R; error can be treated as zero in these cases
DT[!is.na(B15003_001MA), B15003_001M := 0L]

# We are interested in working on the block_group level for the ADI
DT <- DT[!is.na(block_group)]

# build the topic
#
# if the denominator is zero set the value to NA and denote as QDI-ZD for
# "Questionable Data Integrity; zero denominator"
#
numerator_variables <- sprintf("B15003_%03dE", 17:25)

DT[
  ,
  topic02 := data.table::fifelse(B15003_001E > 0, rowSums(.SD, na.rm = TRUE) / B15003_001E, NA_real_),
  .SDcols = numerator_variables
  ]

# Sanity check, all the proportions should be less than 1
stopifnot(all(DT[["topic02"]] <= 1.00, na.rm = TRUE))

DT[B15003_001E == 0, topic02_notes := "QDI-ZD"]

# check that all the NA values are accounted for
stopifnot(
  DT[topic02_notes == "QDI-ZD", all(is.na(topic02))],
  DT[is.na(topic02_notes), !any(is.na(topic02))]
)

# save the output to disk
cols_to_keep <-
  c(COLS_TO_KEEP,
    "topic02",
    "topic02_notes"
  )

DT <- DT[, .SD, .SDcols = cols_to_keep]
data.table::setcolorder(DT, neworder = cols_to_keep)
data.table::setkeyv(DT, cols = COLS_TO_KEEP)
data.table::fwrite(DT, file = "topic02.csv")

################################################################################
#                                 End of File                                  #
################################################################################
