################################################################################
# file: faircdi.R
#
# Steps 7, 8, and 9 for the CDI process
#
################################################################################
source("../utilities/build_FIPS.R")

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

# Orient the first principal component so higher scores consistently reflect
# higher deprivation. "Bad" components increase with deprivation, while "good"
# components are protective and should decrease as deprivation worsens.
bad_components <-
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
good_components <-
  c(
    "component02", # higher education
    "component03", # white-collar employment
    "component10", # higher household income
    "component11", # higher gross rent as area affluence proxy
    "component12", # higher home value
    "component13", # higher mortgage costs as area affluence proxy
    "component15"  # owner-occupied housing
  )

weights <-
  lapply(
    pcas,
    function(p) {
      w <- p$rotation[, 1]
      if (sum(w[bad_components]) - sum(w[good_components]) < 0) {
        w <- -w
      }
      w
    }
  )

faircdi <-
  Map(f =
    function(x, w) {
      data.table::set(
        x,
        j = "cdiraw",
        value = as.numeric(as.matrix(x[, .SD, .SDcols = patterns("^component")]) %*% w)
      )
    },
    x = components,
    w = weights
  ) |>
  data.table::rbindlist()

# step 8: standardize to have mean 100, standard deviation 20
faircdi[, cdistd := 100 + 20 * scale(cdiraw), by = .(year)]

# step 9, set percentiles
faircdi[, faircdi := ceiling(100 * data.table::frank(cdiraw, ties.method = "average") / .N), by = .(year)]

#
# positive correlations with the deprivation-direction components:
#   component01, component04, component05, component06, component07,
#   component08, component09, component14, component16, component17, component18
#
# negative correlations with the protective/affluence components:
#   component02, component03, component10, component11, component12,
#   component13, component15
#
cormat <-
  cor(
    faircdi[, .SD, .SDcols = c(bad_components, good_components, "faircdi")],
    use = "pairwise.complete.obs"
  )

# sanity check
stopifnot(
  cormat[good_components, "faircdi"] < 0,
  cormat[bad_components,  "faircdi"] > 0
)

#pdf(file="corrplot.pdf")
#corrplot::corrplot(cormat, method = "shade")
#dev.off()

################################################################################
# save fairadi to disk
faircdi[, FIPS := build_FIPS(state, county, tract, block_group)]
# write to disk
data.table::fwrite(
  faircdi[, .SD, .SDcols = c("year", "FIPS", "cdiraw", "cdistd", "faircdi")],
  file = "faircdi.csv"
)


################################################################################
#                                 End of File                                  #
################################################################################
