test_that("W2mol_spec_irradiance: round-trips with n2W_spec_irradiance (umol)", {
  lambda <- c(400, 500, 600)
  W      <- c(1e-3, 2e-3, 3e-3)
  umol   <- W2mol_spec_irradiance(W, lambda, molar_unit = "umol")
  W_back <- n2W_spec_irradiance(umol, lambda, photonic = TRUE, molar_unit = "umol")
  expect_equal(W_back, W, tolerance = 1e-10)
})

test_that("W2mol_spec_irradiance: round-trips with n2W_spec_irradiance (mol)", {
  lambda <- c(400, 500, 600)
  W      <- c(1e-3, 2e-3, 3e-3)
  mol    <- W2mol_spec_irradiance(W, lambda, molar_unit = "mol")
  W_back <- n2W_spec_irradiance(mol, lambda, photonic = TRUE, molar_unit = "mol")
  expect_equal(W_back, W, tolerance = 1e-10)
})

test_that("W2mol_spec_irradiance: round-trips with W2photon / photon2W", {
  lambda <- seq(400, 700, by = 50)
  W      <- rep(1e-3, length(lambda))
  umol   <- W2mol_spec_irradiance(W, lambda, molar_unit = "umol")
  photon_n <- W2photon(W, lambda)
  expect_equal(umol * 6.02214076e17, photon_n, tolerance = 1e-10)
})

test_that("W2mol_spec_irradiance: default molar_unit is umol", {
  lambda <- c(500)
  W      <- 1e-3
  expect_equal(W2mol_spec_irradiance(W, lambda),
               W2mol_spec_irradiance(W, lambda, molar_unit = "umol"))
})

test_that("W2mol_spec_irradiance: umol > mmol > mol for same W", {
  lambda <- 550
  W      <- 1e-3
  expect_gt(W2mol_spec_irradiance(W, lambda, "umol"),
            W2mol_spec_irradiance(W, lambda, "mmol"))
  expect_gt(W2mol_spec_irradiance(W, lambda, "mmol"),
            W2mol_spec_irradiance(W, lambda, "mol"))
})

test_that("W2mol_spec_irradiance: vectorised over lambda and W", {
  lambda <- c(400, 500, 600)
  W      <- c(1e-4, 2e-4, 3e-4)
  result <- W2mol_spec_irradiance(W, lambda)
  expect_length(result, 3L)
  expect_true(all(result > 0))
})

test_that("W2mol_spec_irradiance: radiance preserves steradian and W scale", {
  lambda <- c(400, 500, 600)
  W      <- c(1e-3, 2e-3, 3e-3)
  x      <- lux_spectrum(W, lambda, "radiance", "W/m2/sr/nm")

  photons <- W2mol_spec_irradiance(x, molar_unit = "umol")
  expect_equal(photons$unit, "umol/m2/s/sr/nm")
  expect_equal(photons$quantity, "radiance")
  expect_equal(photons$E, W2mol_spec_irradiance(W, lambda, "umol"),
               tolerance = 1e-12)
})

test_that("W2mol_spec_irradiance: mW radiance applies the 1e-3 scale", {
  lambda <- 500
  x_mW   <- lux_spectrum(1, lambda, "radiance", "mW/m2/sr/nm")
  x_W    <- lux_spectrum(1e-3, lambda, "radiance", "W/m2/sr/nm")

  result <- W2mol_spec_irradiance(x_mW, molar_unit = "mol")
  expect_equal(result$unit, "mol/m2/s/sr/nm")
  expect_equal(result$E, W2mol_spec_irradiance(x_W, molar_unit = "mol")$E,
               tolerance = 1e-12)
})

test_that("radiance photon conversion round-trips values and dimensions", {
  lambda <- c(400, 500, 600)
  for (energy_unit in c("W/m2/sr/nm", "mW/m2/sr/nm")) {
    x <- lux_spectrum(c(1, 2, 3), lambda, "radiance", energy_unit)
    photons <- W2mol_spec_irradiance(x, molar_unit = "umol")
    back <- n2W_spec_irradiance(photons)
    expect_equal(back$quantity, "radiance")
    expect_equal(back$unit, "W/m2/sr/nm")
    expected <- if (energy_unit == "mW/m2/sr/nm") x$E * 1e-3 else x$E
    expect_equal(back$E, expected, tolerance = 1e-12)
  }
})
