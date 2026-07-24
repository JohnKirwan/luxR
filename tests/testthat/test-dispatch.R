# tests/testthat/test-dispatch.R
library(luxR)

lam <- seq(400, 700, by = 10)
E   <- rep(1, length(lam))
x   <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")

# ---- par_irradiance ----------------------------------------------------

test_that("par_irradiance: lux_spectrum matches numeric path", {
  expected <- par_irradiance(E, lam)
  result   <- par_irradiance(x)
  expect_equal(result, expected, tolerance = 1e-10)
})

test_that("par_irradiance: umol lux_spectrum returns correct µmol/m2/s value", {
  x_mol    <- lux_spectrum(Naples$depth_0m, Naples$wv,
                           "irradiance", "umol/m2/s/nm")
  # Correct expected: direct integral of the photon-flux spectrum
  expected <- sum(Naples$depth_0m[Naples$wv >= 400 & Naples$wv <= 700]) * 5
  result   <- par_irradiance(x_mol)
  expect_equal(result, expected, tolerance = 1e-8)
})

# ---- par_fraction ------------------------------------------------------

test_that("par_fraction: lux_spectrum matches numeric path", {
  expected <- par_fraction(E, lam)
  result   <- par_fraction(x)
  expect_equal(result, expected, tolerance = 1e-10)
})

# ---- irradiance2lux ----------------------------------------------------

test_that("irradiance2lux: lux_spectrum matches numeric path", {
  expected <- irradiance2lux(E, lam, binwidth = 10)
  result   <- irradiance2lux(x)
  expect_equal(result, expected, tolerance = 1e-8)
})

test_that("irradiance2lux: photonic lux_spectrum (umol) matches numeric path", {
  x_mol    <- lux_spectrum(Naples$depth_0m, Naples$wv,
                           "irradiance", "umol/m2/s/nm")
  bw       <- mean(diff(Naples$wv))   # 5 nm
  expected <- irradiance2lux(Naples$depth_0m, Naples$wv,
                             photonic = TRUE, molar_unit = "umol",
                             binwidth = bw)
  result   <- irradiance2lux(x_mol)
  expect_equal(result, expected, tolerance = 1e-8)
})

# ---- scotopic_lux ------------------------------------------------------

test_that("scotopic_lux: lux_spectrum matches numeric path", {
  expected <- scotopic_lux(E, lam, binwidth = 10)
  result   <- scotopic_lux(x)
  expect_equal(result, expected, tolerance = 1e-8)
})

# ---- secchi_depth ------------------------------------------------------

test_that("secchi_depth: lux_spectrum matches numeric irradiance-weighted path", {
  sp  <- solar_irradiance("clear_noon")
  Kd  <- jerlov_Kd(
    "II", lambda = sp$wavelength, extrapolation = "constant"
  )
  expected <- secchi_depth(Kd, lambda = sp$wavelength, irradiance = sp$irradiance)
  sx  <- lux_spectrum(sp$irradiance, sp$wavelength, "irradiance", "W/m2/nm")
  result <- secchi_depth(Kd, spectrum = sx)
  expect_equal(result, expected, tolerance = 1e-10)
})

# ---- attenuate_spectrum ------------------------------------------------

test_that("attenuate_spectrum: lux_spectrum returns named list of lux_spectrum", {
  Kd  <- rep(0.05, length(lam))
  res <- attenuate_spectrum(x, Kd, depths = c(0, 10))
  expect_type(res, "list")
  expect_equal(length(res), 2L)
  expect_true(all(vapply(res, inherits, logical(1), "lux_spectrum")))
})

test_that("attenuate_spectrum: lux_spectrum E matches numeric matrix path", {
  Kd   <- rep(0.05, length(lam))
  res  <- attenuate_spectrum(x, Kd, depths = 10)
  mat  <- attenuate_spectrum(E, Kd, depths = 10, format = "matrix")
  expect_equal(res[["10"]]$E, mat[, 1], tolerance = 1e-10)
})

test_that("attenuate_spectrum: each result has meta$depth set", {
  Kd  <- rep(0.05, length(lam))
  res <- attenuate_spectrum(x, Kd, depths = c(5, 20))
  expect_equal(res[["5"]]$meta$depth,  5)
  expect_equal(res[["20"]]$meta$depth, 20)
})

# ---- propagate_spectrum ------------------------------------------------

test_that("propagate_spectrum: lux_spectrum returns named list of lux_spectrum", {
  Kd  <- rep(0.05, length(lam))
  res <- propagate_spectrum(x, Kd, from = 0, to = c(0, 10))
  expect_type(res, "list")
  expect_true(all(vapply(res, inherits, logical(1), "lux_spectrum")))
})

test_that("propagate_spectrum: lux_spectrum E matches numeric matrix path", {
  Kd  <- rep(0.05, length(lam))
  res <- propagate_spectrum(x, Kd, from = 0, to = 10)
  mat <- propagate_spectrum(E, Kd, from = 0, to = 10, format = "matrix")
  expect_equal(res[["10"]]$E, mat[, 1], tolerance = 1e-10)
})

# ---- fit_Kd ------------------------------------------------------------

test_that("fit_Kd: two lux_spectrum objects match numeric path", {
  Kd    <- rep(0.05, length(lam))
  E2    <- E * exp(-Kd * 10)
  x2    <- lux_spectrum(E2, lam)
  expected <- fit_Kd(E, 0, E2, 10)
  result   <- fit_Kd(x, 0, x2, 10)
  expect_equal(result, expected, tolerance = 1e-10)
})

# ---- band_irradiance ---------------------------------------------------

test_that("band_irradiance: lux_spectrum matches numeric path", {
  Kd       <- rep(0.05, length(lam))
  expected <- band_irradiance(E, Kd, lam, depths = c(0, 10))
  result   <- band_irradiance(x, Kd, depths = c(0, 10))
  expect_equal(result$E, expected$E, tolerance = 1e-10)
})

test_that("band_irradiance: lux_spectrum passes lambda_min/lambda_max through", {
  Kd       <- rep(0.05, length(lam))
  expected <- band_irradiance(E, Kd, lam, depths = 5,
                              lambda_min = 500, lambda_max = 600)
  result   <- band_irradiance(x, Kd, depths = 5,
                              lambda_min = 500, lambda_max = 600)
  expect_equal(result$E, expected$E, tolerance = 1e-10)
})

# ---- n2W_spec_irradiance -----------------------------------------------

test_that("n2W_spec_irradiance: lux_spectrum (umol) returns W/m2/nm lux_spectrum", {
  x_mol  <- lux_spectrum(Naples$depth_0m, Naples$wv,
                         "irradiance", "umol/m2/s/nm")
  result <- n2W_spec_irradiance(x_mol)
  expect_s3_class(result, "lux_spectrum")
  expect_equal(result$unit, "W/m2/nm")
})

test_that("n2W_spec_irradiance: lux_spectrum E matches numeric path", {
  x_mol    <- lux_spectrum(Naples$depth_0m, Naples$wv,
                           "irradiance", "umol/m2/s/nm")
  expected <- n2W_spec_irradiance(Naples$depth_0m, Naples$wv,
                                   photonic = TRUE, molar_unit = "umol")
  result   <- n2W_spec_irradiance(x_mol)
  expect_equal(result$E, expected, tolerance = 1e-10)
})

test_that("n2W_spec_irradiance: errors when unit is already energy-based", {
  expect_error(n2W_spec_irradiance(x), "[Pp]hotonic")
})

# ---- W2mol_spec_irradiance ---------------------------------------------

test_that("W2mol_spec_irradiance: lux_spectrum (W/m2/nm) returns umol lux_spectrum", {
  result <- W2mol_spec_irradiance(x, molar_unit = "umol")
  expect_s3_class(result, "lux_spectrum")
  expect_equal(result$unit, "umol/m2/s/nm")
})

test_that("W2mol_spec_irradiance: lux_spectrum E matches numeric path", {
  expected <- W2mol_spec_irradiance(E, lam, molar_unit = "umol")
  result   <- W2mol_spec_irradiance(x, molar_unit = "umol")
  expect_equal(result$E, expected, tolerance = 1e-10)
})

test_that("W2mol_spec_irradiance: errors when unit is already photonic", {
  x_mol <- lux_spectrum(Naples$depth_0m, Naples$wv,
                        "irradiance", "umol/m2/s/nm")
  expect_error(W2mol_spec_irradiance(x_mol), "[Ee]nergy|[Pp]hotonic")
})

# ---- reflectance_to_radiance -------------------------------------------

test_that("reflectance_to_radiance: two lux_spectrum inputs return lux_spectrum", {
  refl  <- lux_spectrum(rep(0.5, length(lam)), lam,
                        quantity = "reflectance", unit = "dimensionless")
  illum <- lux_spectrum(E, lam, quantity = "irradiance", unit = "W/m2/nm")
  result <- reflectance_to_radiance(refl, illum)
  expect_s3_class(result, "lux_spectrum")
  expect_equal(result$quantity, "radiance")
  expect_equal(result$unit, "W/m2/sr/nm")
  expect_equal(result$E, refl$E * illum$E / pi)
})

test_that("reflectance_to_radiance: irradiance uses Lambertian conversion", {
  refl_v <- rep(0.5, length(lam))
  illum_v <- E
  refl   <- lux_spectrum(refl_v, lam,
                         quantity = "reflectance", unit = "dimensionless")
  illum  <- lux_spectrum(illum_v, lam, "irradiance", "W/m2/nm")
  result   <- reflectance_to_radiance(refl, illum)
  expect_equal(result$E, refl_v * illum_v / pi, tolerance = 1e-10)
  expect_equal(result$unit, "W/m2/sr/nm")
})

test_that("reflectance_to_radiance: radiance input retains values and unit", {
  refl <- lux_spectrum(rep(0.5, length(lam)), lam,
                       quantity = "reflectance", unit = "dimensionless")
  illum <- lux_spectrum(E, lam, "radiance", "W/m2/sr/nm")
  result <- reflectance_to_radiance(refl, illum)
  expect_equal(result$E, refl$E * illum$E)
  expect_equal(result$unit, illum$unit)
})

test_that("reflectance_to_radiance: errors when reflectance quantity is wrong", {
  not_refl <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  illum    <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  expect_error(reflectance_to_radiance(not_refl, illum), "[Rr]eflectance")
})

test_that("reflectance_to_radiance: errors on mismatched lambda grids", {
  refl  <- lux_spectrum(rep(0.5, length(lam)), lam,
                        "reflectance", "dimensionless")
  illum <- lux_spectrum(rep(1, length(lam)), lam + 1,
                        "irradiance", "W/m2/nm")
  expect_error(reflectance_to_radiance(refl, illum), "[Ll]ambda")
})
