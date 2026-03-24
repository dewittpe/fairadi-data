#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args) >= 1L) args[[1]] else "."

required_namespaces <- c(
  "data.table",
  "digest",
  "ggplot2",
  "ggplotify",
  "gridExtra",
  "kableExtra",
  "knitr",
  "pcaPP",
  "qwraps2",
  "scales"
)

scan_files <- c(
  list.files(file.path(root, "ADI"), pattern = "\\.[Rr](md)?$", full.names = TRUE),
  list.files(file.path(root, "utilities"), pattern = "\\.[Rr]$", full.names = TRUE)
)
scan_files <- normalizePath(scan_files[file.exists(scan_files)], winslash = "/", mustWork = FALSE)

extract_namespaces <- function(path) {
  lines <- readLines(path, warn = FALSE)
  matches <- regmatches(lines, gregexpr("[A-Za-z][A-Za-z0-9.]+::[A-Za-z][A-Za-z0-9._]*", lines, perl = TRUE))
  refs <- unique(sub("::.*$", "", unlist(matches, use.names = FALSE)))
  refs[nzchar(refs)]
}

found_namespaces <- sort(unique(unlist(lapply(scan_files, extract_namespaces), use.names = FALSE)))

cat("Checking R namespace usage in:\n")
for (path in scan_files) {
  cat(" -", sub(paste0("^", normalizePath(root, winslash = "/", mustWork = FALSE), "/?"), "", path), "\n")
}

cat("\nExpected namespaces:\n")
cat(paste(required_namespaces, collapse = ", "), "\n")

cat("\nNamespaces found via explicit pkg:: calls:\n")
cat(paste(found_namespaces, collapse = ", "), "\n")

missing_from_declared <- setdiff(found_namespaces, required_namespaces)
unused_declared <- setdiff(required_namespaces, found_namespaces)

if (length(missing_from_declared) > 0L) {
  cat("\nFound namespace-qualified packages not listed in required_namespaces:\n", file = stderr())
  cat(paste(" -", missing_from_declared), sep = "\n", file = stderr())
  cat("\n", file = stderr())
}

if (length(unused_declared) > 0L) {
  cat("\nDeclared namespaces not seen in pkg:: calls:\n", file = stderr())
  cat(paste(" -", unused_declared), sep = "\n", file = stderr())
  cat("\n", file = stderr())
}

availability <- vapply(required_namespaces, requireNamespace, logical(1), quietly = TRUE)

if (!all(availability)) {
  cat("\nMissing installed namespaces:\n", file = stderr())
  cat(paste(" -", required_namespaces[!availability]), sep = "\n", file = stderr())
  cat("\n", file = stderr())
}

if (length(missing_from_declared) > 0L || length(unused_declared) > 0L || !all(availability)) {
  quit(status = 1L)
}

cat("\nAll required namespaces are installed and the declared list matches explicit pkg:: usage.\n")
