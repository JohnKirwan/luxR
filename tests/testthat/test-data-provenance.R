test_that("every bundled dataset has complete manifest-backed provenance", {
  datasets <- c(
    "CIE1931", "CIE_scotopic", "Naples", "jerlov_types", "solar_spectra",
    "species_sensitivities", "species_channels", "species_channel_support"
  )
  expected <- c(
    "dataset", "source_id", "citation_key", "source_url", "source_doi",
    "retrieval_date", "license", "provenance_status", "source_artifact",
    "source_artifact_md5", "units", "supported_wavelength_range_nm",
    "wavelength_step_nm", "processing_steps", "processing_version",
    "configuration"
  )
  for (dataset in datasets) {
    object <- get(dataset, envir = asNamespace("luxR"))
    provenance <- attr(object, "luxR.provenance", exact = TRUE)
    expect_named(provenance, expected)
    expect_identical(provenance$dataset, dataset)
    expect_true(nzchar(provenance$source_artifact))
    expect_match(provenance$source_artifact_md5, "^[0-9a-f]{32}$")
    expect_true(nzchar(provenance$processing_version))
  }
})

test_that("bundled spectrum readers preserve source provenance", {
  naples <- from_naples("0m")
  solar <- from_solar("clear_noon")

  expect_identical(naples$meta$provenance$dataset, "Naples")
  expect_match(naples$meta$import$source_checksum_md5, "^[0-9a-f]{32}$")
  expect_identical(solar$meta$provenance$dataset, "solar_spectra")
  expect_match(solar$meta$import$source_checksum_md5, "^[0-9a-f]{32}$")
  expect_identical(solar$meta$import$reader_model_version,
                   solar$meta$provenance$processing_version)
})

test_that("species source labels have a one-to-one citation mapping", {
  provenance <- attr(species_sensitivities, "luxR.provenance", exact = TRUE)
  citation_map <- provenance$configuration$citation_key_map
  status_map <- provenance$configuration$citation_status_map
  labels <- unique(c(species_sensitivities$source, species_channels$source,
                     species_channel_support$source))
  expect_setequal(labels, names(citation_map))
  expect_identical(anyDuplicated(names(citation_map)), 0L)
  expect_identical(anyDuplicated(unname(citation_map)), 0L)
  expect_identical(names(status_map), names(citation_map))
  expect_true(all(nzchar(status_map)))
})

test_that("commit and version capture is single-source across provenance surfaces", {
  commit <- luxR:::.luxr_code_commit()
  version <- luxR:::.luxr_package_version()

  expect_length(commit, 1L)
  expect_length(version, 1L)
  expect_true(is.character(commit))
  expect_identical(version, as.character(utils::packageVersion("luxR")))

  imp <- luxR:::.spectrum_import_context(NA_character_, "csv", "read")
  pol <- luxR:::.polarization_runtime_context("degree_of_polarization")

  expect_identical(imp$code_commit, commit)
  expect_identical(imp$package_version, version)
  expect_identical(pol$code_commit, commit)
  expect_identical(pol$package_version, version)
})
