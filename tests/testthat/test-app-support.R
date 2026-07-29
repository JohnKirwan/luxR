jerlov_test_metadata <- function(type = "IA") {
  luxR:::.prepare_jerlov_domain(
    c(300, 350, 700, 800), rep(1, 4), wavelength_policy = "trim",
    type = type, operation = "test metadata"
  )$metadata
}

test_that(".depth_summary_df returns one row per depth with lux and photon columns", {
  lambda  <- seq(400, 700, by = 10)
  spectra <- list(
    "0"  = rep(1.0, length(lambda)),
    "10" = rep(0.5, length(lambda))
  )
  df <- luxR:::.depth_summary_df(spectra, lambda)

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2L)
  expect_equal(df[["Depth (m)"]], c(0, 10))
  expect_true(all(c("Depth (m)", "Lux", "Photons/s/m2") %in% names(df)))
  expect_gt(df[["Lux"]][1], df[["Lux"]][2])
  # photon column is raw numeric (no display formatting leaked in) and ordered
  expect_true(is.numeric(df[["Photons/s/m2"]]))
  expect_gt(df[["Photons/s/m2"]][1], df[["Photons/s/m2"]][2])
})

test_that("depth output metadata records an applied air-water surface model", {
  targets <- c(0, 10, 20)
  metadata <- luxR:::.depth_output_metadata(
    source_condition = "clear_noon",
    reference_depth_m = 0,
    reference_medium = "air",
    water_type = "II",
    target_depth_m = targets,
    jerlov_metadata = jerlov_test_metadata("II"),
    surface_source = "direct",
    surface_angle = 30,
    refractive_index = 1.333
  )

  expect_equal(nrow(metadata), length(targets))
  expect_identical(metadata$target_depth_m, targets)
  expect_true(all(metadata$surface_transmission_applied))
  expect_equal(
    metadata$surface_multiplier,
    rep(surface_transmittance(angle = 30, n = 1.333), length(targets))
  )
  expect_true(all(metadata$surface_model == "flat-interface Fresnel"))
  expect_true(all(metadata$jerlov_type == "II"))
  expect_true(all(metadata$propagation_model ==
                  "spectral Beer-Lambert diffuse attenuation"))
  expect_true(all(metadata$propagation_model_version ==
                  "beer-lambert-kd-v1"))
  expect_match(metadata$propagation_assumptions[[1L]],
               "wavelength bins propagate independently")

  label <- luxR:::.format_depth_output_metadata(metadata)
  expect_match(label, "clear_noon")
  expect_match(label, "air; reference 0 m")
  expect_match(label, "flat-interface Fresnel direct at 30 deg")
  expect_match(label, "Propagation: spectral Beer-Lambert diffuse attenuation")
  expect_match(label, "Jerlov: II")
  expect_match(label, "Target depths: 0-20 m by 10 m")
})

test_that("depth output metadata marks surface transmission as not applied in water", {
  metadata <- luxR:::.depth_output_metadata(
    source_condition = "underwater_10m",
    reference_depth_m = 10,
    reference_medium = "water",
    water_type = "IA",
    target_depth_m = c(10, 20),
    jerlov_metadata = jerlov_test_metadata("IA")
  )

  expect_false(any(metadata$surface_transmission_applied))
  expect_equal(metadata$surface_multiplier, c(1, 1))
  expect_match(
    luxR:::.format_depth_output_metadata(metadata),
    "not applied \\(source already in water; multiplier=1\\)"
  )
})

test_that("depth download metadata stays aligned with numeric results", {
  summary <- data.frame(
    `Depth (m)` = c(10, 20),
    Lux = c(12.3456789, 1.23456789),
    `Photons/s/m2` = c(1.23e18, 1.23e17),
    check.names = FALSE
  )
  metadata <- luxR:::.depth_output_metadata(
    source_condition = "underwater_10m",
    reference_depth_m = 10,
    reference_medium = "water",
    water_type = "IA",
    target_depth_m = c(10, 20),
    jerlov_metadata = jerlov_test_metadata("IA")
  )
  download <- luxR:::.depth_download_df(summary, metadata)

  expect_identical(download[["Target depth (m)"]], c(10, 20))
  expect_identical(download[["Lux"]], summary[["Lux"]])
  expect_identical(download[["Photons/s/m2"]], summary[["Photons/s/m2"]])
  expect_true(all(c(
    "Source condition", "Source reference medium",
    "Source reference depth (m)", "Propagation model",
    "Propagation model version", "Propagation equation",
    "Propagation assumptions", "Surface model",
    "Surface transmission applied", "Surface source",
    "Surface incidence angle (deg)", "Surface refractive index",
    "Surface multiplier", "Jerlov type", "Target depth (m)"
  ) %in% names(download)))

  expect_error(
    luxR:::.depth_download_df(summary, metadata[2:1, ]),
    "misaligned"
  )
})

test_that("depth output metadata fails on invalid source context", {
  expect_error(
    luxR:::.depth_output_metadata(
      source_condition = "underwater_10m",
      reference_depth_m = NA_real_,
      reference_medium = "water",
      water_type = "IA",
      target_depth_m = 10,
      jerlov_metadata = jerlov_test_metadata("IA")
    ),
    "reference_depth_m.*finite",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    luxR:::.format_depth_output_metadata(data.frame(target_depth_m = 10)),
    "missing required fields"
  )
})

test_that("Depth Propagation accepts an uploaded Ocean Optics spectrum", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  # use source-tree app dir if not installed
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")

  fixture <- normalizePath(
    testthat::test_path("fixtures", "ocean_optics_sample.txt"),
    mustWork = FALSE
  )
  skip_if(!file.exists(fixture), "fixture missing")

  shiny::testServer(app_dir, {
    session$setInputs(
      source_type = "upload",
      upload_file = list(name = "s.txt", datapath = fixture),
      upload_unit = "W/m2/nm",
      upload_calibration = "test certificate",
      upload_reference_depth = 3,
      wtype = "IA", dp_wavelength_policy = "trim",
      depths = c(5, 20), depth_step = 5, dp_unit = "W_nm"
    )
    src <- dp_source()
    expect_true(is.numeric(src$lambda) && length(src$lambda) > 1)
    expect_equal(length(src$lambda), length(src$irradiance))
    expect_identical(src$reference_depth_m, 3)
    expect_identical(src$reference_medium, "water")
    df <- dp_summary_df()
    expect_s3_class(df, "data.frame")
    expect_gte(nrow(df), 1L)
    metadata <- dp_metadata()
    expect_true(all(metadata$source_condition == "uploaded file 's.txt'"))
    expect_true(all(metadata$source_calibration == "test certificate"))
    expect_true(all(metadata$source_path == "s.txt"))
    expect_match(metadata$source_checksum_md5[[1L]], "^[0-9a-f]{32}$")
    expect_false(any(metadata$surface_transmission_applied))
    expect_identical(
      dp_download_df()[["Target depth (m)"]],
      df[["Depth (m)"]]
    )
  })
})

test_that("Depth Propagation uses bundled solar reference depth", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")

  shiny::testServer(app_dir, {
    session$setInputs(
      source_type = "solar", solar_cond = "underwater_10m",
      wtype = "II", dp_wavelength_policy = "trim",
      depths = c(10, 20), depth_step = 10,
      dp_unit = "W_nm"
    )
    src <- dp_source()
    expect_identical(src$reference_depth_m, 10)
    expect_identical(src$reference_medium, "water")

    metadata <- dp_metadata()
    expect_true(all(metadata$source_condition == "underwater_10m"))
    expect_true(all(metadata$source_reference_depth_m == 10))
    expect_false(any(metadata$surface_transmission_applied))
    expect_true(all(metadata$jerlov_type == "II"))

    spectra <- dp_spectra()
    domain <- dp_domain()
    expect_equal(spectra[["10"]], domain$values)
    Kd <- jerlov_Kd("II", lambda = domain$lambda)
    expected_20m <- propagate_spectrum(
      domain$values, Kd, from = 10, to = 20, format = "matrix"
    )
    expect_equal(spectra[["20"]], as.numeric(expected_20m[, 1]))

    session$setInputs(depths = c(5, 20), depth_step = 5)
    expect_error(
      dp_spectra(),
      "shallower than source 'underwater_10m'",
      class = "lux_spectrum_depth_error"
    )
  })
})

test_that("Depth Propagation crosses the surface for an air source", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")

  shiny::testServer(app_dir, {
    session$setInputs(
      source_type = "solar", solar_cond = "clear_noon",
      wtype = "II", dp_wavelength_policy = "trim",
      depths = c(0, 10), depth_step = 10,
      dp_unit = "W_nm"
    )
    src <- dp_source()
    spectra <- dp_spectra()
    tau <- surface_transmittance(angle = 30)

    expect_identical(src$reference_medium, "air")
    metadata <- dp_metadata()
    expect_true(all(metadata$surface_transmission_applied))
    expect_equal(metadata$surface_multiplier, rep(tau, nrow(metadata)))
    expect_no_error(output$dp_plot)
    expect_equal(spectra[["0"]], dp_domain()$values * tau)
    expect_equal(
      spectra[["10"]],
      light_at_depth(
        "clear_noon", "II", depth = 10, wavelength_policy = "trim"
      )$irradiance
    )
  })
})

test_that("Colour and Detection reject targets shallower than an underwater reference", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")

  shiny::testServer(app_dir, {
    session$setInputs(jnd_solar = "underwater_10m", jnd_wtype = "IA",
                      jnd_wavelength_policy = "trim", jnd_depth = 10)
    source <- solar_irradiance("underwater_10m")
    keep <- source$wavelength >= 350 & source$wavelength <= 700
    expect_equal(jnd_light()$irradiance, source$irradiance[keep])

    session$setInputs(det_solar = "underwater_1m", det_wtype = "IA",
                      det_wavelength_policy = "trim", det_depth = 1)
    source_1m <- solar_irradiance("underwater_1m")
    keep_1m <- source_1m$wavelength >= 350 & source_1m$wavelength <= 700
    expect_equal(det_light()$irradiance, source_1m$irradiance[keep_1m])

    session$setInputs(jnd_depth = 5)
    expect_error(jnd_light(), class = "lux_spectrum_depth_error")
    session$setInputs(det_depth = 0)
    expect_error(det_light(), class = "lux_spectrum_depth_error")
  })
})

test_that("Depth Propagation 'Load example data' loads the Mare Chiaro spectrum", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")

  shiny::testServer(app_dir, {
    session$setInputs(source_type = "upload",
                      wtype = "IA", dp_wavelength_policy = "trim",
                      depths = c(5, 20), depth_step = 5,
                      dp_unit = "W_nm")
    # before clicking, an upload source with no file should error (need a file)
    expect_error(dp_source())
    # clicking the example button loads the bundled Mare Chiaro spectrum (W/m2/nm)
    session$setInputs(dp_example = 1)
    src <- dp_source()
    expect_equal(src$lambda, Naples$wv)
    expect_equal(length(src$irradiance), length(Naples$wv))
    expect_true(all(src$irradiance > 0))
    expect_identical(src$reference_depth_m, 0)
    expect_identical(src$reference_medium, "water")
    # in W/m2/nm the values are far smaller than the raw umol numbers
    expect_lt(max(src$irradiance), max(Naples$depth_0m))
    expect_match(paste(unlist(output$dp_refs), collapse = " "), "Mare Chiaro")
  })
})

test_that(".preset_reflectance returns values in [0,1] on the given grid", {
  lambda <- seq(400, 700, by = 5)
  grey <- luxR:::.preset_reflectance("grey", lambda)
  red  <- luxR:::.preset_reflectance("red",  lambda)
  expect_length(grey, length(lambda))
  expect_true(all(grey >= 0 & grey <= 1))
  expect_true(all(red  >= 0 & red  <= 1))
  expect_gt(red[length(red)], red[1])   # red preset: higher at long than short λ
})

test_that(".read_reflectance_csv handles headed and headerless 2-column files", {
  lambda <- seq(400, 700, by = 10)

  headed <- tempfile(fileext = ".csv")
  on.exit(unlink(headed), add = TRUE)
  utils::write.csv(
    data.frame(wavelength = c(400, 550, 700), reflectance = c(0.1, 0.5, 0.9)),
    headed, row.names = FALSE)
  r1 <- luxR:::.read_reflectance_csv(headed, lambda)
  expect_length(r1, length(lambda))
  expect_true(all(r1 >= 0 & r1 <= 1))
  expect_equal(r1[lambda == 550], 0.5)

  headerless <- tempfile(fileext = ".csv")
  on.exit(unlink(headerless), add = TRUE)
  writeLines(c("400,0.1", "550,0.5", "700,0.9"), headerless)
  r2 <- luxR:::.read_reflectance_csv(headerless, lambda)
  # first data row must not be lost to a phantom header
  expect_equal(r2[lambda == 400], 0.1)
  expect_equal(r2[lambda == 550], 0.5)

  one_row <- tempfile(fileext = ".csv")
  on.exit(unlink(one_row), add = TRUE)
  writeLines("450,0.3", one_row)
  expect_error(luxR:::.read_reflectance_csv(one_row, lambda))
})

test_that(".read_reflectance_csv rejects repair and extrapolation paths", {
  lambda <- seq(400, 700, by = 10)
  outside <- tempfile(fileext = ".csv")
  malformed <- tempfile(fileext = ".csv")
  short_coverage <- tempfile(fileext = ".csv")
  on.exit(unlink(c(outside, malformed, short_coverage)))
  writeLines(c("wavelength,reflectance", "400,-0.1", "700,0.5"), outside)
  writeLines(c("wavelength,reflectance", "400,bad", "700,0.5"), malformed)
  writeLines(c("wavelength,reflectance", "450,0.1", "650,0.5"),
             short_coverage)
  expect_error(luxR:::.read_reflectance_csv(outside, lambda),
               class = "luxR_spectrum_value_error")
  expect_error(luxR:::.read_reflectance_csv(malformed, lambda),
               class = "luxR_spectrum_value_error")
  expect_error(luxR:::.read_reflectance_csv(short_coverage, lambda),
               "extrapolation is disabled",
               class = "luxR_spectrum_value_error")
})

test_that(".app_jnd is ~0 for identical reflectances and >0 for different ones", {
  lambda     <- seq(400, 700, by = 5)
  illuminant <- rep(1.0, length(lambda))            # flat white light field
  grey       <- luxR:::.preset_reflectance("grey", lambda)
  red        <- luxR:::.preset_reflectance("red",  lambda)
  species    <- "Danio rerio"
  recs       <- utils::head(
    unique(luxR::species_sensitivities$receptor[
      luxR::species_sensitivities$species == species]), 3)

  jnd_same <- luxR:::.app_jnd(grey, grey, illuminant, lambda, species, recs)
  jnd_diff <- luxR:::.app_jnd(grey, red,  illuminant, lambda, species, recs)

  expect_lt(jnd_same, 1e-6)
  expect_gt(jnd_diff, jnd_same)
})

test_that("Depth Propagation does not offer unsupported TriOS upload", {
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) {
    app_dir <- testthat::test_path("..", "..", "inst", "app")
  }
  ui_path <- file.path(app_dir, "ui.R")
  skip_if(!file.exists(ui_path), "app UI not found")
  ui <- paste(readLines(ui_path), collapse = "\n")
  expect_false(grepl('"TriOS RAMSES"[[:space:]]*=[[:space:]]*"trios"', ui))
  expect_match(ui, "cannot be converted to irradiance")
})

test_that("Colour tab computes a JND via testServer", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")
  sp <- sort(unique(luxR::species_channels$species[
    luxR::species_channels$channel_role == "chromatic" &
      luxR::species_channels$is_default]))[1]
  shiny::testServer(app_dir, {
    session$setInputs(jnd_solar="clear_noon", jnd_wtype="IA",
                      jnd_wavelength_policy="trim", jnd_depth=5,
                      jnd_species=sp, jnd_r1="grey", jnd_r2="red", jnd_calc=1)
    res <- jnd_result()
    expect_true(is.numeric(res$jnd) && is.finite(res$jnd))
    expect_gt(res$jnd, 0)
  })
})

test_that("Detection tab routes only validated species channels", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")

  shiny::testServer(app_dir, {
    expect_identical(detection_channel("Homo sapiens"), "chromatic")
    expect_identical(detection_channel("Danio rerio"), "both")
    expect_identical(detection_channel("Apis mellifera"), "both")
    expect_identical(detection_channel("Drosophila melanogaster"), "achromatic")
    expect_error(
      detection_channel("Callorhinchus milii"),
      "no validated detection channel"
    )
  })
})

test_that("Species Perception applies optical-density self-screening", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")

  shiny::testServer(app_dir, {
    session$setInputs(sp_species = "Danio rerio", sp_receptor = "L-cone",
                      sp_solar = "clear_noon", sp_od = 0)
    # OD = 0 -> bare template (effective sensitivity unchanged)
    expect_equal(max(sp_effective_S()$S), max(sp_sensitivity()$S),
                 tolerance = 1e-9)

    # OD = 1 -> absorptance with base-10 peak capture of 1 - 10^-1 = 0.9
    session$setInputs(sp_od = 1)
    expect_equal(max(sp_effective_S()$S), 0.9, tolerance = 1e-6)

    # quantum catch computes, and the references gain the self-screening cite
    session$setInputs(sp_calc = 1)
    expect_true(is.finite(sp_qcatch_val()) && sp_qcatch_val() > 0)
    result <- sp_qcatch_df()
    expect_identical(result$unit, "photon/m2/s")
    expect_match(result$quantity, "weighted photon irradiance")
    expect_match(result$interpretation, "not an absolute per-receptor")
    expect_match(result$absolute_rate_status, "collection area")
    expect_match(result$absolute_rate_status, "solid angle")
    expect_match(result$absolute_rate_status, "ocular transmission")
    expect_match(result$absolute_rate_status, "quantum efficiency")
    expect_match(result$source_checksum_md5, "^[0-9a-f]{32}$")
    expect_identical(result$source_model_version, "solar-legacy-v1")
    expect_match(result$sensitivity_source_checksum_md5, "^[0-9a-f]{32}$")
    expect_identical(result$sensitivity_model_version, "species-v1")
    expect_match(result$sensitivity_citation_keys, "bowmakerDartnall1980")
    rendered <- paste(unlist(output$sp_qcatch), collapse = " ")
    expect_match(rendered, "photons m\u207b\u00b2 s\u207b\u00b9")
    expect_match(rendered, "Not an absolute photons per receptor per second rate")
    expect_match(paste(unlist(output$sp_refs), collapse = " "), "Self-screening")
  })
})

test_that(".visibility_metrics returns positive, ordered depths", {
  m <- luxR:::.visibility_metrics(Kd = 0.1, photic_fraction = 0.01,
                                  contrast_threshold = 0.02)
  expect_named(m, c("secchi_m", "photic_m", "visual_range_m"))
  expect_true(all(unlist(m) > 0))
  # clearer water (smaller Kd) => deeper photic depth
  m2 <- luxR:::.visibility_metrics(Kd = 0.05, photic_fraction = 0.01,
                                   contrast_threshold = 0.02)
  expect_gt(m2$photic_m, m$photic_m)
})

test_that(".visibility_metrics applies a measured beam_c to visual range only", {
  m_proxy <- luxR:::.visibility_metrics(0.1)
  m_c     <- luxR:::.visibility_metrics(0.1, beam_c = 0.3)
  expect_equal(m_c$visual_range_m, visual_range(0.1, beam_c = 0.3))
  expect_false(isTRUE(all.equal(m_proxy$visual_range_m, m_c$visual_range_m)))
  # Secchi and photic depth depend on Kd only, so beam_c leaves them unchanged
  expect_equal(m_proxy$secchi_m, m_c$secchi_m)
  expect_equal(m_proxy$photic_m, m_c$photic_m)
})

test_that("each tab renders a data-sources caption with the right citations", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")

  flat <- function(x) paste(unlist(x), collapse = " ")

  shiny::testServer(app_dir, {
    # Depth Propagation: solar default cites ASTM + Jerlov; example data switches
    session$setInputs(source_type = "solar")
    dp <- flat(output$dp_refs)
    expect_match(dp, "ASTM G173-03")
    expect_match(dp, "Jerlov")
    session$setInputs(source_type = "upload", dp_example = 1)
    expect_match(flat(output$dp_refs), "Mare Chiaro")

    # Species Perception: per-species source + Govardovskii template
    session$setInputs(sp_species = "Danio rerio")
    sp <- flat(output$sp_refs)
    expect_match(sp, "Robinson")          # Danio rerio lambda_max source
    expect_match(sp, "Govardovskii")

    # Colour discrimination: Vorobyev-Osorio model citation
    session$setInputs(jnd_species = "Danio rerio")
    expect_match(flat(output$jnd_refs), "Vorobyev")

    # Visibility: Secchi + visual-range method citations
    vis <- flat(output$vis_refs)
    expect_match(vis, "Tyler")
    expect_match(vis, "Duntley")
    expect_match(vis, "not an empirically validated")
  })
})

test_that("Visibility tab renders a 3-row metric table", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")
  shiny::testServer(app_dir, {
    session$setInputs(vis_wtype="IA", vis_lambda=550,
                      vis_photic=0.01, vis_contrast=0.02)
    out <- paste(as.character(output$vis_table), collapse = " ")
    expect_match(out, "Secchi depth")
    expect_match(out, "Horizontal visual range")
  })
})

test_that("Detection tab computes a lux_detection result via testServer", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")
  shiny::testServer(app_dir, {
    session$setInputs(det_solar = "clear_noon", det_wtype = "IA",
                      det_wavelength_policy = "trim", det_depth = 5,
                      det_lambda = 490, det_species = "Danio rerio",
                      det_obj = "red", det_bg = "grey", det_dir = "horizontal",
                      det_contrast = 0.02)
    d <- det_result()
    expect_s3_class(d, "lux_detection")
    expect_identical(d$model, "scalar_heuristic")
    expect_match(d$validation, "not empirically validated")
    expect_true(is.finite(d$range$achromatic) && d$range$achromatic > 0)
    expect_match(paste(unlist(output$det_out), collapse = " "), "heuristic")
    expect_match(paste(unlist(output$det_refs), collapse = " "), "sighting")
  })
})

test_that("Visibility and Detection tabs use a measured beam attenuation when enabled", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- testthat::test_path("..", "..", "inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")
  shiny::testServer(app_dir, {
    # Visibility: vis_beam_c() is NULL until enabled, then c = a + b
    session$setInputs(vis_wtype = "IA", vis_lambda = 550, vis_photic = 0.01,
                      vis_contrast = 0.02, vis_use_c = FALSE)
    expect_null(vis_beam_c())
    session$setInputs(vis_use_c = TRUE, vis_a = 0.2, vis_b = 0.1)
    expect_equal(vis_beam_c(), 0.3, tolerance = 1e-9)
    expect_match(paste(unlist(output$vis_refs), collapse = " "), "Beam attenuation")

    # Detection: enabling beam_c changes the computed range
    session$setInputs(det_solar = "clear_noon", det_wtype = "IA",
                      det_wavelength_policy = "trim", det_depth = 5,
                      det_lambda = 490, det_species = "Danio rerio",
                      det_obj = "red", det_bg = "grey", det_dir = "horizontal",
                      det_contrast = 0.02, det_use_c = FALSE)
    r_proxy <- det_result()$range$achromatic
    session$setInputs(det_use_c = TRUE, det_a = 0.3, det_b = 0.2)   # c = 0.5
    r_meas <- det_result()$range$achromatic
    expect_false(isTRUE(all.equal(r_proxy, r_meas)))
  })
})

test_that("the app sources carry no un-superscripted squared metres", {
  app_dir <- system.file("app", package = "luxR")
  if (identical(app_dir, "")) app_dir <- "../../inst/app"
  skip_if_not(dir.exists(app_dir), "bundled app sources not available")

  src <- unlist(lapply(
    list.files(app_dir, pattern = "\\.R$", full.names = TRUE),
    readLines, warn = FALSE, encoding = "UTF-8"
  ))

  # Lines that assign or convert to a canonical unit are data, not display,
  # and are expected to contain the ASCII form. Comments are excluded too.
  display <- src[!grepl("unit\\s*=|convert_unit|^\\s*#", src)]

  expect_false(any(grepl("m\\^2", display)),
               info = "literal 'm^2' left in an app display string")
  expect_false(any(grepl("/ m\u00b2 /", display, fixed = TRUE)),
               info = "solidus unit style left in the app; use exponents")
})
