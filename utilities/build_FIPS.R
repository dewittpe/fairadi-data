################################################################################
# file: build_FIPS.R
#
# Given the numberic (integer) values for state, county, tract, and block group,
# return the correctly formated FIPS.
#
#
build_FIPS <- function(state, county, tract, block_group) {
  stopifnot(length(unique(sapply(list(state, county, tract, block_group), length))) == 1L)
  state <- ifelse(is.na(state), "", sprintf("%02d", state))
  county <- ifelse(is.na(county), "", sprintf("%03d", county))
  tract <- ifelse(is.na(tract), "", sprintf("%06d", tract))
  block_group <- ifelse(is.na(block_group), "", sprintf("%01d", block_group))
  paste0(state, county, tract, block_group)
}

################################################################################
#                                 End of File                                  #
################################################################################
