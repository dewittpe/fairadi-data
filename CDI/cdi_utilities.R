################################################################################
# file cdi_utilities.R
source("../utilities/import_census_table.R")
source("../utilities/check_for_annotations.R")
source("../utilities/build_FIPS.R")

COLS_TO_KEEP <- c("year", "state", "county", "tract", "block_group")

################################################################################
# Affluence and deprivation components
deprivation_components <-
  c(
    "component01", # lower education
    "component04", # families below poverty
    "component05", # crowding
    "component06", # no high-speed internet
    "component07", # no vehicle
    "component08", # incomplete plumbing
    "component09", # income disparity
    "component14", # one-parent households
    "component16", # below 150% poverty
    "component17", # unemployment
    "component18"  # uninsured
  )
affluence_components <-
  c(
    "component02", # higher education
    "component03", # white-collar employment
    "component10", # higher household income
    "component11", # higher gross rent as area affluence proxy
    "component12", # higher home value
    "component13", # higher mortgage costs as area affluence proxy
    "component15"  # owner-occupied housing
  )

################################################################################
# Join Total Population and Houseing Units
join_tphu <- function(DT) {
  tphu <- data.table::fread("total_population_and_housing_units.csv.gz")
  merge(DT, tphu, all.x = TRUE, by = c("year", "GEO_ID"))
}

################################################################################
steps_1_and_2 <- function(DT, component, numerator_variables, denominator_variables = NULL) {
  stopifnot(inherits(DT, "data.table"))
  stopifnot(as.integer(component) %in% as.integer(1:18))
  compE <- sprintf("component%02dE", as.integer(component))
  compM <- sprintf("component%02dM", as.integer(component))

  # step1: build component estimate
  n <- DT[, rowSums(.SD), .SDcols = paste0(numerator_variables, "E")]

  if (!is.null(denominator_variables)) {
    d <- DT[, rowSums(.SD), .SDcols = paste0(denominator_variables, "E")]
  } else {
    d <- rep(1, length(n))
  }

  data.table::set(x = DT, j = compE, value = n/d)

  if (is.null(denominator_variables)) {
    moe <- DT[, sqrt(rowSums(.SD^2)), .SDcols = paste0(numerator_variables, "M")]
    data.table::set(DT, j = compM, value = moe)
  } else {
    DT[, m1sq := rowSums(.SD^2), .SDcols = paste0(numerator_variables, "M")]
    DT[, m2sq := rowSums(.SD^2), .SDcols = paste0(denominator_variables, "M")]
    DT[, x1   := .SD, .SDcols = compE]
    DT[, x2   := rowSums(.SD), .SDcols = paste0(denominator_variables, "E")]
    DT[, radican1 := m1sq - (x1/x2)^2 * m2sq]
    DT[, radican2 := m1sq + (x1/x2)^2 * m2sq]

    if (any(DT[["x1"]]/DT[["x2"]] > 1, na.rm = TRUE)) {
      data.table::set(DT, j = compM, value = DT[, 1/x2 * sqrt(radican2)])
    } else {
      i <- which(DT[["radican1"]] >= 0)
      data.table::set(DT, i = i, j = compM, value = DT[i, 1/x2 * sqrt(radican1)])
      i <- which(DT[["radican1"]] < 0)
      data.table::set(DT, i = i, j = compM, value = DT[i, 1/x2 * sqrt(radican2)])
    }
  }
  DT
}

################################################################################
# Step 4 and 5 of the CDI build requires shrinking the value and geographic
# imputation.  The following function does that.
steps_4_and_5 <- function(DT, variable) {
  stopifnot(inherits(DT, "data.table"))
  stopifnot(is.character(variable))
  VE <- paste0(variable, "E")
  VM <- paste0(variable, "M")
  stopifnot(VE %in% names(DT), VM %in% names(DT))
  DT0 <- DT[flag_for_replacement == 0]

  # Inter geographic level variance
  bgshrunk <-
    merge(
      DT[!is.na(block_group),                 .SD, .SDcols = c("year", "state", "county", "tract", "block_group", VE, VM, "flag_for_replacement")],
      DT[ is.na(block_group) & !is.na(tract), .SD, .SDcols = c("year", "state", "county", "tract",                VE, VM)],
      all.x = TRUE,
      by = c("year", "state", "county", "tract"),
      suffixes = c("_x", "_z")
    )
  tractshrunk <-
    merge(
      DT0[ is.na(block_group) & !is.na(tract),                  .SD, .SDcols = c("year", "state", "county", "tract", VE, VM)],
      DT0[ is.na(block_group) &  is.na(tract) & !is.na(county), .SD, .SDcols = c("year", "state", "county",          VE, VM)],
      all.x = TRUE,
      by = c("year", "state", "county"),
      suffixes = c("_x", "_z")
    )
  countyshrunk <-
    merge(
      DT0[ is.na(block_group) &  is.na(tract) & !is.na(county),                 .SD, .SDcols = c("year", "state", "county", VE, VM)],
      DT0[ is.na(block_group) &  is.na(tract) &  is.na(county) & !is.na(state), .SD, .SDcols = c("year", "state",           VE, VM)],
      all.x = TRUE,
      by = c("year", "state"),
      suffixes = c("_x", "_z")
    )

  etsq <- parse(text = sprintf("1/(.N - 1) * sum((%s_x - %s_z)^2)", VE, VE))
  # Values flagged for replacement are excluded from the block-group shrinkage
  # factor calculation, but retained here so they can still be replaced in Step 5.
  bgshrunk[
    ,
    tsq := if (sum(flag_for_replacement == 0L, na.rm = TRUE) > 1L) {
      1 / (sum(flag_for_replacement == 0L, na.rm = TRUE) - 1L) *
        sum(((get(paste0(VE, "_x")) - get(paste0(VE, "_z")))^2)[flag_for_replacement == 0L], na.rm = TRUE)
    } else {
      NA_real_
    },
    keyby = .(year, state, county, tract)
  ]
  tractshrunk[,  tsq := eval(etsq), keyby = .(year, state, county)]
  countyshrunk[, tsq := eval(etsq), keyby = .(year, state)]

  bgshrunk[,     Ssq := (.SD/1.645)^2, .SDcols = paste0(VM, "_x")]
  tractshrunk[,  Ssq := (.SD/1.645)^2, .SDcols = paste0(VM, "_x")]
  countyshrunk[, Ssq := (.SD/1.645)^2, .SDcols = paste0(VM, "_x")]

  bgshrunk[,     w := 1]
  tractshrunk[,  w := 1]
  countyshrunk[, w := 1]

  # TEAM CDI spec: if the local SE or inter-geography variance is missing or
  # zero, do not apply shrinkage. Keeping w = 1 preserves the local estimate.
  bgshrunk[!is.na(Ssq) & Ssq > 0 & !is.na(tsq) & tsq > 0,     w := (1/Ssq) / (1/Ssq + 1/tsq)]
  tractshrunk[!is.na(Ssq) & Ssq > 0 & !is.na(tsq) & tsq > 0,  w := (1/Ssq) / (1/Ssq + 1/tsq)]
  countyshrunk[!is.na(Ssq) & Ssq > 0 & !is.na(tsq) & tsq > 0, w := (1/Ssq) / (1/Ssq + 1/tsq)]

  eshrunk <- parse(text = sprintf("%s_shrunk := w * %s_x + (1 - w) * %s_z", VE, VE, VE))
  bgshrunk[,     eval(eshrunk)]
  tractshrunk[,  eval(eshrunk)]
  countyshrunk[, eval(eshrunk)]

  data.table::setnames(bgshrunk,     old = paste0(VE, "_shrunk"), new = paste0(VE, "_shrunk_block_group"))
  data.table::setnames(tractshrunk,  old = paste0(VE, "_shrunk"), new = paste0(VE, "_shrunk_tract"))
  data.table::setnames(countyshrunk, old = paste0(VE, "_shrunk"), new = paste0(VE, "_shrunk_county"))

  # build the frame work for the return object
  rtn <-
    merge(
     x =
       merge(
         bgshrunk[,    .SD, .SDcols = c("year", "state", "county", "tract", "block_group", paste0(VE, "_shrunk_block_group"))],
         tractshrunk[, .SD, .SDcols = c("year", "state", "county", "tract",                paste0(VE, "_shrunk_tract"))],
         all.x = TRUE,
         by = c("year", "state", "county", "tract")
       ),
     y = countyshrunk[, .SD, .SDcols = c("year", "state", "county", paste0(VE, "_shrunk_county"))],
     all.x = TRUE,
     by = c("year", "state", "county")
   )

  rtn <-
    merge(
      x = rtn,
      y = DT[, .SD, .SDcols = c("year", "state", "county", "tract", "block_group", "flag_for_replacement")],
      all.x = TRUE,
      by = c("year", "state", "county", "tract", "block_group")
    )

  data.table::set(
    x = rtn,
    i = which(rtn[["flag_for_replacement"]] == 1),
    j = paste0(VE, "_shrunk_block_group"),
    value = NA
  )

  ecoal <- parse(text = sprintf("%s := data.table::fcoalesce(%s_shrunk_block_group, %s_shrunk_tract, %s_shrunk_county)", variable, VE, VE, VE))

  rtn[, eval(ecoal)]

  rtn[, .SD, .SDcols = c("year", "state", "county", "tract", "block_group", variable)]
}

################################################################################
#                                 End of File                                  #
################################################################################
