################################################################################
#                             Import census table
#
# Function to import all the yearly files for a specific variable
#
# This method is expected to be called from a working directory of either ADI or
# CDI.
#
# @param x the table to import
# @param ... passed to data.table::fread
#
import_census_table <- function(table, ...) {
  stopifnot(!is.null(table), is.character(table), length(table) == 1L)
  if (startsWith(table, "P")) {
    path <- "Decennial"
  } else if (startsWith(table, "B") | startsWith(table, "C")) {
    path <- "ACS5"
  } else {
    stop("Expected table name to start with a 'P' for Decennial table, 'B' or 'C' for ACS5 table.")
  }
  path <- file.path("..", path)

  files <-
    list.files(
      path = path,
      pattern = sprintf("%s__\\d{4}\\.csv\\.gz$", table),
      full.names = TRUE
    )

  message(paste("Importing data from:\n ", paste(files, collapse = "\n  "), "\n"))

  DTs <- lapply(files, data.table::fread, na.strings = c("NA", "null"), ...)
  data.table::rbindlist(DTs)
}

################################################################################
#                                 End of File                                  #
################################################################################
