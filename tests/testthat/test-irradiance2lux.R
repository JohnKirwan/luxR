library(luxR)

test_that("irradiance2lux is silent by default", {
  irr <- c(0.5, 1.0, 0.5)
  lam <- c(545, 555, 565)
  expect_silent(irradiance2lux(irr, lam))
})

test_that("irradiance2lux emits messages when verbose = TRUE", {
  irr <- c(0.5, 1.0, 0.5)
  lam <- c(545, 555, 565)
  expect_message(irradiance2lux(irr, lam, verbose = TRUE))
})

test_that("irradiance2lux uses K_m = 683 not 637", {
  # Official CIE V(555) is exactly one, so a 10 nm bin contributes 6830 lx.
  result <- irradiance2lux(1, 555, total = TRUE, binwidth = 10)
  expect_equal(result, 683 * 10)
})

test_that("irradiance2lux linearly interpolates the luminous efficiency", {
  expected <- mean(CIE1931$W[CIE1931$lambda %in% c(545, 546)])
  result <- irradiance2lux(1, 545.5, total = TRUE, binwidth = 1)
  expect_equal(result, 683 * expected)
})

test_that("irradiance2lux assigns zero weight outside the LEF range", {
  result <- vapply(c(300, 555, 900), function(lambda) {
    irradiance2lux(1, lambda, total = FALSE, binwidth = 1)
  }, numeric(1))
  expect_equal(result, c(0, 683, 0))
})

test_that("irradiance2lux interpolates an irregular custom LEF", {
  LEF <- data.frame(lambda = c(400, 430, 500), W = c(0, 0.6, 1))
  result <- irradiance2lux(1, 415, total = TRUE, LEF = LEF, binwidth = 1)
  expect_equal(result, 683 * 0.3)
})

test_that("irradiance2lux rejects malformed luminous efficiency functions", {
  expect_error(
    irradiance2lux(1, 500, LEF = data.frame(lambda = 500)),
    class = "lux_lef_validation_error"
  )
  expect_error(
    irradiance2lux(1, 500,
                   LEF = data.frame(lambda = c(500, 490), W = c(1, 0.5))),
    class = "lux_lef_validation_error"
  )
  expect_error(
    irradiance2lux(1, 500,
                   LEF = data.frame(lambda = c(490, 500), W = c(0.5, NA))),
    class = "lux_lef_validation_error"
  )
})

test_that("irradiance2lux applies molar conversion for umol input", {
  # If molar conversion works, umol input (6.022e17 photons per umol)
  # must produce a larger watt value than raw photon input.
  lx_photon <- irradiance2lux(Naples$depth_0m, Naples$wv,
                               photonic = TRUE, molar_unit = "photons")
  lx_umol   <- irradiance2lux(Naples$depth_0m, Naples$wv,
                               photonic = TRUE, molar_unit = "umol")
  # umol -> photons multiplies by ~6.022e17, so lx_umol >> lx_photon
  expect_gt(lx_umol, lx_photon * 1e10)
})

test_that("irradiance2lux total = FALSE returns vector", {
  irr <- c(1, 2, 1)
  lam <- c(545, 555, 565)
  result <- irradiance2lux(irr, lam, total = FALSE)
  expect_length(result, 3)
})

test_that("irradiance2lux infers bin width from a regular wavelength grid", {
  irr <- rep(1, 3)

  inferred_5nm <- irradiance2lux(irr, c(545, 550, 555))
  explicit_5nm <- irradiance2lux(irr, c(545, 550, 555), binwidth = 5)
  inferred_1nm <- irradiance2lux(irr, c(553, 554, 555))
  explicit_1nm <- irradiance2lux(irr, c(553, 554, 555), binwidth = 1)

  expect_equal(inferred_5nm, explicit_5nm)
  expect_equal(inferred_1nm, explicit_1nm)
})

test_that("irradiance2lux requires an explicit width for one wavelength", {
  expect_error(
    irradiance2lux(1, 555),
    "required for a single-bin",
    class = "lux_spectrum_grid_error"
  )
  expect_equal(
    irradiance2lux(1, 555, binwidth = 1),
    683
  )
})

test_that("irradiance2lux requires explicit trapezoidal integration for irregular grids", {
  expect_error(
    irradiance2lux(c(1, 1, 1), c(500, 510, 525)),
    "regularly spaced",
    class = "lux_spectrum_grid_error"
  )
  expect_error(
    irradiance2lux(c(1, 1, 1), c(500, 510, 525), binwidth = 10,
                   integration = "trapezoid"),
    "must be NULL",
    class = "lux_spectrum_grid_error"
  )
  expect_error(
    irradiance2lux(c(1, 1, 1), c(500, 510, 520), binwidth = 5),
    "must match",
    class = "lux_spectrum_grid_error"
  )
})

test_that("irradiance2lux integrates irregular grids by the trapezoidal rule", {
  lam <- c(500, 510, 530)
  irr <- c(1, 2, 4)
  constant_LEF <- data.frame(lambda = c(490, 540), W = c(1, 1))

  contributions <- irradiance2lux(
    irr, lam, LEF = constant_LEF, integration = "trapezoid", total = FALSE
  )

  # Composite trapezoid weights are 5, 15, and 10 nm. Equivalently,
  # interval areas are (1 + 2) / 2 * 10 + (2 + 4) / 2 * 20 = 75.
  expect_equal(contributions, 683 * c(5, 30, 40))
  expect_equal(sum(contributions), 683 * 75)
  expect_equal(
    irradiance2lux(irr, lam, LEF = constant_LEF,
                   integration = "trapezoid"),
    sum(contributions)
  )
})

test_that("trapezoidal integration covers only the measured interval", {
  lam <- c(500, 510, 520)
  constant_LEF <- data.frame(lambda = c(490, 530), W = c(1, 1))

  rectangle <- irradiance2lux(rep(1, 3), lam, LEF = constant_LEF)
  trapezoid <- irradiance2lux(rep(1, 3), lam, LEF = constant_LEF,
                              integration = "trapezoid")

  expect_equal(rectangle, 683 * 30)
  expect_equal(trapezoid, 683 * 20)
})

test_that("trapezoidal integration validates grid boundaries", {
  invalid_calls <- list(
    function() irradiance2lux(1, 500, integration = "trapezoid"),
    function() irradiance2lux(c(1, 1), 500,
                              integration = "trapezoid"),
    function() irradiance2lux(c("1", "1"), c(500, 510),
                              integration = "trapezoid"),
    function() irradiance2lux(c(1, Inf), c(500, 510),
                              integration = "trapezoid"),
    function() irradiance2lux(c(1, 1), c(500, 500),
                              integration = "trapezoid"),
    function() irradiance2lux(c(1, 1), c(510, 500),
                              integration = "trapezoid"),
    function() irradiance2lux(c(1, 1), c(500, NA),
                              integration = "trapezoid"),
    function() irradiance2lux(c(1, -1), c(500, 510),
                              integration = "trapezoid")
  )

  for (call in invalid_calls) {
    expect_error(call(), class = "lux_spectrum_validation_error")
  }
})

test_that("trapezoidal integration converts photons before weighting", {
  lam <- c(500, 510, 530)
  photons <- c(1e15, 2e15, 1e15)
  energy <- photon2W(photons, lam)

  expect_equal(
    irradiance2lux(photons, lam, photonic = TRUE,
                   integration = "trapezoid"),
    irradiance2lux(energy, lam, integration = "trapezoid"),
    tolerance = 1e-12
  )
})

test_that("lux_spectrum supports explicit trapezoidal integration", {
  spectrum <- lux_spectrum(c(1, 2, 1), c(500, 510, 520))

  expect_equal(
    irradiance2lux(spectrum, integration = "trapezoid"),
    irradiance2lux(spectrum$E, spectrum$lambda,
                   integration = "trapezoid")
  )
})

test_that("irradiance2lux_FUN rejects mismatched internal shapes", {
  expect_error(
    luxR:::irradiance2lux_FUN(
      W_spec_irradiance = 1,
      lambda_measured = c(500, 510),
      integration_weights = c(5, 5)
    ),
    "equal length",
    class = "lux_spectrum_value_error"
  )
})

test_that("irradiance2lux validates numeric spectrum boundaries", {
  invalid_calls <- list(
    function() irradiance2lux(numeric(), numeric()),
    function() irradiance2lux(c("1", "2"), c(500, 510)),
    function() irradiance2lux(c(1, 2), c("500", "510")),
    function() irradiance2lux(c(1, 2), 500),
    function() irradiance2lux(c(1, NA), c(500, 510)),
    function() irradiance2lux(c(1, Inf), c(500, 510)),
    function() irradiance2lux(c(1, -1), c(500, 510)),
    function() irradiance2lux(c(1, 1), c(500, NA)),
    function() irradiance2lux(c(1, 1), c(510, 500)),
    function() irradiance2lux(c(1, 1), c(500, 500)),
    function() irradiance2lux(c(1, 1), c(500, 510), binwidth = 0),
    function() irradiance2lux(c(1, 1), c(500, 510), binwidth = Inf)
  )

  for (call in invalid_calls) {
    expect_error(call(), class = "lux_spectrum_validation_error")
  }
})

test_that("photometric integration accepts only irradiance spectra", {
  lam <- c(545, 555, 565)
  energy <- lux_spectrum(c(1, 2, 1), lam,
                         quantity = "irradiance", unit = "W/m2/nm")

  expect_no_error(irradiance2lux(energy))
  expect_no_error(scotopic_lux(energy))

  invalid <- list(
    lux_spectrum(c(1, 2, 1), lam,
                 quantity = "radiance", unit = "W/m2/sr/nm"),
    lux_spectrum(c(1, 2, 1), lam,
                 quantity = "radiance", unit = "umol/m2/s/sr/nm"),
    lux_spectrum(c(0.1, 0.2, 0.1), lam,
                 quantity = "reflectance", unit = "dimensionless")
  )

  for (spectrum in invalid) {
    expect_error(
      irradiance2lux(spectrum),
      "requires spectral irradiance",
      class = "lux_spectrum_dimension_error"
    )
    expect_error(
      scotopic_lux(spectrum),
      "requires spectral irradiance",
      class = "lux_spectrum_dimension_error"
    )
  }
})

test_that("photonic irradiance spectra are converted to energy before integration", {
  lam <- c(545, 555, 565)
  energy <- lux_spectrum(c(1, 2, 1), lam,
                         quantity = "irradiance", unit = "W/m2/nm")
  expected_photopic <- irradiance2lux(energy)
  expected_scotopic <- scotopic_lux(energy)

  for (unit in c("umol/m2/s/nm", "mmol/m2/s/nm", "mol/m2/s/nm")) {
    photonic <- convert_unit(energy, unit)
    expect_equal(irradiance2lux(photonic), expected_photopic,
                 tolerance = 1e-10)
    expect_equal(scotopic_lux(photonic), expected_scotopic,
                 tolerance = 1e-10)
  }
})
