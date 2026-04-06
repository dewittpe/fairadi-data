################################################################################
# verify integer
#
# verify columns you expect to be integers are integers

verify_integer <- function(DT, cols = grep("(E|M)$", names(DT), value = TRUE)) {
  stopifnot(inherits(DT, "data.table"))
  for (j in cols) {
    if (!(j %in% names(DT))) {
      stop(sprintf("%s is not in names(%s)", j, deparse1(substitute(DT))))
    }
    if (!is.integer(DT[[j]])) {
      stop(sprintf("%s[[%s]] is expected to be an integer but is a %s",
          deparse1(substitute(DT)), j, mode(DT[[j]])))
    }
  }
  invisible(TRUE)
}

################################################################################
#                                 End of File                                  #
################################################################################
