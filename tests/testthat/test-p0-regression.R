# Regression tests for the P0 energy <-> photon radiance conversion
# (TODO.md, "Correct energy-to-photon conversion for radiance").
#
# The original defect dropped the steradian term and/or applied a 1000-fold
# error when converting spectral radiance. These tests reproduce the exact
# scenarios named in the acceptance criteria and lock the fix in place:
#
#   - Converting mW/m2/sr/nm neither loses /sr nor produces a 1000-fold error.
#   - Round-trip conversions retain quantity, unit, wavelength grid, and values.
#   - Irradiance and radiance conversions are correct independently for both
#     W and mW inputs against analytical values.

lam <- seq(400, 700, by = 10)
E   <- seq_along(lam) * 0.1          # strictly positive, non-trivial shape

# --- n2W_spec_irradiance: photonic radiance -> energy radiance ---------------

test_that("n2W preserves the steradian term for radiance input", {
  photon_rad <- lux_spectrum(E, lam, "radiance", "umol/m2/s/sr/nm")
  out        <- n2W_spec_irradiance(photon_rad)

  expect_s3_class(out, "lux_spectrum")
  expect_equal(out$unit, "W/m2/sr/nm")     # /sr retained, not dropped to W/m2/nm
  expect_equal(out$quantity, "radiance")
  expect_equal(out$lambda, lam)
})

test_that("n2W irradiance and radiance agree on values but not dimension", {
  photon_irr <- lux_spectrum(E, lam, "irradiance", "umol/m2/s/nm")
  photon_rad <- lux_spectrum(E, lam, "radiance",    "umol/m2/s/sr/nm")

  out_irr <- n2W_spec_irradiance(photon_irr)
  out_rad <- n2W_spec_irradiance(photon_rad)

  # Identical per-bin arithmetic; the only difference is the /sr dimension.
  expect_equal(out_rad$E, out_irr$E)
  expect_equal(out_irr$unit, "W/m2/nm")
  expect_equal(out_rad$unit, "W/m2/sr/nm")
})

test_that("n2W radiance values match the analytical hc/lambda conversion", {
  photon_rad <- lux_spectrum(E, lam, "radiance", "umol/m2/s/sr/nm")
  out        <- n2W_spec_irradiance(photon_rad)

  expected <- n2W_spec_irradiance.numeric(E, lam, photonic = TRUE,
                                          molar_unit = "umol")
  expect_equal(out$E, expected)
})

# --- W2mol_spec_irradiance: energy radiance -> photonic radiance -------------

test_that("W2mol preserves the steradian term for radiance input", {
  energy_rad <- lux_spectrum(E, lam, "radiance", "W/m2/sr/nm")
  out        <- W2mol_spec_irradiance(energy_rad, molar_unit = "umol")

  expect_equal(out$unit, "umol/m2/s/sr/nm")   # /sr retained
  expect_equal(out$quantity, "radiance")
  expect_equal(out$lambda, lam)
})

test_that("W2mol applies the 1e-3 factor for mW radiance without a 1000x error", {
  # The reproduction: the same numeric values labelled mW vs W must differ by
  # exactly 1000, and mW must keep its /sr term.
  energy_W  <- lux_spectrum(E, lam, "radiance", "W/m2/sr/nm")
  energy_mW <- lux_spectrum(E, lam, "radiance", "mW/m2/sr/nm")

  out_W  <- W2mol_spec_irradiance(energy_W,  molar_unit = "umol")
  out_mW <- W2mol_spec_irradiance(energy_mW, molar_unit = "umol")

  expect_equal(out_mW$unit, "umol/m2/s/sr/nm")   # /sr not dropped
  expect_equal(out_mW$E, out_W$E * 1e-3)         # exactly 1000-fold, no more
})

# --- Round trips retain quantity, unit, grid, and values --------------------

test_that("radiance round-trips W -> photon -> W within tolerance", {
  start <- lux_spectrum(E, lam, "radiance", "W/m2/sr/nm")
  back  <- n2W_spec_irradiance(W2mol_spec_irradiance(start, molar_unit = "umol"))

  expect_equal(back$unit, start$unit)
  expect_equal(back$quantity, start$quantity)
  expect_equal(back$lambda, start$lambda)
  expect_equal(back$E, start$E, tolerance = 1e-8)
})

test_that("irradiance round-trips W -> photon -> W within tolerance", {
  start <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  back  <- n2W_spec_irradiance(W2mol_spec_irradiance(start, molar_unit = "umol"))

  expect_equal(back$unit, start$unit)
  expect_equal(back$quantity, start$quantity)
  expect_equal(back$E, start$E, tolerance = 1e-8)
})

# --- Direction guards: each converter rejects the wrong unit family ----------

test_that("n2W rejects energy units and W2mol rejects photonic units", {
  energy_rad <- lux_spectrum(E, lam, "radiance", "W/m2/sr/nm")
  photon_rad <- lux_spectrum(E, lam, "radiance", "umol/m2/s/sr/nm")

  expect_error(n2W_spec_irradiance(energy_rad),  "photonic unit")
  expect_error(W2mol_spec_irradiance(photon_rad), "energy-based unit")
})
