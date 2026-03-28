################################################################################
# file: faircdi.R
#
# Steps 7, 8, and 9 for the CDI process
#
################################################################################

# step 7: PCA

components <-
  list.files(
    path = ".",
    pattern = "^component\\d{2}\\.csv\\.gz",
    full.names = TRUE
  ) |>
  lapply(data.table::fread) |>
  Reduce(
    function(x, y) {
      merge(x, y, all = TRUE, by = c("year", "state", "county", "tract", "block_group"))
    },
    x = _
  ) |>
  split(by = "year")

pcas <-
  lapply(components,
    function(data, ...) {
      stats::prcomp(
        formula =
          ~ component01 + component02 + component03 + component04 +
            component05 + component06 + component07 + component08 +
            component09 + component10 + component11 + component12 +
            component13 + component14 + component15 + component16 +
            component17 + component18,
        data = data,
        center = FALSE, # data has alredy been scaled
        scale  = FALSE  # data has alredy been scaled
      )
    }
  )

faircdi <-
  Map(f =
    function(x,p) {
      data.table::set(
        x,
        j = "cdiraw",
        value = as.numeric(as.matrix(x[, .SD, .SDcols = patterns("component")]) %*% p$rotation[, 1])
      )
    },
    x = components,
    p = pcas
  ) |>
  data.table::rbindlist()

# step 8: standardize to have mean 100, standard deviation 20
faircdi[, cdistd := 100 + 20 * scale(cdiraw), by = .(year)]

# step 9, set percentiles
faircdi[, faircdi := ceiling(100 * data.table::frank(cdiraw, ties.method = "average") / .N), by = .(year)]

# write to disk
data.table::fwrite(faircdi, file = "faircdi.csv")

################################################################################
#                                 End of File                                  #
################################################################################
