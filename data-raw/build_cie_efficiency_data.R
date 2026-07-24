# Rebuild the bundled CIE photopic and scotopic luminous-efficiency tables.
#
# Run from the package root with:
#   Rscript --vanilla data-raw/build_cie_efficiency_data.R
#
# Sources are the CIE open datasets accompanying CIE 018:2019. Both each CSV
# and its companion metadata file are checksum-pinned so an upstream change
# cannot silently alter package data or its provenance.

source(file.path("data-raw", "provenance_helpers.R"))
assert_package_root()
dataset_manifest <- read_manifest()
arguments <- commandArgs(trailingOnly = TRUE)
output_argument <- grep("^--output-dir=", arguments, value = TRUE)
output_dir <- if (length(output_argument)) {
  sub("^--output-dir=", "", output_argument[[1L]])
} else {
  "data"
}
if (length(output_argument) > 1L || !nzchar(output_dir)) {
  stop("Use at most one non-empty --output-dir=PATH argument.", call. = FALSE)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

source_table <- utils::read.csv(
  file.path("data-raw", "cie_sources.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = character()
)
source_columns <- c(
  "dataset", "url", "md5", "metadata_url", "metadata_md5", "doi",
  "first_wavelength", "last_wavelength", "retrieval_date", "license",
  "standard"
)
if (!identical(names(source_table), source_columns) || nrow(source_table) != 2L ||
    anyNA(source_table) || any(!nzchar(trimws(as.matrix(source_table)))) ||
    !setequal(source_table$dataset, c("CIE1931", "CIE_scotopic")) ||
    anyDuplicated(source_table$dataset)) {
  stop("cie_sources.csv has an invalid schema or dataset coverage.", call. = FALSE)
}
if (length(unique(source_table$retrieval_date)) != 1L ||
    length(unique(source_table$license)) != 1L ||
    length(unique(source_table$standard)) != 1L) {
  stop("CIE source rows must use one retrieval date, license, and standard.",
       call. = FALSE)
}
if (!is.numeric(source_table$first_wavelength) ||
    !is.numeric(source_table$last_wavelength) ||
    any(!is.finite(source_table$first_wavelength)) ||
    any(!is.finite(source_table$last_wavelength)) ||
    any(source_table$first_wavelength != floor(source_table$first_wavelength)) ||
    any(source_table$last_wavelength != floor(source_table$last_wavelength)) ||
    any(source_table$first_wavelength >= source_table$last_wavelength)) {
  stop("CIE wavelength bounds must be finite ordered integers.", call. = FALSE)
}
sources <- setNames(lapply(seq_len(nrow(source_table)), function(i) {
  row <- source_table[i, , drop = FALSE]
  list(
    url = row$url[[1L]], md5 = row$md5[[1L]],
    metadata_url = row$metadata_url[[1L]],
    metadata_md5 = row$metadata_md5[[1L]], doi = row$doi[[1L]],
    first_wavelength = as.integer(row$first_wavelength[[1L]]),
    last_wavelength = as.integer(row$last_wavelength[[1L]])
  )
}), source_table$dataset)
retrieval_date <- unique(source_table$retrieval_date)
source_license <- unique(source_table$license)
source_standard <- unique(source_table$standard)

commit_id <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
  error = function(e) NA_character_
)
if (length(commit_id) != 1L || !nzchar(commit_id)) {
  commit_id <- NA_character_
}

fail_with_context <- function(message, dataset, source, ...) {
  context <- c(
    list(
      dataset = dataset,
      dataset_path = file.path("data", paste0(dataset, ".rda")),
      url = source$url,
      expected_md5 = source$md5,
      metadata_url = source$metadata_url,
      expected_metadata_md5 = source$metadata_md5,
      retrieval_date = retrieval_date,
      source_standard = source_standard,
      code_commit = commit_id,
      random_seed = "not-applicable"
    ),
    list(...)
  )
  rendered <- paste(
    sprintf("%s=%s", names(context), vapply(context, toString, character(1L))),
    collapse = "; "
  )
  stop(message, " [", rendered, "]", call. = FALSE)
}

fail_build <- function(message) {
  context <- list(
    datasets = names(sources),
    dataset_paths = file.path("data", paste0(names(sources), ".rda")),
    expected_md5 = vapply(sources, `[[`, character(1L), "md5"),
    source_standard = source_standard,
    code_commit = commit_id,
    random_seed = "not-applicable"
  )
  rendered <- paste(
    sprintf("%s=%s", names(context), vapply(context, toString, character(1L))),
    collapse = "; "
  )
  stop(message, " [", rendered, "]", call. = FALSE)
}

download_pinned_file <- function(dataset, source, url, expected_md5,
                                 destination, label) {
  tryCatch(
    utils::download.file(
      url,
      destination,
      mode = "wb",
      quiet = TRUE,
      method = "libcurl"
    ),
    error = function(e) {
      fail_with_context(
        paste0("Failed to download CIE ", label, ": ", conditionMessage(e)),
        dataset,
        source
      )
    }
  )

  observed_md5 <- unname(tools::md5sum(destination))
  if (!identical(observed_md5, expected_md5)) {
    fail_with_context(
      paste0("Downloaded CIE ", label, " checksum does not match."),
      dataset,
      source,
      observed_md5 = observed_md5
    )
  }
  observed_md5
}

download_and_validate <- function(dataset, source, download_dir) {
  csv_path <- file.path(download_dir, paste0(dataset, ".csv"))
  metadata_path <- file.path(download_dir, paste0(dataset, ".json"))

  observed_md5 <- download_pinned_file(
    dataset, source, source$url, source$md5, csv_path, "CSV"
  )
  observed_metadata_md5 <- download_pinned_file(
    dataset, source, source$metadata_url, source$metadata_md5,
    metadata_path, "metadata"
  )

  metadata <- paste(readLines(metadata_path, warn = FALSE), collapse = "\n")
  required_metadata <- c(source$doi, source$md5, source_license)
  if (!all(vapply(required_metadata, grepl, logical(1L),
                  x = metadata, fixed = TRUE))) {
    fail_with_context(
      "CIE metadata does not contain the expected DOI, CSV checksum, and license.",
      dataset,
      source,
      observed_md5 = observed_md5,
      observed_metadata_md5 = observed_metadata_md5
    )
  }

  values <- tryCatch(
    utils::read.csv(
      csv_path,
      header = FALSE,
      col.names = c("lambda", "W"),
      colClasses = c("integer", "numeric")
    ),
    error = function(e) {
      fail_with_context(
        paste0("Failed to parse CIE dataset: ", conditionMessage(e)),
        dataset,
        source,
        observed_md5 = observed_md5
      )
    }
  )

  expected_wavelengths <- seq.int(
    source$first_wavelength,
    source$last_wavelength
  )
  if (!identical(names(values), c("lambda", "W")) ||
      !identical(values$lambda, expected_wavelengths)) {
    fail_with_context(
      "CIE data do not have the expected schema and complete 1 nm grid.",
      dataset,
      source,
      observed_md5 = observed_md5,
      observed_columns = names(values),
      observed_rows = nrow(values),
      observed_range = range(values$lambda)
    )
  }
  if (any(!is.finite(values$W)) || any(values$W < 0) || any(values$W > 1) ||
      !isTRUE(all.equal(max(values$W), 1, tolerance = 0))) {
    fail_with_context(
      "CIE efficiencies must be finite, within [0, 1], and peak at one.",
      dataset,
      source,
      observed_md5 = observed_md5,
      observed_range = range(values$W)
    )
  }

  attr(values, "source_url") <- source$url
  attr(values, "source_doi") <- source$doi
  attr(values, "source_md5") <- source$md5
  attr(values, "metadata_url") <- source$metadata_url
  attr(values, "metadata_md5") <- source$metadata_md5
  attr(values, "retrieval_date") <- retrieval_date
  attr(values, "source_standard") <- source_standard
  attr(values, "license") <- source_license
  values <- attach_provenance(
    values, manifest_row(dataset, dataset_manifest),
    configuration = list(
      upstream_csv_md5 = observed_md5,
      upstream_metadata_md5 = observed_metadata_md5,
      source_standard = source_standard
    )
  )
  values
}

download_dir <- tempfile("luxR-cie-download-")
dir.create(download_dir)
on.exit(unlink(download_dir, recursive = TRUE), add = TRUE)

datasets <- Map(
  function(dataset, source) {
    download_and_validate(dataset, source, download_dir)
  },
  names(sources),
  sources
)
names(datasets) <- names(sources)

destinations <- file.path(output_dir, paste0(names(datasets), ".rda"))
write_rda_transaction(datasets, destinations)
message("Rebuilt CIE datasets: ", paste(destinations, collapse = ", "))
