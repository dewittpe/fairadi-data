################################################################################
#                             Import census table
#
# Function to import all the yearly files for a specific variable
#
# This method is expected to be called from a working directory of either ADI or
# CDI.
#
# @param x the table to import
# @param verbose report the files to be imported via message
# @param ... passed to data.table::fread
#
import_census_table <- function(table, verbose = interactive(), ...) {
  stopifnot(!is.null(table), is.character(table), length(table) == 1L)
  if (startsWith(table, "P") || startsWith(table, "H")) {
    path <- "Decennial"
  } else if (startsWith(table, "B") | startsWith(table, "C")) {
    path <- "ACS5"
  } else {
    stop("Expected table name to start with 'P' or 'H' for Decennial tables, or 'B' or 'C' for ACS5 tables.")
  }
  path <- file.path("..", path)

  files <-
    list.files(
      path = path,
      pattern = sprintf("%s__\\d{4}\\.csv\\.gz$", table),
      full.names = TRUE
    )

  if (verbose) {
    message(paste("Importing data from:\n ", paste(files, collapse = "\n  "), "\n"))
  }

  DTs <- lapply(files, data.table::fread, na.strings = c("NA", "null", "."), ...)
  data.table::rbindlist(DTs, use.names = TRUE, fill = TRUE)
}

################################################################################
#                                 End of File                                  #
################################################################################
