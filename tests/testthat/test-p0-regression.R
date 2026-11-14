# Regression tests for the P0 energy <-> photon radiance conversion
# (TODO.md, "Correct energy-to-photon conversion for radiance").
#
# The original defect dropped the steradian term and/or applied a 1000-fold
# error when converting spectral radiance. These tests reproduce the exact
# scenarios named in the acceptance criteria and lock the fix in place
# (via convert_unit(), the single public spectrum unit converter):
#
#   - Converting mW/m2/sr/nm neither loses /sr nor produces a 1000-fold error.
#   - Round-trip conversions retain quantity, unit, wavelength grid, and values.
#   - Irradiance and radiance conversions are correct independently for both
#     W and mW inputs against analytical values.

lam <- seq(400, 700, by = 10)
E   <- seq_along(lam) * 0.1          # strictly positive, non-trivial shape

# Independent analytical factor: J per umol photons at each wavelength.
J_per_umol <- 1.98644585714893e-16 * 6.02214076e23 * 1e-6 / lam

# --- photonic radiance -> energy radiance ------------------------------------

test_that("photon -> energy conversion preserves the steradian term", {
  photon_rad <- lux_spectrum(E, lam, "radiance", "umol/m2/s/sr/nm")
  out        <- convert_unit(photon_rad, "W/m2/sr/nm")

  expect_s3_class(out, "lux_spectrum")
  expect_equal(out$unit, "W/m2/sr/nm")
  expect_equal(out$quantity, "radiance")
  expect_equal(out$lambda, lam)
})

test_that("irradiance and radiance agree on values but not dimension", {
  out_irr <- convert_unit(lux_spectrum(E, lam, "irradiance", "umol/m2/s/nm"),
                          "W/m2/nm")
  out_rad <- convert_unit(lux_spectrum(E, lam, "radiance", "umol/m2/s/sr/nm"),
                          "W/m2/sr/nm")

  expect_equal(out_rad$E, out_irr$E)
  expect_equal(out_irr$unit, "W/m2/nm")
  expect_equal(out_rad$unit, "W/m2/sr/nm")
})

test_that("radiance values match the analytical hc/lambda conversion", {
  out <- convert_unit(lux_spectrum(E, lam, "radiance", "umol/m2/s/sr/nm"),
                      "W/m2/sr/nm")
  expect_equal(out$E, E * J_per_umol, tolerance = 1e-12)
})

# --- energy radiance -> photonic radiance ------------------------------------

test_that("energy -> photon conversion preserves the steradian term", {
  out <- convert_unit(lux_spectrum(E, lam, "radiance", "W/m2/sr/nm"),
                      "umol/m2/s/sr/nm")

  expect_equal(out$unit, "umol/m2/s/sr/nm")
  expect_equal(out$quantity, "radiance")
  expect_equal(out$lambda, lam)
  expect_equal(out$E, E / J_per_umol, tolerance = 1e-12)
})

test_that("mW radiance applies the 1e-3 factor without a 1000x error", {
  energy_W  <- lux_spectrum(E, lam, "radiance", "W/m2/sr/nm")
  energy_mW <- lux_spectrum(E, lam, "radiance", "mW/m2/sr/nm")

  out_W  <- convert_unit(energy_W,  "umol/m2/s/sr/nm")
  out_mW <- convert_unit(energy_mW, "umol/m2/s/sr/nm")

  expect_equal(out_mW$unit, "umol/m2/s/sr/nm")
  expect_equal(out_mW$E, out_W$E * 1e-3)
})

test_that("mW radiance converts to mol with the 1e-3 scale", {
  x_mW <- lux_spectrum(1, 500, "radiance", "mW/m2/sr/nm", binwidth = 1)
  x_W  <- lux_spectrum(1e-3, 500, "radiance", "W/m2/sr/nm", binwidth = 1)
  expect_equal(convert_unit(x_mW, "mol/m2/s/sr/nm")$E,
               convert_unit(x_W,  "mol/m2/s/sr/nm")$E, tolerance = 1e-12)
})

# --- Round trips retain quantity, unit, grid, and values --------------------

test_that("radiance round-trips energy -> photon -> W for W and mW input", {
  for (energy_unit in c("W/m2/sr/nm", "mW/m2/sr/nm")) {
    start <- lux_spectrum(E, lam, "radiance", energy_unit)
    back  <- convert_unit(convert_unit(start, "umol/m2/s/sr/nm"), "W/m2/sr/nm")
    expected <- if (energy_unit == "mW/m2/sr/nm") E * 1e-3 else E
    expect_equal(back$quantity, "radiance")
    expect_equal(back$lambda, lam)
    expect_equal(back$E, expected, tolerance = 1e-12)
  }
})

test_that("irradiance round-trips W -> photon -> W within tolerance", {
  start <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  back  <- convert_unit(convert_unit(start, "umol/m2/s/nm"), "W/m2/nm")

  expect_equal(back$unit, start$unit)
  expect_equal(back$quantity, start$quantity)
  expect_equal(back$E, start$E, tolerance = 1e-12)
})

test_that("conversion between irradiance and radiance units is rejected", {
  rad <- lux_spectrum(E, lam, "radiance", "W/m2/sr/nm")
  expect_error(convert_unit(rad, "umol/m2/s/nm"),
               "between irradiance and radiance", class = "luxR_unit_error")
})
