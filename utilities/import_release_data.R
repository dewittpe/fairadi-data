#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  requireNamespace("data.table")
  requireNamespace("jsonlite")
})

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

read_release_metadata <- function(root = ".") {
  path <- file.path(root, "metadata.json")
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

find_release_file <- function(metadata, suffix) {
  matches <-
    vapply(
      metadata$files,
      function(x) isTRUE(endsWith(x$path, suffix)),
      logical(1)
    )

  if (!any(matches)) {
    stop(sprintf("Could not find %s in metadata.json", suffix), call. = FALSE)
  }

  metadata$files[[which(matches)[1]]]$path
}

read_json_file <- function(path) {
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

coerce_by_schema <- function(DT, schema) {
  properties <- schema$properties %||% list()

  for (nm in intersect(names(properties), names(DT))) {
    property_type <- properties[[nm]]$type

    if (is.null(property_type)) {
      next
    }

    if (is.list(property_type)) {
      next
    }

    if (length(property_type) > 1L) {
      property_type <- setdiff(property_type, "null")
    }

    if (length(property_type) != 1L) {
      next
    }

    if (property_type == "integer") {
      data.table::set(DT, j = nm, value = as.integer(DT[[nm]]))
    } else if (property_type == "number") {
      data.table::set(DT, j = nm, value = as.numeric(DT[[nm]]))
    } else if (property_type == "string") {
      data.table::set(DT, j = nm, value = as.character(DT[[nm]]))
    }
  }

  DT
}

validate_required_columns <- function(DT, schema, dataset_name) {
  required <- schema$required %||% character(0)
  missing_columns <- setdiff(required, names(DT))

  if (length(missing_columns) > 0L) {
    stop(
      sprintf(
        "%s is missing required columns: %s",
        dataset_name,
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

validate_enum_values <- function(DT, schema, dataset_name) {
  properties <- schema$properties %||% list()

  for (nm in intersect(names(properties), names(DT))) {
    enum_values <- properties[[nm]]$enum

    if (is.null(enum_values)) {
      next
    }

    actual <- unique(DT[[nm]])
    bad <- setdiff(actual, enum_values)

    if (length(bad) > 0L) {
      warning(
        sprintf(
          "%s column %s has values outside schema enum: %s",
          dataset_name,
          nm,
          paste(utils::head(bad, 10L), collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}

read_release_dataset <- function(root = ".", dataset = c("adi", "cdi")) {
  dataset <- match.arg(dataset)
  metadata <- read_release_metadata(root)

  if (dataset == "adi") {
    data_suffix <- "ADI/fairadi.csv.gz"
    schema_suffix <- "ADI/fairadi_schema.json"
    dictionary_suffix <- "ADI/fairadi_data_dictionary.tsv"
    dataset_name <- "fairadi"
  } else {
    data_suffix <- "CDI/faircdi.csv.gz"
    schema_suffix <- "CDI/faircdi_schema.json"
    dictionary_suffix <- "CDI/faircdi_data_dictionary.tsv"
    dataset_name <- "faircdi"
  }

  data_path <- file.path(root, find_release_file(metadata, data_suffix))
  schema_path <- file.path(root, find_release_file(metadata, schema_suffix))
  dictionary_path <- file.path(root, find_release_file(metadata, dictionary_suffix))

  DT <- data.table::fread(data_path)
  schema <- read_json_file(schema_path)
  dictionary <- data.table::fread(dictionary_path)

  DT <- coerce_by_schema(DT, schema)
  validate_required_columns(DT, schema, dataset_name)
  validate_enum_values(DT, schema, dataset_name)

  list(
    metadata = metadata,
    schema = schema,
    dictionary = dictionary,
    data = DT,
    data_path = data_path,
    schema_path = schema_path,
    dictionary_path = dictionary_path
  )
}

read_release_bundle <- function(root = ".") {
  list(
    metadata = read_release_metadata(root),
    adi = read_release_dataset(root, "adi"),
    cdi = read_release_dataset(root, "cdi")
  )
}

if (identical(environment(), globalenv())) {
  bundle <- read_release_bundle(".")

  cat("Imported release bundle from metadata.json\n")
  cat(sprintf("Version: %s\n", bundle$metadata$version))
  cat(sprintf("DOI: %s\n", bundle$metadata$doi))
  cat(sprintf("ADI rows: %s\n", format(nrow(bundle$adi$data), big.mark = ",")))
  cat(sprintf("CDI rows: %s\n", format(nrow(bundle$cdi$data), big.mark = ",")))
  cat(sprintf("ADI years: %s-%s\n", min(bundle$adi$data$year), max(bundle$adi$data$year)))
  cat(sprintf("CDI years: %s-%s\n", min(bundle$cdi$data$year), max(bundle$cdi$data$year)))
}
