################################################################################
# file: faircdi.R
#
# Steps 7, 8, and 9 for the CDI process
#
# NOTES:
#
#   Component01: The earliest ACS 5-year estimates for B15003 are available in
#     2012. ACS 1-year estimates do go back to 2010, but because this project
#     uses ACS 5-year estimates, this component is not available for 2010 and
#     2011.
#
#   Component02: The earliest ACS 5-year estimates for B15003 are available in
#     2012. ACS 1-year estimates do go back to 2010, but because this project
#     uses ACS 5-year estimates, this component is not available for 2010 and
#     2011.
#
#   Component09: Due to its unique shrinkage and build process, this component
#     can appear in years before 2013.
#
#   Component17: The earliest ACS 5-year estimates for B23025 are available in
#     2011.
#
#   Component18: The earliest ACS 5-year estimates for B27010 are available in
#     2013.
#
################################################################################
source("cdi_utilities.R")

# Step 7: PCA

# import all the components
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
  )

# subset to viable years
components <- components[year >= 2013L]

# split by year and run PCA
components <- split(components, by = "year")

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
        center = FALSE, # data have already been scaled
        scale  = FALSE  # data have already been scaled
      )
    }
  )

# Orient the first principal component so higher scores consistently reflect
# higher deprivation. "Bad" components increase with deprivation, while "good"
# components are protective and should decrease as deprivation worsens.
# `affluence_components` and `deprivation_components` are defined in cdi_utilities.R
weights <-
  lapply(
    pcas,
    function(p) {
      w <- p$rotation[, 1]
      if (sum(w[deprivation_components]) - sum(w[affluence_components]) < 0) {
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

# Step 8: standardize to have mean 100 and standard deviation 20
faircdi[, cdistd := 100 + 20 * scale(cdiraw), by = .(year)]

# Step 9: set percentiles
faircdi[, faircdi := ceiling(100 * data.table::frank(cdiraw, ties.method = "average") / .N), by = .(year)]


# sanity check
#
# positive correlations with the deprivation-direction components (deprivation_components):
#   component01, component04, component05, component06, component07,
#   component08, component09, component14, component16, component17, component18
#
# negative correlations with the protective/affluence components (affluence_components):
#   component02, component03, component10, component11, component12,
#   component13, component15
cormat <-
  cor(
    faircdi[, .SD, .SDcols = c(deprivation_components, affluence_components, "faircdi")],
    use = "pairwise.complete.obs",
    method = "pearson"
  )

stopifnot(
  cormat[affluence_components, "faircdi"] < 0,
  cormat[deprivation_components,  "faircdi"] > 0
)

################################################################################
# Save faircdi to disk
faircdi[, FIPS := build_FIPS(state, county, tract, block_group)]
# write to disk
data.table::fwrite(
  faircdi[, .SD, .SDcols = c("year", "FIPS", "cdiraw", "cdistd", "faircdi")],
  file = "faircdi.csv"
)

################################################################################
#                                 End of File                                  #
################################################################################
