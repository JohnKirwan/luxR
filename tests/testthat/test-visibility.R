library(luxR)

# ---- secchi_depth ----------------------------------------------------------

test_that("secchi_depth returns positive value", {
  Kd <- jerlov_Kd("IA", lambda = 550)
  expect_gt(secchi_depth(Kd), 0)
})

test_that("secchi_depth is inversely proportional to Kd", {
  expect_equal(secchi_depth(0.1), 1.7 / 0.1)
  expect_equal(secchi_depth(0.05), 1.7 / 0.05)
})

test_that("secchi_depth clearer water gives deeper Secchi", {
  Kd_I  <- jerlov_Kd("I",  lambda = 490)
  Kd_C2 <- jerlov_Kd("C2", lambda = 490)
  expect_gt(secchi_depth(Kd_I), secchi_depth(Kd_C2))
})

test_that("secchi_depth with lambda and irradiance uses PAR-weighted Kd", {
  sp  <- solar_irradiance("clear_noon")
  lam <- sp$wavelength
  Kd  <- jerlov_Kd("IA", lambda = lam, extrapolation = "constant")
  zsd_spectral <- secchi_depth(Kd, lambda = lam, irradiance = sp$irradiance)
  zsd_scalar   <- secchi_depth(mean(Kd))
  # Both give positive, finite depths; they won't be equal
  expect_gt(zsd_spectral, 0)
  expect_true(is.finite(zsd_spectral))
  expect_false(isTRUE(all.equal(zsd_spectral, zsd_scalar)))
})

test_that("secchi_depth vectorises over Kd values", {
  Kd  <- c(0.1, 0.2, 0.5)
  zsd <- secchi_depth(Kd)
  expect_length(zsd, 3)
  expect_true(all(zsd > 0))
  expect_true(all(diff(zsd) < 0))   # increasing Kd -> decreasing Secchi
})

# ---- visual_range ----------------------------------------------------------

test_that("visual_range returns positive value", {
  Kd <- jerlov_Kd("IA", lambda = 490)
  expect_gt(visual_range(Kd), 0)
})

test_that("visual_range clearer water gives longer range", {
  vr_I  <- visual_range(jerlov_Kd("I",  lambda = 490))
  vr_C2 <- visual_range(jerlov_Kd("C2", lambda = 490))
  expect_gt(vr_I, vr_C2)
})

test_that("visual_range higher contrast threshold gives longer range", {
  Kd <- 0.06
  vr_strict <- visual_range(Kd, contrast_threshold = 0.01)
  vr_loose  <- visual_range(Kd, contrast_threshold = 0.10)
  expect_gt(vr_strict, vr_loose)
})

test_that("visual_range formula: -log(Ct) / (Kd * kd_to_c)", {
  Kd <- 0.06
  Ct <- 0.02
  f  <- 1.5
  expect_equal(visual_range(Kd, Ct, f), -log(Ct) / (Kd * f))
})

test_that("visual_range vectorises over Kd", {
  vr <- visual_range(c(0.05, 0.10, 0.20))
  expect_length(vr, 3)
  expect_true(all(diff(vr) < 0))
})

test_that("visual_range rejects invalid attenuation and thresholds", {
  invalid_calls <- list(
    function() visual_range(0),
    function() visual_range(-0.1),
    function() visual_range(NA_real_),
    function() visual_range(0.1, contrast_threshold = 0),
    function() visual_range(0.1, contrast_threshold = 1),
    function() visual_range(0.1, beam_c = Inf)
  )
  for (call in invalid_calls) {
    expect_error(call(), class = "luxR_value_error")
  }
})

test_that("visual_range respects c > Kd: ignoring it overestimates range", {
  # Johnsen, The Optics of Life ch.5: beam attenuation c (not Kd) governs
  # sighting distance, and c > Kd always. So treating c = Kd (kd_to_c = 1) is
  # an upper bound; any physical c/Kd > 1 must shorten the range.
  Kd <- 0.06
  range_floor_c <- visual_range(Kd, kd_to_c = 1)     # c == Kd (unphysical max)
  range_clear   <- visual_range(Kd, kd_to_c = 1.3)   # clear oceanic
  range_coastal <- visual_range(Kd, kd_to_c = 3.0)   # turbid coastal
  expect_gt(range_floor_c, range_clear)
  expect_gt(range_clear,   range_coastal)
})

test_that("visual_range uses a measured beam_c directly, ignoring kd_to_c", {
  expect_equal(visual_range(0.06, beam_c = 0.2), -log(0.02) / 0.2)
  expect_equal(visual_range(0.06, kd_to_c = 99, beam_c = 0.2),
               visual_range(0.06, beam_c = 0.2))
  # supplying beam_c = Kd*kd_to_c reproduces the proxy result
  expect_equal(visual_range(0.06, beam_c = 0.06 * 1.5),
               visual_range(0.06, kd_to_c = 1.5))
})

test_that("Jerlov provenance does not leak into scalar visibility results", {
  Kd <- jerlov_Kd("IA", lambda = 490)

  expect_null(attr(secchi_depth(Kd), "luxR.jerlov", exact = TRUE))
  expect_null(attr(visual_range(Kd), "luxR.jerlov", exact = TRUE))
  expect_null(attr(
    contrast_at_distance(1, 10, Kd), "luxR.jerlov", exact = TRUE
  ))
})

test_that("secchi_depth weights the half-width edge bins by their overlap", {
  lam <- seq(400, 700, by = 10)
  Kd  <- rep(0.1, length(lam))
  Kd[c(1, length(lam))] <- 1
  w <- rep(10, length(lam))
  w[c(1, length(lam))] <- 5
  expect_equal(secchi_depth(Kd, lam, rep(1, length(lam)), basis = "energy"),
               1.7 / (sum(Kd * w) / sum(w)))
})

test_that("secchi_depth weights by photons by default", {
  lam <- seq(400, 700, by = 10)
  Kd  <- 0.05 + (lam - 400) / 1000
  E   <- rep(1, length(lam))              # flat energy spectrum
  w   <- rep(10, length(lam))
  w[c(1, length(lam))] <- 5
  photon <- 1.7 / (sum(Kd * lam * w) / sum(lam * w))
  energy <- 1.7 / (sum(Kd * w) / sum(w))
  expect_equal(secchi_depth(Kd, lam, E), photon)
  expect_equal(secchi_depth(Kd, lam, E, basis = "energy"), energy)
  # Photon-unit input: flat photon flux is used as given for photons and
  # divided by lambda for energy.
  expect_equal(secchi_depth(Kd, lam, E, photonic = TRUE), energy)
  expect_equal(secchi_depth(Kd, lam, E, photonic = TRUE, basis = "energy"),
               1.7 / (sum(Kd * w / lam) / sum(w / lam)))
})

test_that("secchi_depth gives the same answer for any lux_spectrum unit and basis", {
  x  <- from_naples("0m")
  Kd <- rep(0.1, length(x$lambda)) + x$lambda / 1e4
  w  <- convert_unit(x, "W/m2/nm")
  for (b in c("photon", "energy")) {
    expect_equal(secchi_depth(Kd, spectrum = x, basis = b),
                 secchi_depth(Kd, spectrum = w, basis = b))
  }
  expect_equal(secchi_depth(Kd, spectrum = w),
               secchi_depth(Kd, w$lambda, w$E))
})

test_that("secchi_depth rejects invalid photonic and basis", {
  lam <- seq(400, 700, by = 10)
  E   <- rep(1, 31)
  expect_error(secchi_depth(rep(0.1, 31), lam, E, photonic = NA),
               class = "luxR_type_error")
  expect_error(secchi_depth(rep(0.1, 31), lam, E, basis = "quanta"))
  x <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  expect_error(secchi_depth(rep(0.1, 31), spectrum = x, photonic = TRUE),
               class = "luxR_value_error")
})

test_that("secchi_depth rejects invalid input", {
  lam <- seq(400, 700, by = 10)
  E   <- rep(1, 31)
  expect_error(secchi_depth(0), class = "luxR_value_error")
  expect_error(secchi_depth(NA_real_), class = "luxR_value_error")
  expect_error(secchi_depth(rep(0.1, 3), lam, E),
               class = "luxR_dimension_error")
  expect_error(secchi_depth(rep(0.1, 31), lam), class = "luxR_value_error")
  expect_error(secchi_depth(rep(0.1, 31), lam, rep(0, 31)),
               class = "luxR_value_error")
  expect_error(secchi_depth(rep(0.1, 31), lam, c(-1, E[-1])),
               class = "luxR_value_error")
  r <- lux_spectrum(E, lam, "radiance", "W/m2/sr/nm")
  expect_error(secchi_depth(rep(0.1, 31), spectrum = r),
               class = "luxR_dimension_error")
  expect_error(secchi_depth(rep(0.1, 31), spectrum = E),
               class = "luxR_type_error")
})
