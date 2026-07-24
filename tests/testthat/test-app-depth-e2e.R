test_that("Depth Propagation handles an above-surface source end to end", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) {
    app_dir <- testthat::test_path("..", "..", "inst", "app")
  }
  skip_if(!dir.exists(app_dir), "app dir not found")

  shiny::testServer(app_dir, {
    session$setInputs(
      source_type = "solar",
      solar_cond = "clear_noon",
      wtype = "II",
      dp_wavelength_policy = "trim",
      depths = c(0, 10),
      depth_step = 10,
      dp_unit = "W_nm"
    )

    source <- dp_source()
    reference <- solar_irradiance("clear_noon")
    keep <- reference$wavelength >= 350 & reference$wavelength <= 700
    lambda <- reference$wavelength[keep]
    reference_irradiance <- reference$irradiance[keep]
    tau <- surface_transmittance(angle = 30, n = 1.333, source = "direct")
    Kd <- as.numeric(jerlov_Kd("II", lambda = lambda))
    expected <- list(
      "0" = reference_irradiance * tau,
      "10" = reference_irradiance * tau * exp(-as.numeric(Kd) * 10)
    )

    expect_identical(source$source_condition, "clear_noon")
    expect_identical(source$reference_medium, "air")
    expect_identical(source$reference_depth_m, 0)

    spectra <- dp_spectra()
    expect_named(spectra, c("0", "10"))
    expect_equal(spectra[["0"]], expected[["0"]])
    expect_equal(spectra[["10"]], expected[["10"]])
    expect_true(all(spectra[["10"]] <= spectra[["0"]]))
    expect_true(any(spectra[["10"]] < spectra[["0"]]))

    metadata <- dp_metadata()
    expect_true(all(metadata$source_condition == "clear_noon"))
    expect_true(all(metadata$source_reference_medium == "air"))
    expect_true(all(metadata$source_reference_depth_m == 0))
    expect_true(all(metadata$surface_transmission_applied))
    expect_equal(metadata$surface_multiplier, rep(tau, 2))
    expect_true(all(metadata$surface_source == "direct"))
    expect_true(all(metadata$surface_incidence_angle_deg == 30))
    expect_true(all(metadata$surface_refractive_index == 1.333))
    expect_true(all(metadata$jerlov_type == "II"))
    expect_true(all(metadata$jerlov_wavelength_policy == "trim"))
    expect_true(all(metadata$jerlov_calculated_min_nm == 350))
    expect_true(all(metadata$jerlov_calculated_max_nm == 700))
    expect_identical(metadata$target_depth_m, c(0, 10))

    plot_context <- luxR:::.format_depth_output_metadata(metadata)
    expect_match(plot_context, "Source: clear_noon \\(air; reference 0 m\\)")
    expect_match(plot_context, "flat-interface Fresnel direct at 30 deg")
    expect_match(plot_context, "Propagation: spectral Beer-Lambert")
    expect_match(plot_context, "Jerlov: II")
    expect_match(plot_context, "Target depths: 0-10 m by 10 m")
    expect_no_error(output$dp_plot)

    binwidth <- mean(diff(lambda))
    expected_lux <- vapply(expected, function(E) {
      irradiance2lux(E, lambda, total = TRUE, binwidth = binwidth)
    }, numeric(1))
    expected_photons <- vapply(expected, function(E) {
      sum(W2photon(E, lambda) * binwidth)
    }, numeric(1))

    summary <- dp_summary_df()
    expect_identical(summary[["Depth (m)"]], c(0, 10))
    expect_equal(summary[["Lux"]], unname(expected_lux))
    expect_equal(summary[["Photons/s/m2"]], unname(expected_photons))
    expect_no_error(output$dp_summary)

    download <- dp_download_df()
    expect_identical(download[["Target depth (m)"]], c(0, 10))
    expect_equal(download[["Lux"]], unname(expected_lux))
    expect_equal(download[["Photons/s/m2"]], unname(expected_photons))
    expect_true(all(download[["Surface transmission applied"]]))
    expect_true(all(download[["Propagation model version"]] ==
                    "beer-lambert-kd-v1"))
    expect_equal(download[["Surface multiplier"]], rep(tau, 2))

    path <- tempfile(fileext = ".csv")
    on.exit(unlink(path), add = TRUE)
    utils::write.csv(download, path, row.names = FALSE)
    roundtrip <- utils::read.csv(path, check.names = FALSE)

    expect_identical(names(roundtrip), names(download))
    expect_identical(roundtrip[["Source condition"]], c("clear_noon", "clear_noon"))
    expect_identical(roundtrip[["Source reference medium"]], c("air", "air"))
    expect_identical(roundtrip[["Target depth (m)"]], c(0L, 10L))
    expect_equal(roundtrip[["Surface multiplier"]], rep(tau, 2))
    expect_equal(roundtrip[["Lux"]], unname(expected_lux))
    expect_equal(roundtrip[["Photons/s/m2"]], unname(expected_photons))
  })
})

test_that("Depth Propagation handles a surface-referenced source end to end", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) {
    app_dir <- testthat::test_path("..", "..", "inst", "app")
  }
  skip_if(!dir.exists(app_dir), "app dir not found")

  shiny::testServer(app_dir, {
    session$setInputs(
      source_type = "upload",
      wtype = "IA",
      dp_wavelength_policy = "trim",
      depths = c(0, 10),
      depth_step = 10,
      dp_unit = "W_nm"
    )
    session$setInputs(dp_example = 1)

    source <- dp_source()
    reference <- convert_unit(from_naples("0m"), "W/m2/nm")
    keep <- reference$lambda >= 350 & reference$lambda <= 700
    lambda <- reference$lambda[keep]
    reference_E <- reference$E[keep]
    Kd <- as.numeric(jerlov_Kd("IA", lambda = lambda))
    expected <- list(
      "0" = reference_E,
      "10" = reference_E * exp(-as.numeric(Kd) * 10)
    )

    expect_identical(source$source_condition, "Naples 0 m example")
    expect_identical(source$reference_medium, "water")
    expect_identical(source$reference_depth_m, 0)

    spectra <- dp_spectra()
    expect_named(spectra, c("0", "10"))
    expect_equal(spectra[["0"]], expected[["0"]])
    expect_equal(spectra[["10"]], expected[["10"]])
    expect_true(all(spectra[["10"]] <= spectra[["0"]]))
    expect_true(any(spectra[["10"]] < spectra[["0"]]))

    metadata <- dp_metadata()
    expect_true(all(metadata$source_condition == "Naples 0 m example"))
    expect_true(all(metadata$source_reference_medium == "water"))
    expect_true(all(metadata$source_reference_depth_m == 0))
    expect_false(any(metadata$surface_transmission_applied))
    expect_equal(metadata$surface_multiplier, rep(1, 2))
    expect_true(all(metadata$jerlov_type == "IA"))
    expect_true(all(metadata$jerlov_wavelength_policy == "trim"))
    expect_true(all(metadata$jerlov_calculated_max_nm <= 700))
    expect_identical(metadata$target_depth_m, c(0, 10))

    plot_context <- luxR:::.format_depth_output_metadata(metadata)
    expect_match(
      plot_context,
      "Source: Naples 0 m example \\(water; reference 0 m\\)"
    )
    expect_match(
      plot_context,
      "not applied \\(source already in water; multiplier=1\\)"
    )
    expect_match(plot_context, "Jerlov: IA")
    expect_match(plot_context, "Target depths: 0-10 m by 10 m")
    expect_no_error(output$dp_plot)

    binwidth <- mean(diff(lambda))
    expected_lux <- vapply(expected, function(E) {
      irradiance2lux(E, lambda, total = TRUE, binwidth = binwidth)
    }, numeric(1))
    expected_photons <- vapply(expected, function(E) {
      sum(W2photon(E, lambda) * binwidth)
    }, numeric(1))

    summary <- dp_summary_df()
    expect_identical(summary[["Depth (m)"]], c(0, 10))
    expect_equal(summary[["Lux"]], unname(expected_lux))
    expect_equal(summary[["Photons/s/m2"]], unname(expected_photons))
    expect_no_error(output$dp_summary)

    download <- dp_download_df()
    expect_identical(download[["Target depth (m)"]], c(0, 10))
    expect_equal(download[["Lux"]], unname(expected_lux))
    expect_equal(download[["Photons/s/m2"]], unname(expected_photons))
    expect_false(any(download[["Surface transmission applied"]]))
    expect_equal(download[["Surface multiplier"]], rep(1, 2))

    path <- tempfile(fileext = ".csv")
    on.exit(unlink(path), add = TRUE)
    utils::write.csv(download, path, row.names = FALSE)
    roundtrip <- utils::read.csv(path, check.names = FALSE)

    expect_identical(names(roundtrip), names(download))
    expect_identical(
      roundtrip[["Source condition"]],
      c("Naples 0 m example", "Naples 0 m example")
    )
    expect_identical(
      roundtrip[["Source reference medium"]],
      c("water", "water")
    )
    expect_identical(roundtrip[["Target depth (m)"]], c(0L, 10L))
    expect_equal(roundtrip[["Surface multiplier"]], rep(1, 2))
    expect_equal(roundtrip[["Lux"]], unname(expected_lux))
    expect_equal(roundtrip[["Photons/s/m2"]], unname(expected_photons))
  })
})

test_that("Depth Propagation handles an already-underwater source end to end", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) {
    app_dir <- testthat::test_path("..", "..", "inst", "app")
  }
  skip_if(!dir.exists(app_dir), "app dir not found")

  shiny::testServer(app_dir, {
    session$setInputs(
      source_type = "solar",
      solar_cond = "underwater_10m",
      wtype = "II",
      dp_wavelength_policy = "trim",
      depths = c(10, 20),
      depth_step = 10,
      dp_unit = "W_nm"
    )

    source <- dp_source()
    reference <- solar_irradiance("underwater_10m")
    keep <- reference$wavelength >= 350 & reference$wavelength <= 700
    lambda <- reference$wavelength[keep]
    reference_irradiance <- reference$irradiance[keep]
    Kd <- as.numeric(jerlov_Kd("II", lambda = lambda))
    expected <- list(
      "10" = reference_irradiance,
      "20" = reference_irradiance * exp(-as.numeric(Kd) * 10)
    )

    expect_identical(source$source_condition, "underwater_10m")
    expect_identical(source$reference_medium, "water")
    expect_identical(source$reference_depth_m, 10)

    spectra <- dp_spectra()
    expect_named(spectra, c("10", "20"))
    expect_equal(spectra[["10"]], expected[["10"]])
    expect_equal(spectra[["20"]], expected[["20"]])
    expect_true(all(spectra[["20"]] <= spectra[["10"]]))
    expect_true(any(spectra[["20"]] < spectra[["10"]]))

    metadata <- dp_metadata()
    expect_true(all(metadata$source_condition == "underwater_10m"))
    expect_true(all(metadata$source_reference_medium == "water"))
    expect_true(all(metadata$source_reference_depth_m == 10))
    expect_false(any(metadata$surface_transmission_applied))
    expect_equal(metadata$surface_multiplier, rep(1, 2))
    expect_true(all(metadata$jerlov_type == "II"))
    expect_identical(metadata$target_depth_m, c(10, 20))

    plot_context <- luxR:::.format_depth_output_metadata(metadata)
    expect_match(
      plot_context,
      "Source: underwater_10m \\(water; reference 10 m\\)"
    )
    expect_match(
      plot_context,
      "not applied \\(source already in water; multiplier=1\\)"
    )
    expect_match(plot_context, "Jerlov: II")
    expect_match(plot_context, "Target depths: 10-20 m by 10 m")
    expect_no_error(output$dp_plot)

    binwidth <- mean(diff(lambda))
    expected_lux <- vapply(expected, function(E) {
      irradiance2lux(E, lambda, total = TRUE, binwidth = binwidth)
    }, numeric(1))
    expected_photons <- vapply(expected, function(E) {
      sum(W2photon(E, lambda) * binwidth)
    }, numeric(1))

    summary <- dp_summary_df()
    expect_identical(summary[["Depth (m)"]], c(10, 20))
    expect_equal(summary[["Lux"]], unname(expected_lux))
    expect_equal(summary[["Photons/s/m2"]], unname(expected_photons))
    expect_no_error(output$dp_summary)

    download <- dp_download_df()
    expect_identical(download[["Target depth (m)"]], c(10, 20))
    expect_equal(download[["Lux"]], unname(expected_lux))
    expect_equal(download[["Photons/s/m2"]], unname(expected_photons))
    expect_false(any(download[["Surface transmission applied"]]))
    expect_equal(download[["Surface multiplier"]], rep(1, 2))

    path <- tempfile(fileext = ".csv")
    on.exit(unlink(path), add = TRUE)
    utils::write.csv(download, path, row.names = FALSE)
    roundtrip <- utils::read.csv(path, check.names = FALSE)

    expect_identical(names(roundtrip), names(download))
    expect_identical(
      roundtrip[["Source condition"]],
      c("underwater_10m", "underwater_10m")
    )
    expect_identical(
      roundtrip[["Source reference medium"]],
      c("water", "water")
    )
    expect_identical(roundtrip[["Source reference depth (m)"]], c(10L, 10L))
    expect_identical(roundtrip[["Target depth (m)"]], c(10L, 20L))
    expect_false(any(roundtrip[["Surface transmission applied"]]))
    expect_equal(roundtrip[["Surface multiplier"]], rep(1, 2))
    expect_equal(roundtrip[["Lux"]], unname(expected_lux))
    expect_equal(roundtrip[["Photons/s/m2"]], unname(expected_photons))
  })
})
