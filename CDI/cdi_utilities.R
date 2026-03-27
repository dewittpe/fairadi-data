################################################################################
# file cdi_utilities.R
source("../utilities/import_census_table.R")
source("../utilities/check_for_annotations.R")
COLS_TO_KEEP <- c("year", "state", "county", "tract", "block_group")

################################################################################
# Join Total Population and Houseing Units
join_tphu <- function(DT) {
  tphu <- data.table::fread("total_population_and_housing_units.csv.gz")
  merge(DT, tphu, all.x = TRUE, by = c("year", "GEO_ID"))
}

################################################################################
# Step 4 and 5 of the CDI build requires shrinking the value and geographic
# imputation.  The following function does that.
shrink <- function(DT, variable) {
  stopifnot(inherits(DT, "data.table"))
  stopifnot(is.character(variable))
  VE <- paste0(variable, "E")
  VM <- paste0(variable, "M")
  stopifnot(VE %in% names(DT), VM %in% names(DT))

  # Inter geographic level variance
  bgshrunk <-
    merge(
      DT[!is.na(block_group),                 .SD, .SDcols = c("year", "state", "county", "tract", "block_group", VE, VM)],
      DT[ is.na(block_group) & !is.na(tract), .SD, .SDcols = c("year", "state", "county", "tract",                VE, VM)],
      all.x = TRUE,
      by = c("year", "state", "county", "tract"),
      suffixes = c("_x", "_z")
    )
  tractshrunk <-
    merge(
      DT[ is.na(block_group) & !is.na(tract),                  .SD, .SDcols = c("year", "state", "county", "tract", VE, VM)],
      DT[ is.na(block_group) &  is.na(tract) & !is.na(county), .SD, .SDcols = c("year", "state", "county",          VE, VM)],
      all.x = TRUE,
      by = c("year", "state", "county"),
      suffixes = c("_x", "_z")
    )
  countyshrunk <-
    merge(
      DT[ is.na(block_group) &  is.na(tract) & !is.na(county),                 .SD, .SDcols = c("year", "state", "county", VE, VM)],
      DT[ is.na(block_group) &  is.na(tract) &  is.na(county) & !is.na(state), .SD, .SDcols = c("year", "state",           VE, VM)],
      all.x = TRUE,
      by = c("year", "state"),
      suffixes = c("_x", "_z")
    )

  etsq <- parse(text = sprintf("1/(.N - 1) * sum((%s_x - %s_z)^2)", VE, VE))
  bgshrunk[,     tsq := eval(etsq), keyby = .(year, state, county, tract)]
  tractshrunk[,  tsq := eval(etsq), keyby = .(year, state, county)]
  countyshrunk[, tsq := eval(etsq), keyby = .(year, state)]

  bgshrunk[,     Ssq := (.SD/1.645)^2, .SDcols = paste0(VM, "_x")]
  tractshrunk[,  Ssq := (.SD/1.645)^2, .SDcols = paste0(VM, "_x")]
  countyshrunk[, Ssq := (.SD/1.645)^2, .SDcols = paste0(VM, "_x")]

  bgshrunk[,     w := (1/Ssq) / (1/Ssq + 1/tsq)]
  tractshrunk[,  w := (1/Ssq) / (1/Ssq + 1/tsq)]
  countyshrunk[, w := (1/Ssq) / (1/Ssq + 1/tsq)]

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

  # set the block_group value to NA if flag_for_replacement is 1
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
