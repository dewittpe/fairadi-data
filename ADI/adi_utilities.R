################################################################################
# file: adi_utilities.R
#
# Objective: define several utilities to simplify the building of the ADI
#
# Methods defined in this file:
#
#   import_census_table
#   check_for_anotations
#   geographic_imputation
#
# Variables defined in this file
#
#   COLS_TO_KEEP
#
################################################################################
COLS_TO_KEEP <- c("year", "state", "county", "tract", "block_group")

################################################################################
#                             Import census table
#
# Function to import all the yearly files for a specific variable
#
# @param x the table to import
# @param ... passed to data.table::fread
#
# @example
#
import_census_table <- function(table, ...) {
  stopifnot(!is.null(table), is.character(table), length(table) == 1L)
  if (startsWith(table, "P")) {
    path <- "Decennial"
  } else if (startsWith(table, "B") | startsWith(table, "C")) {
    path <- "ACS5"
  } else {
    stop("Expected table name to start with a 'P' for Decennial table, 'B' or 'C' for ACS5 table.")
  }
  path <- file.path("..", path)

  files <-
    list.files(
      path = path,
      pattern = sprintf("%s__\\d{4}\\.csv\\.gz$", table),
      full.names = TRUE
    )

  message(paste("Importing data from:\n ", paste(files, collapse = "\n  "), "\n"))

  DTs <- lapply(files, data.table::fread, na.strings = c("NA", "null"), ...)
  data.table::rbindlist(DTs)
}

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
check_for_anotations <- function(x) {
  stopifnot(inherits(x, "data.frame"))
  E <- endsWith(names(x), "EA")
  M <- endsWith(names(x), "MA")

  if (!any(E) && !any(M)) {
    message("No annotation columns")
  } else {
    message("annotated columns exist!")
  }
  list(E = names(x)[E], M = names(x)[M])
}

################################################################################
#                            Geographic Imputation
#
# When there are missing values, we will use a geographic imputation.  If the
# block_group is missing then the tract level value will be used, if the
# block_group and the tract is missing then the county level value will be used,
# and if the block_group, tract, and county are all missing then the state level
# value will be used.
geographic_imputation <- function(DT, variable = NULL) {
  stopifnot(!is.null(variable))
  stopifnot(is.character(variable))
  VE <- paste0(variable, "E")
  VM <- paste0(variable, "M")
  stopifnot(VE %in% names(DT))
  stopifnot(VM %in% names(DT))
  stopifnot(all(COLS_TO_KEEP %in% names(DT)))
  bg <- DT[!is.na(block_group),                                                  .SD, .SDcols = c("year", "state", "county", "tract", "block_group", VE, VM)]
  tt <- DT[ is.na(block_group) & !is.na(tract),                                  .SD, .SDcols = c("year", "state", "county", "tract",                VE, VM)]
  cy <- DT[ is.na(block_group) &  is.na(tract) & !is.na(county),                 .SD, .SDcols = c("year", "state", "county",                         VE, VM)]
  st <- DT[ is.na(block_group) &  is.na(tract) &  is.na(county) & !is.na(state), .SD, .SDcols = c("year", "state",                                   VE, VM)]

  d <-
    merge(
      x = merge(bg, tt, all.x = TRUE, by = c("year", "state", "county", "tract"), suffixes = c("_bg", "_tt")),
      y = merge(cy, st, all.x = TRUE, by = c("year", "state"), suffixes = c("_cy", "_st")),
      all.x = TRUE,
      by = c("year", "state", "county")
    )

  # coalescing
  data.table::set(
    d,
    j = VE,
    value = data.table::fcoalesce(
      d[[paste0(VE, "_bg")]],
      d[[paste0(VE, "_tt")]],
      d[[paste0(VE, "_cy")]],
      d[[paste0(VE, "_st")]]
    )
  )

  # denote the geographic level the value came from
  bgi <- !is.na(d[[paste0(VE, "_bg")]])
  tti <- !bgi & !is.na(d[[paste0(VE, "_tt")]])
  cyi <- !bgi & !tti & !is.na(d[[paste0(VE, "_cy")]])
  sti <- !bgi & !tti & !cyi & !is.na(d[[paste0(VE, "_st")]])

  data.table::set(d, i = which(bgi), j = paste0(VE, "_geo"), value = "block_group")
  data.table::set(d, i = which(tti), j = paste0(VE, "_geo"), value = "tract")
  data.table::set(d, i = which(cyi), j = paste0(VE, "_geo"), value = "county")
  data.table::set(d, i = which(sti), j = paste0(VE, "_geo"), value = "state")
  
  # set the MOE value
  data.table::set(d, j = VM, value = NA_integer_)
  data.table::set(d, i = which(bgi), j = VM, value = d[[paste0(VM, "_bg")]][which(bgi)])
  data.table::set(d, i = which(tti), j = VM, value = d[[paste0(VM, "_tt")]][which(tti)])
  data.table::set(d, i = which(cyi), j = VM, value = d[[paste0(VM, "_cy")]][which(cyi)])
  data.table::set(d, i = which(sti), j = VM, value = d[[paste0(VM, "_st")]][which(sti)])

  V_varhat <- paste0(variable, "_varhat")
  data.table::set(d, j = V_varhat, value = (d[[VM]]/1.645)^2)

  d[, .SD, .SDcols = c(COLS_TO_KEEP, VE, VM, V_varhat, paste0(VE, "_geo"))]
}

################################################################################
shrinkage_weights <- function(DT, variable) {
  stopifnot(inherits(DT, "data.table"))
  stopifnot(is.character(variable))
  stopifnot(paste0(variable, "E") %in% names(DT))
  stopifnot(paste0(variable, "M") %in% names(DT))
  
  n <- parse(text = sprintf("sum(!is.na(%sE))", variable))
  m <- parse(text = sprintf("mean(%sE, na.rm = TRUE)", variable))
  t <- parse(text = sprintf("max(0, var(%sE, na.rm = TRUE) - mean(%sM/1.645, na.rm = TRUE)^2)", variable, variable))

  state_mu_tau  <- DT[!is.na(state),  .(state_n  = eval(n), state_mu  = eval(m), state_tau_sq  = eval(t)), keyby = .(year, state)]
  county_mu_tau <- DT[!is.na(county), .(county_n = eval(n), county_mu = eval(m), county_tau_sq = eval(t)), keyby = .(year, state, county)]
  tract_mu_tau  <- DT[!is.na(tract),  .(tract_n  = eval(n), tract_mu  = eval(m), tract_tau_sq  = eval(t)), keyby = .(year, state, county, tract)]

  merge(
    merge(tract_mu_tau, county_mu_tau, all = TRUE, by = c("year", "state", "county")),
    state_mu_tau,
    all = TRUE,
    by = c("year", "state")
  )
}

################################################################################
shrink <- function(DT, variable) {
  VE <- paste0(variable, "E")
  VM <- paste0(variable, "M")
  VS <- paste0(variable, "_shrunk")
  VH <- paste0(variable, "_varhat")
  VG <- paste0(variable, "E_geo")

  est <- geographic_imputation(DT, variable)
  sw  <- shrinkage_weights(DT, variable)

  d <- merge(est, sw, all.x = TRUE, by = c("year", "state", "county", "tract"))

  # build the weights
  data.table::set(
    x = d,
    j = "tract_weight",
    value = d[["tract_tau_sq"]] / (d[["tract_tau_sq"]] + d[[VH]])
  )
  data.table::set(
    x = d,
    j = "county_weight",
    value = d[["county_tau_sq"]] / (d[["county_tau_sq"]] + d[[VH]])
  )
  data.table::set(
    x = d,
    j = "state_weight",
    value = d[["state_tau_sq"]] / (d[["state_tau_sq"]] + d[[VH]])
  )

  # there are some missing tract weights because while there are more than one
  # blockgroups in the tract, the data might not have been usable, so if there
  # is only one useable blockgroup in the tract, then the weight is 1.
  i <- which((d[[VG]] == "block_group") & (d[["tract_n"]] == 1) & is.na(d[["tract_weight"]]))
  data.table::set(d, i = i, j = "tract_weight", value = 1)

  # shrink 
  bgi <- which(d[[paste0(variable, "E_geo")]] == "block_group")
  tti <- which(d[[paste0(variable, "E_geo")]] == "tract")
  cyi <- which(d[[paste0(variable, "E_geo")]] == "county")
  sti <- which(d[[paste0(variable, "E_geo")]] == "state")

  data.table::set(d, i = bgi, j = VS, value = NA_real_)
  i <- which(d[[VG]] == "block_group") 
  data.table::set(
    x = d,
    i = i,
    j = VS,
    value = 
      (
        d[[VE]] * d[["tract_weight"]] + (1 - d[["tract_weight"]]) * d[["tract_mu"]]
      )[i]
  )


  i <- which(d[[VG]] == "tract") 
  data.table::set(
    x = d,
    i = i,
    j = VS,
    value = 
      (
        d[[VE]] * d[["county_weight"]] + (1 - d[["county_weight"]]) * d[["county_mu"]]
      )[i]
  )

  i <- which(d[[VG]] == "county") 
  data.table::set(
    x = d,
    i = i,
    j = VS,
    value = 
      (
        d[[VE]] * d[["state_weight"]] + (1 - d[["state_weight"]]) * d[["state_mu"]]
      )[i]
  )

  # if there are any missing values left, all the imputatation should be from
  # the state level data
  stopifnot(
    d[is.na(B19113_001_shrunk), all(.SD == "state"), .SDcols = VG]
  )
  d
}


################################################################################
#                                 End of File                                  #
################################################################################
