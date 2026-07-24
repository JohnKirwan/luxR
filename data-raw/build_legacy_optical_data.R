# Deterministically rebuild legacy canonical optical datasets.
#
# These CSVs are explicitly provenance-limited snapshots extracted from the
# historical luxR objects. They make the package data reviewable and
# reproducible, but are not represented as primary raw measurements/tables.

source(file.path("data-raw", "provenance_helpers.R"))
description <- assert_package_root()
manifest <- read_manifest()
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

naples_row <- manifest_row("Naples", manifest)
Naples <- utils::read.csv(
  naples_row$source_artifact[[1L]], check.names = FALSE,
  colClasses = rep("numeric", 4L)
)
if (!identical(names(Naples), c("wv", "depth_0m", "depth_5m", "depth_10m")) ||
    nrow(Naples) != 103L || any(!is.finite(as.matrix(Naples))) ||
    any(Naples[-1L] < 0) || any(diff(Naples$wv) <= 0) ||
    !isTRUE(all.equal(diff(Naples$wv), rep(5, 102), tolerance = 1e-12))) {
  stop("Naples legacy snapshot violates its schema/grid/value contract.",
       call. = FALSE)
}
Naples <- attach_provenance(
  Naples, naples_row,
  configuration = list(reference_depth_m = c(0, 5, 10),
                       reference_medium = "water")
)

jerlov_row <- manifest_row("jerlov_types", manifest)
jerlov_types <- utils::read.csv(
  jerlov_row$source_artifact[[1L]], check.names = FALSE,
  colClasses = c("character", "numeric", "numeric")
)
expected_types <- c("I", "IA", "IB", "II", "III", "C1", "C2", "C3")
if (!identical(names(jerlov_types), c("type", "lambda", "Kd")) ||
    nrow(jerlov_types) != 120L ||
    !setequal(unique(jerlov_types$type), expected_types) ||
    any(!is.finite(jerlov_types$lambda)) || any(!is.finite(jerlov_types$Kd)) ||
    any(jerlov_types$Kd < 0)) {
  stop("Jerlov legacy snapshot violates its schema/type/value contract.",
       call. = FALSE)
}
for (type in expected_types) {
  wavelength <- jerlov_types$lambda[jerlov_types$type == type]
  if (!identical(wavelength, seq(350, 700, by = 25))) {
    stop("Jerlov type `", type, "` does not have the complete expected grid.",
         call. = FALSE)
  }
}
jerlov_types <- attach_provenance(jerlov_types, jerlov_row)
attr(jerlov_types, "supported_wavelength_range_nm") <- c(350, 700)
attr(jerlov_types, "wavelength_step_nm") <- 25
attr(jerlov_types, "table_checksum_md5") <- jerlov_row$source_md5[[1L]]
attr(jerlov_types, "source_path") <- jerlov_row$source_artifact[[1L]]
attr(jerlov_types, "build_commit") <-
  "23752442d1cd1f96309d98d299d5787d5e36faa9"
attr(jerlov_types, "model_version") <- jerlov_row$processing_version[[1L]]
attr(jerlov_types, "package_version") <- unname(description[1L, "Version"])

solar_row <- manifest_row("solar_spectra", manifest)
solar_long <- utils::read.csv(
  solar_row$source_artifact[[1L]], check.names = FALSE,
  colClasses = c("character", "numeric", "numeric")
)
metadata <- utils::read.csv(file.path("data-raw", "solar_source_metadata.csv"),
                            stringsAsFactors = FALSE)
expected_conditions <- metadata$condition
if (!identical(names(solar_long), c("condition", "wavelength", "irradiance")) ||
    !setequal(unique(solar_long$condition), expected_conditions) ||
    any(!is.finite(solar_long$wavelength)) ||
    any(!is.finite(solar_long$irradiance)) || any(solar_long$irradiance < 0)) {
  stop("Solar legacy snapshot violates its schema/condition/value contract.",
       call. = FALSE)
}
solar_spectra <- setNames(lapply(expected_conditions, function(condition) {
  spectrum <- solar_long[solar_long$condition == condition,
                         c("wavelength", "irradiance"), drop = FALSE]
  rownames(spectrum) <- NULL
  if (!identical(spectrum$wavelength, seq(300, 800, by = 10))) {
    stop("Solar condition `", condition, "` has an invalid wavelength grid.",
         call. = FALSE)
  }
  metadata_row <- metadata[metadata$condition == condition, , drop = FALSE]
  spectrum <- attach_provenance(
    spectrum, solar_row,
    configuration = list(condition = condition,
                         reference_depth_m = metadata_row$reference_depth_m[[1L]],
                         reference_medium = metadata_row$reference_medium[[1L]])
  )
  attr(spectrum, "condition") <- condition
  attr(spectrum, "reference_depth_m") <-
    as.double(metadata_row$reference_depth_m[[1L]])
  attr(spectrum, "reference_medium") <- metadata_row$reference_medium[[1L]]
  if (identical(metadata_row$reference_medium[[1L]], "water")) {
    attr(spectrum, "jerlov_wavelength_policy") <- "constant"
    attr(spectrum, "jerlov_supported_wavelength_range_nm") <- c(350, 700)
    attr(spectrum, "jerlov_input_wavelength_range_nm") <- c(300, 800)
    attr(spectrum, "jerlov_table_checksum_md5") <-
      jerlov_row$source_md5[[1L]]
  }
  spectrum
}), expected_conditions)
solar_spectra <- attach_provenance(
  solar_spectra, solar_row,
  configuration = list(source_conditions = expected_conditions,
                       solar_source_metadata_md5 = file_md5(
                         file.path("data-raw", "solar_source_metadata.csv")
                       ),
                       jerlov_source_md5 = jerlov_row$source_md5[[1L]])
)

objects <- list(Naples = Naples, jerlov_types = jerlov_types,
                solar_spectra = solar_spectra)
destinations <- file.path(output_dir, paste0(names(objects), ".rda"))
write_rda_transaction(objects, destinations)
message("Rebuilt legacy optical datasets: ", paste(destinations, collapse = ", "))
