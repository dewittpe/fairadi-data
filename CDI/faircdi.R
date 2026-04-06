################################################################################
# file: faircdi.R
#
# Steps 7, 8, and 9 for the CDI process
#
# NOTES:
#
#   Component01: ACS-5-Year Estimates for B15003 eariliest availablity is 2012.
#     ACS-1-Year estimates do go back to 2010, but since we are working with
#     ACS-5-year estiamtes we will not have this component for 2010 and 2011
#
#   Component02: ACS-5-Year Estimates for B15003 eariliest availablity is 2012.
#     ACS-1-Year estimates do go back to 2010, but since we are working with
#     ACS-5-year estiamtes we will not have this component for 2010 and 2011
#
#   Component09: due to a unique shrinkage and build process, this component
#     can, and does, appear in 
#
#   Component17: ACS-5-Year estimtes for B23025 first availablity is 2011
#
#   Component18: ACS-5-Year estimtes for B27010 first availablity is 2013
#
################################################################################
source("cdi_utilities.R")

# step 7: PCA

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
        center = FALSE, # data has alredy been scaled
        scale  = FALSE  # data has alredy been scaled
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

# step 8: standardize to have mean 100, standard deviation 20
faircdi[, cdistd := 100 + 20 * scale(cdiraw), by = .(year)]

# step 9, set percentiles
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
