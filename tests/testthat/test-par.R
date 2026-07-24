library(luxR)

# ---- par_irradiance --------------------------------------------------------

test_that("par_irradiance returns positive value for solar spectrum", {
  sp  <- solar_irradiance("clear_noon")
  par <- par_irradiance(sp$irradiance, sp$wavelength, binwidth = 10)
  expect_type(par, "double")
  expect_length(par, 1)
  expect_gt(par, 0)
})

test_that("par_irradiance clear_noon > overcast", {
  sp1 <- solar_irradiance("clear_noon")
  sp2 <- solar_irradiance("overcast")
  p1  <- par_irradiance(sp1$irradiance, sp1$wavelength, binwidth = 10)
  p2  <- par_irradiance(sp2$irradiance, sp2$wavelength, binwidth = 10)
  expect_gt(p1, p2)
})

test_that("par_irradiance returns realistic full-sun value", {
  sp  <- solar_irradiance("clear_noon")
  par <- par_irradiance(sp$irradiance, sp$wavelength, binwidth = 10)
  # Midday full-sun PAR is ~2000-2500 umol/m2/s (Johnsen, The Optics of Life,
  # ch.2/9; standard ocean-optics references). These bounds are tight enough
  # that a unit-scale slip (e.g. mol vs umol, or missing binwidth) would fail.
  expect_gt(par, 1900)
  expect_lt(par, 2600)
})

test_that("par_irradiance decreases with depth via attenuate_spectrum", {
  sp     <- solar_irradiance("clear_noon")
  lam    <- sp$wavelength
  E0     <- sp$irradiance
  Kd     <- jerlov_Kd("IA", lambda = lam, extrapolation = "constant")
  E50    <- attenuate_spectrum(E0, Kd, depths = 50, lambda = lam,
                               format = "matrix")[, 1]
  par0   <- par_irradiance(E0,  lam, binwidth = 10)
  par50  <- par_irradiance(E50, lam, binwidth = 10)
  expect_gt(par0, par50)
})

test_that("par_irradiance photonic = TRUE works with Naples data", {
  lam <- Naples$wv
  E   <- Naples$depth_0m
  par <- par_irradiance(E, lam, photonic = TRUE)
  expect_gt(par, 0)
})

test_that("par_irradiance: umol lux_spectrum returns same value as direct sum", {
  # Naples is in umol/m2/s/nm; PAR = sum of PAR-window bins * binwidth
  expected <- sum(Naples$depth_0m[Naples$wv >= 400 & Naples$wv <= 700]) * 5
  x_umol   <- lux_spectrum(Naples$depth_0m, Naples$wv, "irradiance", "umol/m2/s/nm")
  expect_equal(par_irradiance(x_umol), expected, tolerance = 1e-6)
})

test_that("par_irradiance errors when no wavelengths in PAR range", {
  expect_error(par_irradiance(c(1, 2), c(800, 900)), "PAR range")
})

test_that("par_irradiance infers binwidth from lambda spacing", {
  sp   <- solar_irradiance("clear_noon")
  par1 <- par_irradiance(sp$irradiance, sp$wavelength, binwidth = 10)
  par2 <- par_irradiance(sp$irradiance, sp$wavelength)
  expect_equal(par1, par2, tolerance = 1e-6)
})

# ---- par_fraction ----------------------------------------------------------

test_that("par_fraction is in (0, 1) for solar spectrum", {
  sp <- solar_irradiance("clear_noon")
  f  <- par_fraction(sp$irradiance, sp$wavelength)
  expect_gt(f, 0)
  expect_lt(f, 1)
})

test_that("par_fraction of underwater spectrum is higher than noon surface", {
  sp1 <- solar_irradiance("clear_noon")
  sp2 <- solar_irradiance("underwater_10m")
  f1  <- par_fraction(sp1$irradiance, sp1$wavelength)
  f2  <- par_fraction(sp2$irradiance, sp2$wavelength)
  # Underwater spectrum is mostly PAR (UV filtered out)
  expect_gt(f2, f1)
})

test_that("par_fraction of all-PAR spectrum is 1", {
  lam <- seq(400, 700, by = 10)
  E   <- rep(1, length(lam))
  expect_equal(par_fraction(E, lam), 1)
})
