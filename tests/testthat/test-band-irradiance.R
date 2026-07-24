lam  <- seq(400, 700, by = 10)
E0   <- rep(1, length(lam))          # flat 1 W/m²/nm surface spectrum
Kd   <- rep(0.05, length(lam))       # uniform Kd

test_that("band_irradiance: returns data.frame with depth and E columns", {
  result <- band_irradiance(E0, Kd, lam, depths = c(0, 10))
  expect_s3_class(result, "data.frame")
  expect_true(all(c("depth", "E") %in% names(result)))
  expect_equal(nrow(result), 2L)
})

test_that("band_irradiance: at depth 0, E equals full-band integral of E0", {
  result <- band_irradiance(E0, Kd, lam, depths = 0)
  bw <- mean(diff(lam))
  expect_equal(result$E, sum(E0) * bw, tolerance = 1e-10)
})

test_that("band_irradiance: E decreases monotonically with depth", {
  result <- band_irradiance(E0, Kd, lam, depths = c(0, 10, 25, 50))
  expect_true(all(diff(result$E) < 0))
})

test_that("band_irradiance: wavelength subsetting reduces E vs full band", {
  full  <- band_irradiance(E0, Kd, lam, depths = 10)
  sub   <- band_irradiance(E0, Kd, lam, depths = 10, lambda_min = 500, lambda_max = 600)
  expect_lt(sub$E, full$E)
})

test_that("band_irradiance: band subset integrates the correct wavelengths only", {
  # with flat spectrum and uniform Kd, band E at z=0 = n_bins * binwidth * E0[1]
  sub  <- band_irradiance(E0, Kd, lam, depths = 0, lambda_min = 500, lambda_max = 600)
  bw   <- mean(diff(lam))
  n_bins <- sum(lam >= 500 & lam <= 600)
  expect_equal(sub$E, n_bins * bw, tolerance = 1e-10)
})

test_that("band_irradiance: full band with no limits equals PAR-range subset for PAR spectrum", {
  lam2  <- seq(400, 700, by = 10)
  E2    <- rep(1, length(lam2))
  Kd2   <- rep(0.05, length(lam2))
  full  <- band_irradiance(E2, Kd2, lam2, depths = 5)
  sub   <- band_irradiance(E2, Kd2, lam2, depths = 5,
                           lambda_min = 400, lambda_max = 700)
  expect_equal(full$E, sub$E, tolerance = 1e-10)
})

test_that("band_irradiance: matches manual attenuate_spectrum + sum", {
  depths <- c(0, 10, 25)
  mat    <- attenuate_spectrum(E0, Kd, depths = depths, format = "matrix")
  bw     <- mean(diff(lam))
  idx    <- lam >= 500 & lam <= 600
  manual <- colSums(mat[idx, ]) * bw
  result <- band_irradiance(E0, Kd, lam, depths = depths,
                            lambda_min = 500, lambda_max = 600)
  expect_equal(result$E, manual, tolerance = 1e-10)
})

test_that("band_irradiance: photonic output matches par_irradiance for PAR band", {
  # with a full 400-700 nm input, photonic band_irradiance should equal par_irradiance
  E_z <- E0 * exp(-Kd * 10)           # manually attenuated spectrum at 10 m
  par <- par_irradiance(E_z, lam)
  bi  <- band_irradiance(E0, Kd, lam, depths = 10,
                         photonic = TRUE, molar_unit = "umol")$E
  expect_equal(bi, par, tolerance = 1e-6)
})

test_that("band_irradiance: error when lambda_min >= lambda_max", {
  expect_error(band_irradiance(E0, Kd, lam, depths = 0,
                               lambda_min = 600, lambda_max = 500),
               "lambda_min")
})

test_that("band_irradiance: error when no wavelengths fall in range", {
  expect_error(band_irradiance(E0, Kd, lam, depths = 0,
                               lambda_min = 800, lambda_max = 900),
               "[Nn]o wavelength")
})

# ---- from parameter (bidirectional) ----------------------------------------

test_that("band_irradiance: from=0 gives same result as default", {
  r1 <- band_irradiance(E0, Kd, lam, depths = 10)
  r2 <- band_irradiance(E0, Kd, lam, depths = 10, from = 0)
  expect_equal(r1$E, r2$E)
})

test_that("band_irradiance: round-trip surface -> depth -> surface recovers original", {
  depths_target <- c(0, 5, 10, 20)
  # propagate down, then recover surface from each depth
  down <- band_irradiance(E0, Kd, lam, depths = depths_target)
  for (i in seq_len(nrow(down))) {
    z     <- down$depth[i]
    E_z   <- E0 * exp(-Kd * z)           # spectrum at depth z
    up    <- band_irradiance(E_z, Kd, lam, depths = 0, from = z)
    surf  <- band_irradiance(E0, Kd, lam, depths = 0)
    expect_equal(up$E, surf$E, tolerance = 1e-8)
  }
})

test_that("band_irradiance: from one depth to another matches manual propagation", {
  z1   <- 5
  z2   <- 20
  E_z1 <- E0 * exp(-Kd * z1)
  manual <- band_irradiance(E_z1, Kd, lam, depths = z2)       # from surface equiv
  result <- band_irradiance(E0,   Kd, lam, depths = z2, from = 0)
  # both should agree: E at z2 starting from known spectrum at z1
  direct <- band_irradiance(E_z1, Kd, lam, depths = z2, from = z1)
  expect_equal(direct$E, result$E, tolerance = 1e-8)
})

test_that("band_irradiance: E increases when propagating upward (from > depth)", {
  z_deep  <- 20
  E_deep  <- E0 * exp(-Kd * z_deep)
  result  <- band_irradiance(E_deep, Kd, lam,
                             depths = c(20, 10, 5, 0), from = z_deep)
  expect_true(all(diff(result$E) > 0))  # shallower = brighter
})
