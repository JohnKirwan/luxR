library(luxR)

# Literature-consistency benchmark, not a calibration dataset.
# Cronin TW, Shashar N (2001), J Exp Biol 204:2461-2467.
# DOI: 10.1242/jeb.204.14.2461
# Observation domain: clear tropical reef water, 15 m, 350-600 nm.

test_that("Rayleigh-like angular maximum is consistent with field pattern", {
  theta <- seq(0, 180, by = 1)
  result <- underwater_polarization(
    view_zenith = theta,
    view_azimuth = 0,
    sun_zenith = 0,
    depth = 15
  )
  maximum_angle <- result$scattering_angle[which.max(result$dop)]

  # Cronin & Shashar report the greatest polarization 60-90 degrees from the
  # sun. This checks only that qualitative angular pattern.
  expect_gte(maximum_angle, 60)
  expect_lte(maximum_angle, 90)
})

test_that("literature benchmark cannot be mistaken for calibration", {
  result <- underwater_polarization(
    view_zenith = 90,
    sun_zenith = 0,
    depth = 15
  )
  metadata <- attr(result, "luxR.polarization", exact = TRUE)

  expect_equal(metadata$evidence$doi, "10.1242/jeb.204.14.2461")
  expect_match(metadata$evidence$observation_domain, "15 m")
  expect_match(metadata$evidence$benchmark, "not calibration")
  expect_equal(metadata$status, "uncalibrated_approximation")
  expect_false(metadata$quantitative_prediction)

  # The illustrative defaults predict about 0.205 at this geometry and depth,
  # below the roughly 0.25-0.40 maxima reported in the paper. Encoding this
  # known mismatch prevents qualitative agreement from becoming a quantitative
  # claim without a separately reviewed calibration.
  expect_lt(result$dop, 0.25)
})
