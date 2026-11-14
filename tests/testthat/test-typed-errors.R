# One class expectation per error site converted from a plain stop() call.
# Grouped by source file; kinds follow ?luxR-conditions.

lam <- seq(400, 700, by = 10)
irr <- lux_spectrum(rep(1, 31), lam, "irradiance", "W/m2/nm")

test_that("lux_spectrum.R: subsetting, arithmetic and conversion are typed", {
  expect_error(irr[800, 900], "No wavelengths", class = "luxR_grid_error")
  shifted <- lux_spectrum(rep(1, 31), lam + 1, "irradiance", "W/m2/nm")
  expect_error(irr + shifted, "identical lambda", class = "luxR_grid_error")
  rad <- lux_spectrum(rep(1, 31), lam, "radiance", "W/m2/sr/nm")
  expect_error(irr + rad, "different quantities", class = "luxR_unit_error")
  expect_error(irr * irr, "Unsupported lux_spectrum multiplication",
               class = "luxR_type_error")
  expect_error(irr / irr, "division between two spectra",
               class = "luxR_type_error")
  expect_error(luxR:::.lux_arithmetic(irr, irr, `^`),
               "Unsupported lux_spectrum operator", class = "luxR_internal_error")
  expect_error(irr * c(1, 2), "numeric scalar", class = "luxR_type_error")
  expect_error(c(1, 2) * irr, "numeric scalar", class = "luxR_type_error")
  expect_error(2 / irr, "reciprocal", class = "luxR_type_error")
  expect_error(convert_unit(irr, "furlongs"), "controlled unit vocabulary",
               class = "luxR_unit_error")
  expect_error(convert_unit(irr, "dimensionless"), "dimensionless",
               class = "luxR_unit_error")
  expect_error(convert_unit(irr, "W/m2/sr/nm"), "No conversion defined",
               class = "luxR_unit_error")
  expect_error(plot_spectra("x"), class = "luxR_type_error")
  expect_error(plot_spectra(list()), class = "luxR_value_error")
})

test_that("converters.R errors are typed", {
  expect_error(wavelength_in_medium(500, n = 0.5), "`n` must be >= 1",
               class = "luxR_value_error")
  expect_error(reflectance_to_radiance(c(0.5, 0.5), 1, 500),
               "same length", class = "luxR_dimension_error")
  expect_error(reflectance_to_radiance(1.5, 1, 500), "\\[0, 1\\]",
               class = "luxR_value_error")
  refl <- lux_spectrum(rep(0.5, 31), lam, "reflectance", "dimensionless")
  expect_error(reflectance_to_radiance(refl, rep(1, 31)), "must be a lux_spectrum",
               class = "luxR_type_error")
  expect_error(reflectance_to_radiance(irr, irr), "must be 'reflectance'",
               class = "luxR_unit_error")
  expect_error(reflectance_to_radiance(refl, refl),
               "'irradiance' or 'radiance'", class = "luxR_unit_error")
  shifted <- lux_spectrum(rep(1, 31), lam + 1, "irradiance", "W/m2/nm")
  expect_error(reflectance_to_radiance(refl, shifted), "grids must be identical",
               class = "luxR_grid_error")
})

test_that("unit, photon and molar conversions raise unit errors", {
  expect_error(unit_label(1), class = "luxR_type_error")
  expect_error(unit_label(NA_character_), class = "luxR_value_error")
  expect_error(unit_label("furlongs"), "controlled vocabulary",
               class = "luxR_unit_error")
  expect_error(n2W_spec_irradiance(irr), "requires a photonic unit",
               class = "luxR_unit_error")
  umol <- convert_unit(irr, "umol/m2/s/nm")
  expect_error(W2mol_spec_irradiance(umol), "energy-based unit",
               class = "luxR_unit_error")
  expect_error(luxR:::mol2photon_FUN(1, "pmol"), "Unrecognised molar_unit",
               class = "luxR_unit_error")
})

test_that("missing required arguments and bad values are value errors", {
  expect_error(resample_spectrum(1:3, 400:402), "'from'",
               class = "luxR_value_error")
  expect_error(michelson_contrast(0, 0), "both be zero",
               class = "luxR_value_error")
  expect_error(michelson_contrast(1, 2), "Check argument order",
               class = "luxR_value_error")
  expect_error(single_scattering_albedo(-1, 1), class = "luxR_value_error")
  expect_error(single_scattering_albedo(0, 0), "must be > 0",
               class = "luxR_value_error")
  expect_error(transmittance(-1, 1), class = "luxR_value_error")
  expect_error(transmittance(1, -1), class = "luxR_value_error")
  expect_error(absorbance(0), class = "luxR_value_error")
  expect_error(snells_window(1), class = "luxR_value_error")
  expect_error(fresnel_reflectance(0, n = c(1.3, 1.4)),
               class = "luxR_value_error")
  expect_error(fresnel_reflectance(91), class = "luxR_value_error")
  expect_error(surface_transmittance(), "`angle` is required",
               class = "luxR_value_error")
})

test_that("unknown names in lookups are value errors", {
  expect_error(species_LEF("Unicornis"), "unknown species",
               class = "luxR_value_error")
  expect_error(species_LEF("Homo sapiens", receptor = "Z-cone"),
               "unknown receptor", class = "luxR_value_error")
  expect_error(solar_irradiance("eclipse"), "unknown condition",
               class = "luxR_value_error")
  expect_error(from_solar("eclipse"), "condition must be one of",
               class = "luxR_value_error")
})

test_that("as_lux_spectrum column lookups are typed", {
  expect_error(as_lux_spectrum(data.frame(a = 1, E = 1)), "lambda column",
               class = "luxR_value_error")
  expect_error(as_lux_spectrum(data.frame(lambda = 400, b = 1)), "E column",
               class = "luxR_value_error")
  rspec <- structure(data.frame(x = 400:402, y = 1:3),
                     class = c("rspec", "data.frame"))
  expect_error(as_lux_spectrum(rspec), "no 'wl'", class = "luxR_type_error")
  rspec <- structure(data.frame(wl = 400:402, y = 1:3),
                     class = c("rspec", "data.frame"))
  expect_error(as_lux_spectrum(rspec, column = "z"), "Column not found",
               class = "luxR_value_error")
})

test_that("broken bundled provenance is a data error", {
  expect_error(luxR:::.bundled_dataset_provenance(data.frame(), "x"),
               "provenance metadata", class = "luxR_data_error")
  expect_error(luxR:::.bundled_source_import(list()),
               "provenance is incomplete", class = "luxR_data_error")
})
