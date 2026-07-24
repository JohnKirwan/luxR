library(luxR)

# ---- beam_attenuation / single_scattering_albedo ------------------------

test_that("beam_attenuation is c = a + b", {
  expect_equal(beam_attenuation(0.1, 0.05), 0.15)
  expect_equal(beam_attenuation(c(0.1, 0.2), c(0.05, 0.1)), c(0.15, 0.30))
})

test_that("single_scattering_albedo is b / (a + b)", {
  expect_equal(single_scattering_albedo(0.1, 0.05), 0.05 / 0.15, tolerance = 1e-12)
  expect_equal(single_scattering_albedo(0, 0.2), 1)        # pure scatterer
  expect_equal(single_scattering_albedo(0.2, 0), 0)        # pure absorber
})

test_that("beam_attenuation always exceeds Kd (c > Kd)", {
  # Johnsen ch.5: c = a + b > a, and Kd ~ a-ish, so c > Kd. Sanity-level check.
  a <- 0.1; b <- 0.08
  expect_gt(beam_attenuation(a, b), a)
})

test_that("IOP helpers reject negative coefficients", {
  expect_error(beam_attenuation(-0.1, 0.05))
  expect_error(single_scattering_albedo(0.1, -0.05))
  expect_error(single_scattering_albedo(0, 0))
})

# ---- transmittance / absorbance -----------------------------------------

test_that("transmittance is Beer-Lambert exp(-c*L)", {
  expect_equal(transmittance(0.15, 10), exp(-1.5), tolerance = 1e-12)
  expect_equal(transmittance(0.1, 0), 1)                  # zero path
})

test_that("transmittance reproduces Johnsen's hatchetfish absorptance", {
  expect_equal(1 - transmittance(0.064, 10), 0.47, tolerance = 0.01)
  expect_equal(1 - transmittance(0.064, 75), 0.99, tolerance = 0.01)
})

test_that("absorbance inverts transmittance in both bases", {
  expect_equal(absorbance(exp(-1.5)), 1.5, tolerance = 1e-12)      # natural log
  expect_equal(absorbance(0.01, base = "10"), 2, tolerance = 1e-12) # OD
  # OD = A * log10(e) ~ 0.4343 * A
  A  <- absorbance(0.2, base = "e")
  OD <- absorbance(0.2, base = "10")
  expect_equal(OD, A * log10(exp(1)), tolerance = 1e-12)
})

test_that("absorbance rejects out-of-range transmittance", {
  expect_error(absorbance(0))
  expect_error(absorbance(1.2))
})

# ---- snells_window ------------------------------------------------------

test_that("snells_window half-angle is ~48.6 degrees for seawater", {
  expect_equal(snells_window(1.333), 48.6, tolerance = 0.1)
  expect_equal(snells_window(1.333), asin(1 / 1.333) * 180 / pi, tolerance = 1e-9)
})

test_that("snells_window narrows as refractive index rises", {
  expect_gt(snells_window(1.333), snells_window(1.5))
  expect_error(snells_window(1))
})

# ---- fresnel_reflectance ------------------------------------------------

test_that("fresnel_reflectance is ~2% at normal incidence (air->water)", {
  expect_equal(fresnel_reflectance(0), ((1.333 - 1) / (1.333 + 1))^2,
               tolerance = 1e-9)
  expect_equal(fresnel_reflectance(0), 0.0204, tolerance = 1e-2)
})

test_that("fresnel_reflectance increases toward grazing incidence", {
  expect_lt(fresnel_reflectance(0), fresnel_reflectance(60))
  expect_lt(fresnel_reflectance(60), fresnel_reflectance(85))
})

test_that("fresnel_reflectance: total internal reflection beyond the critical angle", {
  crit <- snells_window(1.333)               # ~48.6 degrees
  expect_lt(fresnel_reflectance(crit - 5, from = "water"), 1)
  expect_equal(fresnel_reflectance(crit + 5, from = "water"), 1)
  expect_equal(fresnel_reflectance(90, from = "water"), 1)
})

test_that("fresnel_reflectance is vectorised over angle", {
  r <- fresnel_reflectance(c(0, 30, 60))
  expect_length(r, 3)
  expect_true(all(r >= 0 & r <= 1))
})

# ---- surface_transmittance ----------------------------------------------

test_that("surface_transmittance direct is 1 - Fresnel reflectance", {
  expect_equal(surface_transmittance(angle = 0),
               1 - fresnel_reflectance(0), tolerance = 1e-12)
  expect_equal(surface_transmittance(angle = 0), 0.9796, tolerance = 1e-2)
  expect_error(surface_transmittance())          # angle required for 'direct'
})

test_that("surface_transmittance diffuse (isotropic sky) is ~0.93", {
  tau <- surface_transmittance(source = "diffuse")
  expect_equal(tau, 0.93, tolerance = 0.01)
  expect_true(tau > 0 && tau < 1)
  # sky-integrated transmittance is lower than at normal incidence (grazing loss)
  expect_lt(tau, surface_transmittance(angle = 0))
})

test_that("surface_transmittance direct decreases toward grazing incidence", {
  expect_gt(surface_transmittance(angle = 0), surface_transmittance(angle = 70))
  v <- surface_transmittance(angle = c(0, 30, 60))
  expect_length(v, 3)
  expect_true(all(v >= 0 & v <= 1))
})
