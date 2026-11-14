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
    .luxr_abort(paste0("Bundled dataset `", dataset,
                       "` has invalid or incomplete provenance metadata."), "data")
  }
  provenance
}

# The commit luxR was installed from, as recorded in its installed DESCRIPTION
# by remotes/pak (GithubSHA1, RemoteSha) or r-universe (RemoteSha). Only a full
# 40-hex SHA is accepted: for a CRAN install RemoteSha holds the version string.
# Ambient environment variables such as GITHUB_SHA are ignored because they
# describe the caller's repository, not luxR. NA means the commit is unknown.
.luxr_code_commit <- function(description = utils::packageDescription("luxR")) {
  if (!is.list(description)) return(NA_character_)
  for (field in c("RemoteSha", "GithubSHA1")) {
    sha <- description[[field]]
    if (is.character(sha) && length(sha) == 1L &&
        grepl("^[0-9a-f]{40}$", sha)) {
      return(sha)
    }
  }
  NA_character_
}

.luxr_package_version <- function() {
  version <- tryCatch(as.character(utils::packageVersion("luxR")),
                      error = function(e) NA_character_)
  if (length(version) == 1L && nzchar(version)) version else NA_character_
}

.bundled_source_import <- function(provenance) {
  if (!is.list(provenance) ||
      any(!.required_dataset_provenance %in% names(provenance))) {
    .luxr_abort("Bundled source provenance is incomplete.", "data")
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
