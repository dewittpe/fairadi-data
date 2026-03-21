################################################################################
# file: topic01.R
#
# Objective: build topic01 of the Area Deprivation Index
#
#   Topic: 1
#   Topic Area: % Pop ≥ 25 yrs with < 9 yrs Education
#   Detailed Table ID: B15003
#   Calculations:
#     Numerator: Sum _002 to _012. Denominator: B15003_001
#
# Evaluation:
#
#   Expect this script to be evaluated with the working directory:
#   <repo_root>/ADI
#
# Notes:
#
# | Variable   | Meaning                                    | Part of topic01 |
# | :--------- | :----------------------------------------- | :-------------: |
# | B15003_001 | Total                                      | Denominator     |
# | B15003_002 | No schooling completed                     | Numerator       |
# | B15003_003 | Nursery school                             | Numerator       |
# | B15003_004 | Kindergarten                               | Numerator       |
# | B15003_005 | 1st grade                                  | Numerator       |
# | B15003_006 | 2nd grade                                  | Numerator       |
# | B15003_007 | 3rd grade                                  | Numerator       |
# | B15003_008 | 4th grade                                  | Numerator       |
# | B15003_009 | 5th grade                                  | Numerator       |
# | B15003_010 | 6th grade                                  | Numerator       |
# | B15003_011 | 7th grade                                  | Numerator       |
# | B15003_012 | 8th grade                                  | Numerator       |
# | B15003_013 | 9th grade                                  |                 |
# | B15003_014 | 10th grade                                 |                 |
# | B15003_015 | 11th grade                                 |                 |
# | B15003_016 | 12th grade, no diploma                     |                 |
# | B15003_017 | Regular high school diploma                |                 |
# | B15003_018 | GED or alternative credential              |                 |
# | B15003_019 | Some college, less than 1 year             |                 |
# | B15003_020 | Some college, 1 or more years, no degree   |                 |
# | B15003_021 | Associate's degree                         |                 |
# | B15003_022 | Bachelor's degree                          |                 |
# | B15003_023 | Master's degree                            |                 |
# | B15003_024 | Professional school degree                 |                 |
# | B15003_025 | Doctorate degree                           |                 |
#
################################################################################
source("adi_utilities.R")

# import needed data
DT <- import_census_table(table = "B15003")
cfa <- check_for_anotations(DT)

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
numerator_variables <- sprintf("B15003_%03dE", 2:12)

DT[
  ,
  topic01 := data.table::fifelse(B15003_001E > 0, rowSums(.SD, na.rm = TRUE) / B15003_001E, NA_real_),
  .SDcols = numerator_variables
  ]

DT[B15003_001E == 0, topic01_notes := "QDI-ZD"]

# check that all the NA values are accounted for
stopifnot(
  DT[topic01_notes == "QDI-ZD", all(is.na(topic01))],
  DT[is.na(topic01_notes), !any(is.na(topic01))]
)

# save the output to disk
cols_to_keep <-
  c(COLS_TO_KEEP,
    "topic01",
    "topic01_notes"
  )

DT <- DT[, .SD, .SDcols = cols_to_keep]
data.table::setcolorder(DT, neworder = cols_to_keep)
data.table::setkeyv(DT, cols = COLS_TO_KEEP)
data.table::fwrite(DT, file = "topic01.csv")

################################################################################
#                                 End of File                                  #
################################################################################
