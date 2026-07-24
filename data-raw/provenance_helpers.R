# Shared fail-fast helpers for bundled dataset generation.

assert_package_root <- function() {
  if (!file.exists("DESCRIPTION") || !dir.exists("data") ||
      !dir.exists("data-raw")) {
    stop("Run dataset builders from the luxR package root.", call. = FALSE)
  }
  description <- read.dcf("DESCRIPTION", fields = c("Package", "Version"))
  if (!identical(unname(description[1L, "Package"]), "luxR")) {
    stop("DESCRIPTION does not identify the luxR package.", call. = FALSE)
  }
  invisible(description)
}

file_md5 <- function(path) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("Cannot checksum missing source artifact: ", path, call. = FALSE)
  }
  checksum <- unname(tools::md5sum(path))
  if (is.na(checksum) || !grepl("^[0-9a-f]{32}$", checksum)) {
    stop("Could not calculate MD5 for: ", path, call. = FALSE)
  }
  checksum
}

read_manifest <- function() {
  path <- file.path("data-raw", "dataset_manifest.csv")
  manifest <- utils::read.csv(path, stringsAsFactors = FALSE,
                              check.names = FALSE, na.strings = character())
  required <- c(
    "dataset", "output_path", "generator", "source_artifact",
    "source_md5", "source_id", "citation_key", "source_url", "source_doi",
    "retrieval_date", "license", "provenance_status", "units",
    "wavelength_min_nm", "wavelength_max_nm", "wavelength_step_nm",
    "processing_steps", "processing_version"
  )
  if (!identical(names(manifest), required) || !nrow(manifest) ||
      anyNA(manifest) || any(!nzchar(trimws(as.matrix(manifest)))) ||
      anyDuplicated(manifest$dataset)) {
    stop("dataset_manifest.csv has an invalid schema or empty/duplicate fields.",
         call. = FALSE)
  }
  manifest
}

manifest_row <- function(dataset, manifest = read_manifest()) {
  row <- manifest[manifest$dataset == dataset, , drop = FALSE]
  if (nrow(row) != 1L) {
    stop("Expected one manifest row for dataset `", dataset, "`.", call. = FALSE)
  }
  observed <- file_md5(row$source_artifact[[1L]])
  if (!identical(observed, row$source_md5[[1L]])) {
    stop("Source checksum mismatch for `", dataset, "`: expected ",
         row$source_md5[[1L]], ", observed ", observed, ".", call. = FALSE)
  }
  row
}

dataset_provenance <- function(row, configuration = list()) {
  optional_number <- function(value) {
    if (identical(value, "not-applicable")) return(NA_real_)
    value <- as.character(value)
    numeric_pattern <- paste0(
      "^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)",
      "([eE][+-]?[0-9]+)?$"
    )
    if (length(value) != 1L || !grepl(numeric_pattern, value)) {
      stop("Manifest numeric field is invalid for `", row$dataset[[1L]], "`.",
           call. = FALSE)
    }
    parsed <- as.numeric(value)
    if (!is.finite(parsed)) {
      stop("Manifest numeric field is non-finite for `", row$dataset[[1L]], "`.",
           call. = FALSE)
    }
    parsed
  }
  list(
    dataset = row$dataset[[1L]],
    source_id = strsplit(row$source_id[[1L]], ";", fixed = TRUE)[[1L]],
    citation_key = strsplit(row$citation_key[[1L]], ";", fixed = TRUE)[[1L]],
    source_url = row$source_url[[1L]],
    source_doi = row$source_doi[[1L]],
    retrieval_date = row$retrieval_date[[1L]],
    license = row$license[[1L]],
    provenance_status = row$provenance_status[[1L]],
    source_artifact = row$source_artifact[[1L]],
    source_artifact_md5 = row$source_md5[[1L]],
    units = row$units[[1L]],
    supported_wavelength_range_nm = c(
      optional_number(row$wavelength_min_nm[[1L]]),
      optional_number(row$wavelength_max_nm[[1L]])
    ),
    wavelength_step_nm = optional_number(row$wavelength_step_nm[[1L]]),
    processing_steps = row$processing_steps[[1L]],
    processing_version = row$processing_version[[1L]],
    configuration = configuration
  )
}

attach_provenance <- function(object, row, configuration = list()) {
  attr(object, "luxR.provenance") <- dataset_provenance(row, configuration)
  object
}

write_rda_transaction <- function(objects, destinations) {
  if (!is.list(objects) || !length(objects) || is.null(names(objects)) ||
      any(!nzchar(names(objects))) || length(objects) != length(destinations)) {
    stop("Atomic dataset replacement requires named, aligned objects/paths.",
         call. = FALSE)
  }
  if (anyDuplicated(names(objects)) || anyDuplicated(destinations)) {
    stop("Atomic dataset replacement requires unique object names and paths.",
         call. = FALSE)
  }
  destination_dirs <- unique(dirname(destinations))
  if (length(destination_dirs) != 1L || !dir.exists(destination_dirs)) {
    stop("Atomic dataset replacement requires one existing output directory.",
         call. = FALSE)
  }
  stage_dir <- tempfile("luxR-data-stage-", tmpdir = destination_dirs)
  backup_dir <- tempfile("luxR-data-backup-", tmpdir = destination_dirs)
  dir.create(stage_dir)
  dir.create(backup_dir)
  preserve_backup <- FALSE
  on.exit(unlink(stage_dir, recursive = TRUE), add = TRUE)
  on.exit(if (!preserve_backup) unlink(backup_dir, recursive = TRUE), add = TRUE)
  staged <- file.path(stage_dir, basename(destinations))
  backups <- file.path(backup_dir, basename(destinations))

  for (i in seq_along(objects)) {
    name <- names(objects)[[i]]
    environment <- list2env(setNames(list(objects[[i]]), name),
                            parent = emptyenv())
    save(list = name, file = staged[[i]], envir = environment,
         compress = "xz", version = 2)
    check <- new.env(parent = emptyenv())
    loaded <- load(staged[[i]], envir = check)
    if (!identical(loaded, name) || !identical(check[[name]], objects[[i]])) {
      stop("Staged dataset failed round-trip validation: ", name, call. = FALSE)
    }
  }

  moved <- installed <- logical(length(destinations))
  error <- NULL
  tryCatch({
    for (i in seq_along(destinations)) {
      if (file.exists(destinations[[i]])) {
        moved[[i]] <- file.rename(destinations[[i]], backups[[i]])
        if (!moved[[i]]) stop("Could not back up ", destinations[[i]], ".")
      }
    }
    for (i in seq_along(destinations)) {
      installed[[i]] <- file.rename(staged[[i]], destinations[[i]])
      if (!installed[[i]]) stop("Could not install ", destinations[[i]], ".")
    }
  }, error = function(e) error <<- e)
  if (!is.null(error)) {
    for (i in which(installed)) unlink(destinations[[i]])
    restored <- logical(length(destinations))
    for (i in which(moved)) restored[[i]] <- file.rename(backups[[i]], destinations[[i]])
    if (any(moved & !restored)) {
      preserve_backup <- TRUE
      stop(conditionMessage(error), " Rollback incomplete; backups retained at ",
           backup_dir, ".", call. = FALSE)
    }
    stop(conditionMessage(error), " Original datasets restored.", call. = FALSE)
  }
  invisible(destinations)
}
