library(luxR)

# Cross-validation: luxR's energy <-> photon conversion against the photobiology
# package's e2quantum_multipliers(). Both rest on n(lambda) = E * lambda / (h c),
# so the per-photon conversion must agree to machine precision. photobiology is a
# Suggests dependency, so these tests skip when it is absent.

test_that("W2photon matches photobiology (energy -> photon count)", {
  skip_if_not_installed("photobiology")
  lam <- seq(300, 800, by = 5)
  expect_equal(W2photon(1, lam),
               photobiology::e2quantum_multipliers(lam, molar = FALSE),
               tolerance = 1e-9)
})

test_that("photon2W is the inverse, matching photobiology", {
  skip_if_not_installed("photobiology")
  lam <- seq(300, 800, by = 5)
  expect_equal(photon2W(1, lam),
               1 / photobiology::e2quantum_multipliers(lam, molar = FALSE),
               tolerance = 1e-9)
})

test_that("molar energy -> photon agrees with photobiology", {
  skip_if_not_installed("photobiology")
  lam <- seq(300, 800, by = 5)
  avogadro <- 6.02214076e23
  # Differs only by the value of Avogadro's number each package uses, hence the
  # looser tolerance than the per-photon-count check above.
  expect_equal(W2photon(1, lam) / avogadro,
               photobiology::e2quantum_multipliers(lam, molar = TRUE),
               tolerance = 1e-6)
})

# photobiology::illuminance() currently selects a different observer curve.
# Build matched response spectra explicitly so this benchmark isolates the
# independent spectral multiplication and integration implementation.
photobiology_weighted_illuminance <- function(irradiance, lambda, LEF,
                                               luminous_efficacy) {
  sensitivity <- stats::approx(
    LEF$lambda,
    LEF$W,
    xout = lambda,
    rule = 1
  )$y
  if (anyNA(sensitivity)) {
    stop("Benchmark wavelengths must remain inside the supplied CIE table.")
  }

  source <- photobiology::source_spct(
    w.length = lambda,
    s.e.irrad = irradiance
  )
  response <- photobiology::response_spct(
    w.length = lambda,
    s.e.response = sensitivity
  )

  as.numeric(photobiology::response(
    source * response,
    unit.out = "energy"
  )) * luminous_efficacy
}

reference_spectra <- function(lambda) {
  list(
    flat = rep(1, length(lambda)),
    blue = stats::dnorm(lambda, mean = 450, sd = 25),
    green = stats::dnorm(lambda, mean = 530, sd = 35),
    red = stats::dnorm(lambda, mean = 650, sd = 30)
  )
}

test_that("photopic integration matches photobiology on reference spectra", {
  skip_if_not_installed("photobiology")
  lambda <- CIE1931$lambda
  spectra <- reference_spectra(lambda)

  for (label in names(spectra)) {
    irradiance <- spectra[[label]]
    expected <- photobiology_weighted_illuminance(
      irradiance, lambda, CIE1931, luminous_efficacy = 683
    )
    expect_equal(
      irradiance2lux(irradiance, lambda, integration = "trapezoid"),
      expected,
      tolerance = 1e-10,
      info = label
    )
  }
})

test_that("scotopic integration matches photobiology on reference spectra", {
  skip_if_not_installed("photobiology")
  lambda <- CIE_scotopic$lambda
  spectra <- reference_spectra(lambda)

  for (label in names(spectra)) {
    irradiance <- spectra[[label]]
    expected <- photobiology_weighted_illuminance(
      irradiance, lambda, CIE_scotopic, luminous_efficacy = 1700
    )
    expect_equal(
      scotopic_lux(irradiance, lambda, integration = "trapezoid"),
      expected,
      tolerance = 1e-10,
      info = label
    )
  }
})

test_that("irregular photometric integration matches photobiology", {
  skip_if_not_installed("photobiology")
  lambda <- c(380, 397, 430, 489, 507, 555, 612, 700, 780)
  irradiance <- 0.2 + exp(-((lambda - 520) / 70)^2)

  expected_photopic <- photobiology_weighted_illuminance(
    irradiance, lambda, CIE1931, luminous_efficacy = 683
  )
  expected_scotopic <- photobiology_weighted_illuminance(
    irradiance, lambda, CIE_scotopic, luminous_efficacy = 1700
  )

  expect_equal(
    irradiance2lux(irradiance, lambda, integration = "trapezoid"),
    expected_photopic,
    tolerance = 1e-10
  )
  expect_equal(
    scotopic_lux(irradiance, lambda, integration = "trapezoid"),
    expected_scotopic,
    tolerance = 1e-10
  )
})

test_that("Naples photometry matches photobiology after energy conversion", {
  skip_if_not_installed("photobiology")
  keep <- Naples$wv >= 380 & Naples$wv <= 780
  lambda <- Naples$wv[keep]
  photon_irradiance <- Naples$depth_5m[keep]
  energy_irradiance <- n2W_spec_irradiance(
    photon_irradiance,
    lambda,
    photonic = TRUE,
    molar_unit = "umol"
  )

  expect_equal(
    irradiance2lux(
      photon_irradiance,
      lambda,
      photonic = TRUE,
      molar_unit = "umol",
      integration = "trapezoid"
    ),
    photobiology_weighted_illuminance(
      energy_irradiance, lambda, CIE1931, luminous_efficacy = 683
    ),
    tolerance = 1e-10
  )
  expect_equal(
    scotopic_lux(
      photon_irradiance,
      lambda,
      photonic = TRUE,
      molar_unit = "umol",
      integration = "trapezoid"
    ),
    photobiology_weighted_illuminance(
      energy_irradiance, lambda, CIE_scotopic, luminous_efficacy = 1700
    ),
    tolerance = 1e-10
  )
})
