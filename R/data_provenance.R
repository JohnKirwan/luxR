# Internal bundled-data provenance helpers.

.required_dataset_provenance <- c(
  "dataset", "source_id", "citation_key", "source_url", "source_doi",
  "retrieval_date", "license", "provenance_status", "source_artifact",
  "source_artifact_md5", "units", "supported_wavelength_range_nm",
  "wavelength_step_nm", "processing_steps", "processing_version",
  "configuration"
)

.bundled_dataset_provenance <- function(object, dataset) {
  provenance <- attr(object, "luxR.provenance", exact = TRUE)
  if (!is.list(provenance) ||
      !identical(names(provenance), .required_dataset_provenance) ||
      !identical(provenance$dataset, dataset) ||
      !is.character(provenance$source_artifact_md5) ||
      length(provenance$source_artifact_md5) != 1L ||
      !grepl("^[0-9a-f]{32}$", provenance$source_artifact_md5)) {
    stop("Bundled dataset `", dataset,
         "` has invalid or incomplete provenance metadata.", call. = FALSE)
  }
  provenance
}

.luxr_code_commit <- function() {
  description <- tryCatch(utils::packageDescription("luxR"),
                          error = function(e) NULL)
  if (!is.null(description) && !is.null(description[["GithubSHA1"]]) &&
      nzchar(description[["GithubSHA1"]])) {
    return(description[["GithubSHA1"]])
  }
  commit <- Sys.getenv("GITHUB_SHA", unset = NA_character_)
  if (!is.na(commit) && nzchar(commit)) commit else NA_character_
}

.luxr_package_version <- function() {
  version <- tryCatch(as.character(utils::packageVersion("luxR")),
                      error = function(e) NA_character_)
  if (length(version) == 1L && nzchar(version)) version else NA_character_
}

.bundled_source_import <- function(provenance) {
  if (!is.list(provenance) ||
      any(!.required_dataset_provenance %in% names(provenance))) {
    stop("Bundled source provenance is incomplete.", call. = FALSE)
  }
  list(
    calibration_state = "bundled/reference source",
    calibration = provenance$provenance_status,
    source_path = provenance$source_artifact,
    source_checksum_md5 = provenance$source_artifact_md5,
    reader_model_version = provenance$processing_version,
    package_version = as.character(utils::packageVersion("luxR")),
    code_commit = .luxr_code_commit(),
    preprocessing = provenance$processing_steps
  )
}
