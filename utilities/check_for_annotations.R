################################################################################
#                            Check for Annotations
#
# It is critically important to look for columns appended with EA "Estimate
# Anotation" or MA for "Margin of Error Annotation."  These columns will
# indicate that the numeric value reported in the respected E or M column is not
# to be treated as a numeric value.
#
# Notes on ACS Estimate and Annotation Values
# (https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-estimate-and-annotation-values.html)
#
# Estimate and Annotation Values
#
# Annotation values are character representations of estimates and have values
# when non-integer information needs to be represented. See the table below for
# a list of common Estimate/Margin of Error (E/M) values and their corresponding
# Annotation (EA/MA) values. Please note that ACS data may return the following
# in place of data.
#
# | Estimate Value | Annotation Value | Meaning                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
# | :---           | :---             | :----                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
# | -666666666     | -                | The estimate could not be computed because there were an insufficient number of sample observations. For a ratio of medians estimate, one or both of the median estimates falls in the lowest interval or highest interval of an open-ended distribution. The estimate could not be computed because there were an insufficient number of sample observations. For a ratio of medians estimate, one or both of the median estimates falls in the lowest interval or highest interval of an open-ended distribution. For a 5-year median estimate, the margin of error associated with a median was larger than the median itself. |
# | -999999999     | N                | The estimate or margin of error cannot be displayed because there were an insufficient number of sample cases in the selected geographic area.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
# | -888888888     | (X)              | The estimate or margin of error is not applicable or not available.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
# | Varies         | median-          | The median falls in the lowest interval of an open-ended distribution (for example "2,500-")                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
# | Varies         | median+          | The median falls in the highest interval of an open-ended distribution (for example "250,000+").                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
# | -222222222     | **               | The margin of error could not be computed because there were an insufficient number of sample observations.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
# | -333333333     | ***              | The margin of error could not be computed because the median falls in the lowest interval or highest interval of an open-ended distribution.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
# | -555555555     | *****            | A margin of error is not appropriate because the corresponding estimate is controlled to an independent population or housing estimate. Effectively, the corresponding estimate has no sampling error and the margin of error may be treated as zero.                                                                                                                                                                                                                                                                                                                                                                             |
# | *              | N/A              | An * indicates that the estimate is significantly different (at a 90% confidence level) than the estimate from the most current year. A "c" indicates the estimates for that year and the current year are both controlled; a statistical test is not appropriate.                                                                                                                                                                                                                                                                                                                                                                |
# | null           | null             | A null value in the estimate means there is no data available for the requested geography.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
#
#' @param x a data.frame (data.table) expected to come from importing the data
#'          via import_census_table.
#'
#' @return a list with two elements, the names of the E and M columns with
#'         annotations.
check_for_annotations <- function(x) {
  stopifnot(inherits(x, "data.frame"))
  E <- endsWith(names(x), "EA")
  M <- endsWith(names(x), "MA")

  if (interactive()) {
    if (!any(E) && !any(M)) {
      message("No annotation columns")
    } else {
      message("annotated columns exist!")
    }
  }
  list(E = names(x)[E], M = names(x)[M])
}

################################################################################
#                                 End of File                                  #
################################################################################
