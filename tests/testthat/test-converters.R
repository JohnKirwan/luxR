library(luxR)

# ---- photon2W / W2photon ------------------------------------------------

test_that("photon2W and W2photon are exact inverses", {
  n   <- 1e15
  lam <- 550
  expect_equal(W2photon(photon2W(n, lam), lam), n, tolerance = 1e-10)
  expect_equal(photon2W(W2photon(1, lam), lam), 1, tolerance = 1e-10)
})

test_that("photon2W gives correct energy at 555 nm", {
  # E_photon = hc/lambda = 1.98644585714893e-16 / 555 nm = 3.579e-19 J
  expect_equal(photon2W(1, 555), 1.98644585714893e-16 / 555, tolerance = 1e-10)
})

test_that("photon2W and W2photon are vectorised", {
  lam <- c(400, 500, 600)
  n   <- c(1e14, 1e15, 1e16)
  W   <- photon2W(n, lam)
  expect_length(W, 3)
  expect_equal(W2photon(W, lam), n, tolerance = 1e-10)
})

# ---- ft2m / m2ft --------------------------------------------------------

test_that("ft2m and m2ft are exact inverses", {
  expect_equal(m2ft(ft2m(100)), 100, tolerance = 1e-10)
  expect_equal(ft2m(m2ft(30)),  30,  tolerance = 1e-10)
})

test_that("ft2m(1) equals 0.3048", {
  expect_equal(ft2m(1), 0.3048)
})

test_that("ft2m and m2ft are vectorised and pass through NA", {
  x <- c(10, NA, 30)
  expect_true(is.na(ft2m(x)[2]))
  expect_true(is.na(m2ft(x)[2]))
  expect_length(ft2m(x), 3)
})

# ---- scotopic_lux -------------------------------------------------------

test_that("scotopic_lux is silent by default", {
  irr <- c(1, 1, 1)
  lam <- c(490, 510, 530)
  expect_silent(scotopic_lux(irr, lam))
})

test_that("scotopic_lux returns a positive scalar", {
  irr <- c(1, 1, 1)
  lam <- c(490, 510, 530)
  result <- scotopic_lux(irr, lam)
  expect_true(is.numeric(result) && length(result) == 1 && result > 0)
})

test_that("scotopic_lux is larger than photopic lux for blue-shifted spectrum", {
  # Scotopic sensitivity peaks at 507 nm, photopic at 555 nm.
  # A spectrum centred at 490 nm should produce higher scotopic lux.
  irr <- c(10, 10, 0)
  lam <- c(470, 490, 510)
  expect_gt(scotopic_lux(irr, lam), irradiance2lux(irr, lam))
})

test_that("scotopic_lux total = FALSE returns vector", {
  irr <- c(1, 1, 1)
  lam <- c(490, 510, 530)
  result <- scotopic_lux(irr, lam, total = FALSE)
  expect_length(result, 3)
})

test_that("scotopic_lux infers regular bin width and requires singleton width", {
  irr <- c(1, 2, 1)
  lam <- c(500, 505, 510)

  expect_equal(
    scotopic_lux(irr, lam),
    scotopic_lux(irr, lam, binwidth = 5)
  )
  expect_error(
    scotopic_lux(1, 505),
    "required for a single-bin",
    class = "lux_spectrum_grid_error"
  )
  expect_error(
    scotopic_lux(c("1", "2"), c(500, 505)),
    class = "lux_spectrum_type_error"
  )
})

test_that("scotopic_lux interpolates and assigns zero outside its LEF range", {
  result <- vapply(c(300, 505, 800), function(lambda) {
    scotopic_lux(1, lambda, total = FALSE, binwidth = 1)
  }, numeric(1))
  expected_505 <- 1700 * CIE_scotopic$W[CIE_scotopic$lambda == 505]
  expect_equal(result, c(0, expected_505, 0))
})

test_that("scotopic_lux uses the CIE peak efficacy at 507 nm", {
  expect_equal(scotopic_lux(1, 507, binwidth = 1), 1700)
})

test_that("scotopic_lux supports irregular trapezoidal integration", {
  irr <- c(1, 2, 1)
  lam <- c(490, 505, 530)

  expect_equal(
    scotopic_lux(irr, lam, integration = "trapezoid"),
    irradiance2lux(irr, lam, LEF = CIE_scotopic,
                   integration = "trapezoid") * (1700 / 683)
  )
})

# ---- lux2irradiance -----------------------------------------------------

test_that("lux2irradiance round-trips with irradiance2lux", {
  # Build a simple spectrum; compute lux; invert back; re-compute lux.
  irr <- CIE1931$W          # use V(lambda) shape as reference
  lam <- CIE1931$lambda
  lx  <- irradiance2lux(irr, lam)
  irr_back <- lux2irradiance(lx, spectrum = data.frame(lambda = lam,
                                                        irradiance = irr))
  lx_back  <- irradiance2lux(irr_back, lam)
  expect_equal(lx_back, lx, tolerance = 1e-6)
})

test_that("lux2irradiance infers non-10-nm grids for round trips", {
  lam <- seq(500, 600, by = 5)
  irr <- stats::approx(CIE1931$lambda, CIE1931$W, xout = lam)$y
  spec <- data.frame(lambda = lam, irradiance = irr)
  target <- irradiance2lux(irr, lam)

  recovered <- lux2irradiance(target, spec)

  expect_equal(irradiance2lux(recovered, lam), target, tolerance = 1e-8)
})

test_that("lux2irradiance round-trips an irregular reference shape", {
  lam <- c(500, 510, 525, 550)
  irr <- c(0.2, 0.8, 1, 0.3)
  target <- irradiance2lux(irr, lam, integration = "trapezoid")

  recovered <- lux2irradiance(
    target, irr, lambda = lam, integration = "trapezoid"
  )

  expect_equal(
    irradiance2lux(recovered, lam, integration = "trapezoid"),
    target,
    tolerance = 1e-8
  )
})

test_that("lux2irradiance scales output proportionally to input lux", {
  irr  <- CIE1931$W
  lam  <- CIE1931$lambda
  spec <- data.frame(lambda = lam, irradiance = irr)
  out1 <- lux2irradiance(1000, spec)
  out2 <- lux2irradiance(2000, spec)
  expect_equal(out2, out1 * 2, tolerance = 1e-10)
})

test_that("lux2irradiance accepts bare vector as spectrum arg", {
  irr  <- CIE1931$W
  lam  <- CIE1931$lambda
  out  <- lux2irradiance(500, spectrum = irr, lambda = lam)
  expect_length(out, length(irr))
  expect_true(all(out > 0))
})

# ---- broadband2spectrum -------------------------------------------------

test_that("broadband2spectrum lx unit round-trips", {
  irr  <- CIE1931$W
  lam  <- CIE1931$lambda
  spec <- data.frame(wavelength = lam, irradiance = irr)
  result <- broadband2spectrum(500, unit = "lx", spectrum = spec)
  expect_s3_class(result, "data.frame")
  expect_named(result, c("wavelength", "irradiance"))
  lx_check <- irradiance2lux(result$irradiance, result$wavelength)
  expect_equal(lx_check, 500, tolerance = 0.01)
})

test_that("broadband2spectrum W unit scales correctly", {
  lam  <- seq(400, 700, by = 10)
  irr  <- rep(1, length(lam))
  spec <- data.frame(wavelength = lam, irradiance = irr)
  result <- broadband2spectrum(150, unit = "W", spectrum = spec)
  total_W <- sum(result$irradiance) * 10   # binwidth 10 nm
  expect_equal(total_W, 150, tolerance = 0.01)
})

test_that("broadband2spectrum attaches assumption attribute", {
  lam  <- seq(400, 700, by = 10)
  irr  <- rep(1, length(lam))
  spec <- data.frame(wavelength = lam, irradiance = irr)
  result <- broadband2spectrum(100, unit = "W", spectrum = spec)
  assump <- attr(result, "luxR.assumption")
  expect_false(is.null(assump))
  expect_equal(assump$input_value, 100)
  expect_equal(assump$input_unit, "W")
})

test_that("broadband2spectrum umol unit is positive", {
  lam  <- seq(400, 700, by = 10)
  irr  <- rep(1, length(lam))
  spec <- data.frame(wavelength = lam, irradiance = irr)
  result <- broadband2spectrum(500, unit = "umol", spectrum = spec)
  expect_true(all(result$irradiance > 0))
})

test_that("broadband2spectrum umol round-trips with par_irradiance", {
  sp     <- solar_irradiance("clear_noon")
  target <- 500
  result <- broadband2spectrum(target, unit = "umol", spectrum = sp)
  recovered <- par_irradiance(result$irradiance, result$wavelength)
  expect_equal(recovered, target, tolerance = 1e-6)
})

test_that("broadband2spectrum applies water attenuation when water_type supplied", {
  lam  <- seq(400, 700, by = 10)
  irr  <- rep(1, length(lam))
  spec <- data.frame(wavelength = lam, irradiance = irr)
  r_surface <- broadband2spectrum(500, unit = "W", spectrum = spec)
  r_depth   <- broadband2spectrum(500, unit = "W", spectrum = spec,
                                  water_type = "IA", depth = 20)
  # With depth attenuation applied to the reference shape, the rescale factor
  # will differ between the two — shape at depth ≠ shape at surface.
  k_surface <- attr(r_surface, "luxR.assumption")$rescale_factor
  k_depth   <- attr(r_depth,   "luxR.assumption")$rescale_factor
  expect_false(isTRUE(all.equal(k_surface, k_depth)))
})

test_that("broadband2spectrum requires an explicit out-of-range policy", {
  spectrum <- data.frame(
    wavelength = seq(300, 800, by = 10),
    irradiance = rep(1, 51)
  )
  expect_error(
    broadband2spectrum(
      500, unit = "W", spectrum = spectrum, water_type = "IA", depth = 10
    ),
    class = "luxR_jerlov_range_error"
  )

  trimmed <- broadband2spectrum(
    500, unit = "W", spectrum = spectrum, water_type = "IA", depth = 10,
    wavelength_policy = "trim"
  )
  expect_identical(range(trimmed$wavelength), c(350, 700))
  trim_metadata <- attr(trimmed, "luxR.assumption")$jerlov
  expect_identical(trim_metadata$wavelength_policy, "trim")
  expect_identical(trim_metadata$trimmed_wavelength_count, 15L)

  extended <- broadband2spectrum(
    500, unit = "W", spectrum = spectrum, water_type = "IA", depth = 10,
    wavelength_policy = "constant"
  )
  expect_identical(range(extended$wavelength), c(300, 800))
  extension_metadata <- attr(extended, "luxR.assumption")$jerlov
  expect_identical(extension_metadata$extrapolation, "constant")
  expect_true(extension_metadata$extrapolated)
})

# ---- wavelength_in_medium --------------------------------------------------

test_that("wavelength_in_medium: seawater (n=1.336) shortens 500 nm correctly", {
  expect_equal(wavelength_in_medium(500, n = 1.336), 500 / 1.336, tolerance = 1e-10)
})

test_that("wavelength_in_medium: n=1 (vacuum) is identity", {
  lam <- c(400, 500, 600)
  expect_equal(wavelength_in_medium(lam, n = 1), lam)
})

test_that("wavelength_in_medium: vectorised over lambda", {
  lam    <- c(400, 500, 600)
  result <- wavelength_in_medium(lam, n = 1.5)
  expect_equal(result, lam / 1.5, tolerance = 1e-10)
})

test_that("wavelength_in_medium: errors when n < 1", {
  expect_error(wavelength_in_medium(500, n = 0.9), "n.*must be")
})
