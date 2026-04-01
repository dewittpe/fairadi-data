if (interactive()) {
  cargs <- list("B11012__2018")
} else {
  cargs <- commandArgs(trailingOnly = TRUE)
}

cargs <- strsplit(cargs[[1]], split = "__")[[1]]
VAR <- cargs[1]
YEAR <- cargs[2]

csvgzs <- list.files(
  path = ".",
  pattern = sprintf("%s\\.csv\\.gz$", VAR),
  full.names = TRUE,
  recursive = TRUE
)
csvgzs <- grep(x = csvgzs, pattern = sprintf("\\/%s\\/", YEAR), value = TRUE)
csvgzs <- sort(csvgzs)

DT <- lapply(csvgzs, data.table::fread)
DT <- data.table::rbindlist(DT, use.names = TRUE, fill = TRUE)
if ("block group" %in% names(DT)) {
  data.table::setnames(DT, old = "block group", new = "block_group")
}

# if a column is all "null" there is no reason to save it to disk
keep <- DT[, sapply(.SD, function(x) !all(x == "null"))]
if (length(keep)) {
  keep <- keep[keep]
  DT <- DT[, .SD, .SDcols = names(keep)]
}
if ("NAME" %in% names(DT)) {
  data.table::set(DT, j = "NAME", value = NULL)
}

data.table::set(DT, j = "year", value = as.integer(YEAR))

ordered_cols <-
  intersect(c("year", "state", "county", "tract", "block_group", "GEO_ID"), names(DT))
data.table::setcolorder(DT, ordered_cols)

sort_cols <- intersect(c("year", "state", "county", "tract", "block_group", "GEO_ID"), names(DT))
if (length(sort_cols) > 0L) {
  data.table::setorderv(DT, cols = sort_cols, na.last = TRUE)
}

data.table::fwrite(x = DT, file = sprintf("%s__%s.csv", VAR, YEAR), eol = "\n")
