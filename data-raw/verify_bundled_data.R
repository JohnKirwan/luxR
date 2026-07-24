# Verify bundled-data provenance and deterministic regeneration.
#
# Default verification is offline and rebuilds all local-source datasets.
# Pass --network to also download and rebuild the checksum-pinned CIE datasets.

source(file.path("data-raw", "provenance_helpers.R"))
assert_package_root()
manifest <- read_manifest()
arguments <- commandArgs(trailingOnly = TRUE)
if (any(!arguments %in% "--network")) {
  stop("The only supported argument is --network.", call. = FALSE)
}
use_network <- "--network" %in% arguments

fail <- function(message, dataset = NULL, ...) {
  context <- c(
    list(dataset = if (is.null(dataset)) "manifest" else dataset,
         manifest_md5 = file_md5(file.path("data-raw", "dataset_manifest.csv")),
         random_seed = "not-applicable",
         verifier_model_version = "bundled-data-verifier-v1"),
    list(...)
  )
  rendered <- paste(
    sprintf("%s=%s", names(context), vapply(context, toString, character(1L))),
    collapse = "; "
  )
  stop(message, " [", rendered, "]", call. = FALSE)
}

bundled_paths <- sort(list.files("data", pattern = "[.]rda$", full.names = TRUE))
if (!setequal(manifest$output_path, bundled_paths)) {
  fail("Manifest rows must exactly cover every bundled .rda file.",
       expected = manifest$output_path, observed = bundled_paths)
}
for (path in unique(c(manifest$generator, manifest$source_artifact))) {
  if (!file.exists(path)) fail("Manifest references a missing file.", path = path)
}
for (dataset in manifest$dataset) manifest_row(dataset, manifest)

bib <- paste(readLines(file.path("inst", "REFERENCES.bib"), warn = FALSE),
             collapse = "\n")
citation_keys <- unique(unlist(strsplit(manifest$citation_key, ";", fixed = TRUE)))
missing_citations <- citation_keys[!vapply(
  citation_keys,
  function(key) grepl(paste0("@[[:alnum:]]+\\{", key, "[,]"), bib),
  logical(1L)
)]
if (length(missing_citations)) {
  fail("Manifest citation keys are absent from inst/REFERENCES.bib.",
       missing_citations = missing_citations)
}

required_provenance <- c(
  "dataset", "source_id", "citation_key", "source_url", "source_doi",
  "retrieval_date", "license", "provenance_status", "source_artifact",
  "source_artifact_md5", "units", "supported_wavelength_range_nm",
  "wavelength_step_nm", "processing_steps", "processing_version",
  "configuration"
)
load_dataset <- function(path, expected_name) {
  environment <- new.env(parent = emptyenv())
  loaded <- load(path, envir = environment)
  if (!identical(loaded, expected_name)) {
    fail("Bundled file must contain exactly its named dataset.", expected_name,
         path = path, loaded = loaded)
  }
  environment[[expected_name]]
}
for (dataset in manifest$dataset) {
  row <- manifest[manifest$dataset == dataset, , drop = FALSE]
  object <- load_dataset(row$output_path[[1L]], dataset)
  provenance <- attr(object, "luxR.provenance", exact = TRUE)
  if (!is.list(provenance) || !identical(names(provenance), required_provenance)) {
    fail("Bundled dataset has missing or unexpected provenance fields.", dataset,
         path = row$output_path[[1L]], observed = names(provenance))
  }
  expected <- dataset_provenance(row)
  stable_fields <- setdiff(required_provenance, "configuration")
  if (!identical(provenance[stable_fields], expected[stable_fields])) {
    fail("Bundled provenance does not match the manifest.", dataset,
         path = row$output_path[[1L]])
  }
}

temporary_output <- tempfile("luxR-data-verify-")
dir.create(temporary_output)
on.exit(unlink(temporary_output, recursive = TRUE), add = TRUE)
builders <- c(
  "data-raw/build_legacy_optical_data.R",
  "data-raw/build_species_data.R"
)
if (use_network) builders <- c(builders, "data-raw/build_cie_efficiency_data.R")
for (builder in builders) {
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", builder, paste0("--output-dir=", temporary_output))
  )
  if (!identical(status, 0L)) {
    fail("Dataset builder failed during isolated verification.",
         builder = builder, exit_status = status)
  }
}

rebuilt <- sub("[.]rda$", "", basename(list.files(
  temporary_output, pattern = "[.]rda$"
)))
expected_rebuilt <- manifest$dataset[
  use_network | !manifest$dataset %in% c("CIE1931", "CIE_scotopic")
]
if (!setequal(rebuilt, expected_rebuilt)) {
  fail("Isolated builders produced unexpected dataset coverage.",
       expected = expected_rebuilt, observed = rebuilt)
}
for (dataset in rebuilt) {
  current <- load_dataset(file.path("data", paste0(dataset, ".rda")), dataset)
  generated <- load_dataset(
    file.path(temporary_output, paste0(dataset, ".rda")), dataset
  )
  if (!identical(current, generated)) {
    fail("Bundled dataset differs from its deterministic rebuild.", dataset)
  }
}

cie_table <- utils::read.csv(file.path("data-raw", "cie_sources.csv"),
                             stringsAsFactors = FALSE)
for (dataset in c("CIE1931", "CIE_scotopic")) {
  object <- load_dataset(file.path("data", paste0(dataset, ".rda")), dataset)
  row <- cie_table[cie_table$dataset == dataset, , drop = FALSE]
  if (nrow(row) != 1L ||
      !identical(attr(object, "source_md5", exact = TRUE), row$md5[[1L]]) ||
      !identical(attr(object, "metadata_md5", exact = TRUE),
                 row$metadata_md5[[1L]])) {
    fail("CIE checksum attributes do not match the pinned source table.", dataset)
  }
}

message("Verified provenance for ", nrow(manifest), " bundled datasets",
        if (use_network) " including network rebuilds." else
          " (CIE sources verified from pinned metadata; use --network to rebuild).")
