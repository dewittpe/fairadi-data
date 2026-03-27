################################################################################
# file: adi_utilities.R
#
# Objective: define several utilities to simplify the building of the ADI
#
# Methods defined in this file:
#
#   geographic_imputation
#   shrinkage_weights
#   shrink
#
# Variables defined in this file
#
#   COLS_TO_KEEP
#
################################################################################
COLS_TO_KEEP <- c("year", "state", "county", "tract", "block_group")

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
  i <- which(is.na(d[[VS]]))
  stopifnot(
    d[i, all(.SD == "state"), .SDcols = VG]
  )

  # return
  d
}

################################################################################
#                                 End of File                                  #
################################################################################
