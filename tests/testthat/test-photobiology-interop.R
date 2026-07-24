library(luxR)

# Bridge tests for luxR <-> photobiology generic spectral classes.
#
# luxR handles the water; photobiology handles generic spectral classes,
# integration, and photometry. These tests check that spectra cross that line
# with their dimensions, magnitudes, and grids intact, and that anything
# ambiguous or dimensionally unrepresentable is refused rather than repaired.

lam_fixture <- seq(400, 410, by = 1)
E_fixture   <- seq(1, 2, length.out = length(lam_fixture))

irradiance_fixture <- function(unit = "W/m2/nm", E = E_fixture) {
  lux_spectrum(E, lam_fixture, "irradiance", unit,
               meta = list(source = "fixture", depth_m = 15))
}

test_that("an energy irradiance becomes a source_spct with s.e.irrad", {
  skip_if_not_installed("photobiology")
  out <- as_source_spct(irradiance_fixture())
  expect_s3_class(out, "source_spct")
  expect_equal(out$w.length, lam_fixture)
  expect_equal(out$s.e.irrad, E_fixture)
  expect_false("s.q.irrad" %in% names(out))
  expect_identical(photobiology::getTimeUnit(out), "second")
})

test_that("photon units map to s.q.irrad with the correct decimal factor", {
  skip_if_not_installed("photobiology")
  cases <- list("mol/m2/s/nm" = 1, "mmol/m2/s/nm" = 1e-3,
                "umol/m2/s/nm" = 1e-6)
  for (unit in names(cases)) {
    out <- as_source_spct(irradiance_fixture(unit))
    expect_equal(out$s.q.irrad, E_fixture * cases[[unit]],
                 info = unit)
    expect_false("s.e.irrad" %in% names(out), info = unit)
  }
})

test_that("luxR provenance travels with the exported spectrum", {
  skip_if_not_installed("photobiology")
  out <- as_source_spct(irradiance_fixture())
  expect_match(comment(out), "luxR")
  expect_match(comment(out), "irradiance \\[W/m2/nm\\]")
  expect_match(comment(out), "depth_m=15")
  expect_match(photobiology::getWhatMeasured(out), "luxR")
})

test_that("radiance cannot become a source_spct", {
  skip_if_not_installed("photobiology")
  rad <- lux_spectrum(E_fixture, lam_fixture, "radiance", "W/m2/sr/nm")
  expect_error(as_source_spct(rad), "radiance2irradiance")
})

test_that("reflectance cannot become a source_spct", {
  skip_if_not_installed("photobiology")
  refl <- lux_spectrum(rep(0.5, length(lam_fixture)), lam_fixture,
                       "reflectance", "dimensionless")
  expect_error(as_source_spct(refl), "as_reflector_spct")
})

test_that("a list of spectra converts elementwise, preserving names", {
  skip_if_not_installed("photobiology")
  out <- as_source_spct(list(shallow = irradiance_fixture(),
                             deep    = irradiance_fixture(E = E_fixture / 2)))
  expect_named(out, c("shallow", "deep"))
  expect_s3_class(out$shallow, "source_spct")
  expect_equal(out$deep$s.e.irrad, E_fixture / 2)
})

test_that("unnamed list elements get positional names", {
  skip_if_not_installed("photobiology")
  out <- as_source_spct(list(irradiance_fixture(), irradiance_fixture()))
  expect_named(out, c("spec1", "spec2"))
})

test_that("a list that is empty or holds non-spectra is refused", {
  skip_if_not_installed("photobiology")
  expect_error(as_source_spct(list()), "non-empty list")
  expect_error(as_source_spct(list(1:10)), "non-empty list")
})

reflectance_fixture <- function(Rfr_type = NULL) {
  lux_spectrum(rep(0.4, length(lam_fixture)), lam_fixture,
               "reflectance", "dimensionless",
               meta = if (is.null(Rfr_type)) list(source = "fixture")
                      else list(source = "fixture", Rfr_type = Rfr_type))
}

test_that("reflectance becomes a reflector_spct with a declared Rfr.type", {
  skip_if_not_installed("photobiology")
  out <- as_reflector_spct(reflectance_fixture(), Rfr.type = "total")
  expect_s3_class(out, "reflector_spct")
  expect_equal(out$Rfr, rep(0.4, length(lam_fixture)))
  expect_identical(photobiology::getRfrType(out), "total")
})

test_that("Rfr.type is taken from metadata when recorded", {
  skip_if_not_installed("photobiology")
  out <- as_reflector_spct(reflectance_fixture("specular"))
  expect_identical(photobiology::getRfrType(out), "specular")
})

test_that("an undeclared Rfr.type is an error, never a default", {
  skip_if_not_installed("photobiology")
  expect_error(as_reflector_spct(reflectance_fixture()), "Rfr.type")
})

test_that("Rfr.type must be total or specular", {
  skip_if_not_installed("photobiology")
  expect_error(as_reflector_spct(reflectance_fixture(), Rfr.type = "diffuse"),
               "total")
})

test_that("irradiance cannot become a reflector_spct", {
  skip_if_not_installed("photobiology")
  expect_error(as_reflector_spct(irradiance_fixture()), "as_source_spct")
})

test_that("a list of reflectances converts elementwise", {
  skip_if_not_installed("photobiology")
  out <- as_reflector_spct(list(a = reflectance_fixture("total"),
                                b = reflectance_fixture("total")))
  expect_named(out, c("a", "b"))
  expect_s3_class(out$a, "reflector_spct")
})

source_spct_fixture <- function(...) {
  photobiology::source_spct(w.length = lam_fixture, s.e.irrad = E_fixture, ...)
}

test_that("a source_spct imports as W/m2/nm irradiance", {
  skip_if_not_installed("photobiology")
  x <- as_lux_spectrum(source_spct_fixture())
  expect_s3_class(x, "lux_spectrum")
  expect_identical(x$quantity, "irradiance")
  expect_identical(x$unit, "W/m2/nm")
  expect_equal(x$lambda, lam_fixture)
  expect_equal(x$E, E_fixture)
})

test_that("a photon source_spct imports as mol/m2/s/nm", {
  skip_if_not_installed("photobiology")
  q <- photobiology::source_spct(w.length = lam_fixture,
                                 s.q.irrad = E_fixture * 1e-6)
  x <- as_lux_spectrum(q)
  expect_identical(x$unit, "mol/m2/s/nm")
  expect_equal(x$E, E_fixture * 1e-6)
})

test_that("import records the photobiology origin and applied policies", {
  skip_if_not_installed("photobiology")
  x <- as_lux_spectrum(source_spct_fixture())
  expect_identical(x$meta$import$format, "photobiology::source_spct")
  expect_identical(x$meta$import$configuration$negative_policy, "error")
  expect_false(x$meta$import$configuration$interpolate)
  expect_identical(x$meta$photobiology_version,
                   as.character(utils::packageVersion("photobiology")))
})

test_that("a dose-based time unit is refused", {
  skip_if_not_installed("photobiology")
  d <- photobiology::source_spct(w.length = lam_fixture,
                                 s.e.irrad = E_fixture, time.unit = "day")
  expect_error(as_lux_spectrum(d), "time.unit",
               class = "luxR_spectrum_dimension_error")
})

test_that("a biologically weighted spectrum is refused", {
  skip_if_not_installed("photobiology")
  b <- source_spct_fixture()
  photobiology::setBSWFUsed(b, "unknown")
  expect_error(as_lux_spectrum(b), "bswf",
               class = "luxR_spectrum_dimension_error")
})

test_that("an ambiguous energy/photon basis must be named", {
  skip_if_not_installed("photobiology")
  both <- photobiology::e2q(source_spct_fixture(), action = "add")
  expect_error(as_lux_spectrum(both), "measurement",
               class = "luxR_spectrum_schema_error")
  expect_identical(as_lux_spectrum(both, measurement = "energy")$unit,
                   "W/m2/nm")
  expect_identical(as_lux_spectrum(both, measurement = "photon")$unit,
                   "mol/m2/s/nm")
})

test_that("negative values are refused unless the zero floor is requested", {
  skip_if_not_installed("photobiology")
  neg <- photobiology::source_spct(w.length = lam_fixture,
                                   s.e.irrad = c(-0.5, E_fixture[-1]),
                                   strict.range = FALSE)
  expect_error(as_lux_spectrum(neg), "negative",
               class = "luxR_spectrum_value_error")
  floored <- as_lux_spectrum(neg, negative_policy = "zero")
  expect_equal(floored$E[1], 0)
  expect_identical(floored$meta$import$configuration$negative_policy, "zero")
})

test_that("an irregular grid is refused unless interpolation is requested", {
  skip_if_not_installed("photobiology")
  irregular_wl <- c(400, 401, 403, 406, 410)
  irr <- photobiology::source_spct(w.length = irregular_wl,
                                   s.e.irrad = seq(1, 2, length.out = 5))
  expect_error(as_lux_spectrum(irr), "interpolate",
               class = "luxR_spectrum_grid_error")
  fixed <- as_lux_spectrum(irr, interpolate = TRUE)
  expect_true(fixed$meta$import$configuration$interpolate)
  expect_equal(diff(fixed$lambda), rep(1, length(fixed$lambda) - 1))
})

test_that("a multi-spectrum source_spct is refused", {
  skip_if_not_installed("photobiology")
  multi <- photobiology::rbindspct(
    list(source_spct_fixture(), source_spct_fixture())
  )
  expect_gt(photobiology::getMultipleWl(multi), 1)
  expect_error(as_lux_spectrum(multi), "spectra",
               class = "luxR_spectrum_schema_error")
})

test_that("a source_spct with neither irradiance column is refused", {
  skip_if_not_installed("photobiology")
  # photobiology's own source_spct() constructor always fills in an
  # NA s.e.irrad column when neither is supplied, so the "neither present"
  # state is reached here by stamping the class directly rather than via
  # the constructor, bypassing that auto-repair.
  bare <- data.frame(w.length = lam_fixture)
  class(bare) <- c("source_spct", "generic_spct", "tbl_df", "tbl", "data.frame")
  photobiology::setTimeUnit(bare, "second")
  stopifnot(photobiology::is.source_spct(bare))
  expect_error(as_lux_spectrum(bare), "s.e.irrad",
               class = "luxR_spectrum_schema_error")
})

test_that("a sub-nanometre wavelength span cannot be resampled", {
  skip_if_not_installed("photobiology")
  narrow <- photobiology::source_spct(w.length = c(400.1, 400.3, 400.7),
                                      s.e.irrad = c(1, 1.1, 1.2))
  expect_error(as_lux_spectrum(narrow, interpolate = TRUE),
               "span", class = "luxR_spectrum_grid_error")
})

test_that("a reflector_spct imports as dimensionless reflectance", {
  skip_if_not_installed("photobiology")
  r <- photobiology::reflector_spct(w.length = lam_fixture,
                                    Rfr = rep(0.4, length(lam_fixture)),
                                    Rfr.type = "total")
  x <- as_lux_spectrum(r)
  expect_identical(x$quantity, "reflectance")
  expect_identical(x$unit, "dimensionless")
  expect_equal(x$E, rep(0.4, length(lam_fixture)))
  expect_identical(x$meta$Rfr_type, "total")
})

test_that("an Rpc column is converted from percent, not clamped", {
  skip_if_not_installed("photobiology")
  r <- photobiology::reflector_spct(w.length = lam_fixture,
                                    Rpc = rep(25, length(lam_fixture)),
                                    Rfr.type = "specular")
  x <- as_lux_spectrum(r)
  expect_equal(x$E, rep(0.25, length(lam_fixture)))
  expect_identical(x$meta$Rfr_type, "specular")
})

test_that("reflectance above 1 is refused rather than clamped", {
  skip_if_not_installed("photobiology")
  r <- photobiology::reflector_spct(w.length = lam_fixture,
                                    Rfr = c(1.4, rep(0.4, 10)),
                                    Rfr.type = "total", strict.range = FALSE)
  expect_error(as_lux_spectrum(r), "\\[0, 1\\]",
               class = "lux_spectrum_value_error")
})

test_that("reflectance round-trips through photobiology intact", {
  skip_if_not_installed("photobiology")
  original <- reflectance_fixture("total")
  back <- as_lux_spectrum(as_reflector_spct(original))
  expect_equal(back$lambda, original$lambda)
  expect_equal(back$E, original$E)
  expect_identical(back$quantity, original$quantity)
  expect_identical(back$unit, original$unit)
  expect_identical(back$meta$Rfr_type, "total")
})

test_that("irradiance round-trips through photobiology intact", {
  skip_if_not_installed("photobiology")
  original <- irradiance_fixture()
  back <- as_lux_spectrum(as_source_spct(original))
  expect_equal(back$lambda, original$lambda)
  expect_equal(back$E, original$E)
  expect_identical(back$quantity, original$quantity)
  expect_identical(back$unit, original$unit)
  expect_equal(back$binwidth, original$binwidth)
})

test_that("every photon unit round-trips to its mol/m2/s/nm equivalent", {
  skip_if_not_installed("photobiology")
  factors <- list("mol/m2/s/nm" = 1, "mmol/m2/s/nm" = 1e-3,
                  "umol/m2/s/nm" = 1e-6)
  for (unit in names(factors)) {
    back <- as_lux_spectrum(as_source_spct(irradiance_fixture(unit)))
    expect_identical(back$unit, "mol/m2/s/nm", info = unit)
    expect_equal(back$E, E_fixture * factors[[unit]], info = unit)
  }
})

test_that("luxR's photon scaling agrees with photobiology's own conversion", {
  skip_if_not_installed("photobiology")
  energy <- irradiance_fixture("W/m2/nm")
  # photobiology's route: export the energy spectrum, let it convert.
  via_photobiology <- photobiology::e2q(as_source_spct(energy),
                                        action = "replace")$s.q.irrad
  # luxR's route: convert units first, then export.
  via_luxR <- as_source_spct(convert_unit(energy, "umol/m2/s/nm"))$s.q.irrad
  expect_equal(via_luxR, via_photobiology, tolerance = 1e-6)
})

test_that("a propagated in-water spectrum survives the handoff", {
  skip_if_not_installed("photobiology")
  # Jerlov Kd data cover 350-700 nm, so trim the 300-800 nm solar spectrum
  # to the supported range before propagating.
  surface  <- from_solar("clear_noon")[350, 700]
  Kd       <- jerlov_Kd("II", surface$lambda)
  at_depth <- propagate_spectrum(surface, Kd, from = 0, to = 15)
  if (!inherits(at_depth, "lux_spectrum")) at_depth <- at_depth[[1]]
  out <- as_source_spct(at_depth)
  expect_s3_class(out, "source_spct")
  expect_equal(out$w.length, at_depth$lambda)
  expect_true(all(is.finite(out$s.e.irrad)))
  back <- as_lux_spectrum(out)
  expect_equal(back$E, at_depth$E)
})
