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
  # with a flat unit spectrum, band E at z=0 is the band width in nm
  sub  <- band_irradiance(E0, Kd, lam, depths = 0, lambda_min = 500, lambda_max = 600)
  expect_equal(sub$E, 100, tolerance = 1e-10)
})

test_that("band_irradiance: full band with no limits equals PAR-range subset for PAR spectrum", {
  lam2  <- seq(400, 700, by = 10)
  E2    <- rep(1, length(lam2))
  Kd2   <- rep(0.05, length(lam2))
  full  <- band_irradiance(E2, Kd2, lam2, depths = 5)
  sub   <- band_irradiance(E2, Kd2, lam2, depths = 5,
                           lambda_min = 395, lambda_max = 705)
  expect_equal(full$E, sub$E, tolerance = 1e-10)
})

test_that("band_irradiance: matches manual attenuate_spectrum + sum", {
  depths <- c(0, 10, 25)
  mat    <- attenuate_spectrum(E0, Kd, depths = depths, format = "matrix")
  idx    <- lam >= 500 & lam <= 600
  manual <- colSums(mat[idx, ] * c(5, rep(10, 9), 5))  # edge bins half inside
  result <- band_irradiance(E0, Kd, lam, depths = depths,
                            lambda_min = 500, lambda_max = 600)
  expect_equal(result$E, manual, tolerance = 1e-10)
})

test_that("band_irradiance: photonic output matches par_irradiance for PAR band", {
  # with a full 400-700 nm input, photonic band_irradiance should equal par_irradiance
  E_z <- E0 * exp(-Kd * 10)           # manually attenuated spectrum at 10 m
  par <- par_irradiance(E_z, lam)
  bi  <- band_irradiance(E0, Kd, lam, depths = 10,
                         lambda_min = 400, lambda_max = 700,
                         photonic = TRUE, molar_unit = "umol")$E
  expect_equal(bi, par, tolerance = 1e-6)
})

test_that("band_irradiance: error when lambda_min >= lambda_max", {
  expect_error(band_irradiance(E0, Kd, lam, depths = 0,
                               lambda_min = 600, lambda_max = 500),
               class = "luxR_value_error")
})

test_that("band_irradiance: error when no wavelengths fall in range", {
  expect_error(band_irradiance(E0, Kd, lam, depths = 0,
                               lambda_min = 800, lambda_max = 900),
               class = "luxR_grid_error")
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

# ---- band-edge weighting ----------------------------------------------------

test_that(".band_widths: edge bins contribute only their overlap", {
  lam2 <- seq(390, 710, by = 10)
  w    <- luxR:::.band_widths(lam2, lo = 400, hi = 700, operation = "t()")
  expect_equal(w[lam2 == 390], 0)
  expect_equal(w[lam2 %in% c(400, 700)], c(5, 5))
  expect_equal(w[lam2 == 550], 10)
  expect_equal(sum(w), 300)
})

test_that(".band_widths: default band is the full bin extent", {
  expect_equal(luxR:::.band_widths(lam, operation = "t()"), rep(10, length(lam)))
})

test_that(".band_widths: rejects irregular, descending, uncovered and single-point grids", {
  bw <- function(...) luxR:::.band_widths(..., operation = "t()")
  expect_error(bw(c(400, 410, 430), lo = 400, hi = 430), class = "luxR_grid_error")
  expect_error(bw(c(700, 690, 680), lo = 680, hi = 700), class = "luxR_grid_error")
  expect_error(bw(seq(450, 700, by = 10), lo = 400, hi = 700), class = "luxR_grid_error")
  expect_error(bw(550, lo = 400, hi = 700), class = "luxR_value_error")
  expect_error(bw(lam, binwidth = 2, lo = 400, hi = 700), class = "luxR_grid_error")
  expect_error(bw(lam, lo = 600, hi = 500), class = "luxR_value_error")
  expect_equal(sum(bw(seq(450, 650, by = 10), lo = 400, hi = 700, cover = FALSE)), 210)
  expect_equal(bw(550, binwidth = 10, lo = 400, hi = 700, cover = FALSE), 10)
})

test_that("band_irradiance: a flat spectrum integrates to the band width", {
  lam2 <- seq(390, 710, by = 10)
  out  <- band_irradiance(rep(1, length(lam2)), rep(0.05, length(lam2)), lam2,
                          depths = 0, lambda_min = 400, lambda_max = 700)
  expect_equal(out$E, 300, tolerance = 1e-10)
})

test_that("band_irradiance: rejects a spectrum shorter than its wavelength grid", {
  expect_error(band_irradiance(1, Kd, lam, depths = 0),
               class = "luxR_dimension_error")
})

test_that(".band_widths: a descending grid is reported as not increasing", {
  # the old message said "the step ... is -10 nm, expected -10 nm"
  expect_error(luxR:::.band_widths(rev(lam), operation = "t()"),
               "strictly increasing; index 2 has value 690 after 700",
               class = "luxR_grid_error")
})
