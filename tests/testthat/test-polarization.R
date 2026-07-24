library(luxR)

# ---- degree_of_polarization --------------------------------------------

test_that("degree_of_polarization matches sqrt(Q^2+U^2+V^2)/I", {
  expect_equal(degree_of_polarization(1, 0.4, 0), 0.4)
  expect_equal(degree_of_polarization(2, 0, 2), 1)
  expect_equal(degree_of_polarization(1, 0, 0), 0)
  expect_equal(degree_of_polarization(2, 1, 0), 0.5)
})

test_that("degree_of_polarization rejects non-positive I", {
  expect_error(
    degree_of_polarization(0, 1, 0),
    "must be greater than 0",
    class = "luxR_polarization_input_error"
  )
})

test_that("degree_of_polarization rejects non-physical Stokes states", {
  err <- expect_error(
    degree_of_polarization(I = 1, Q = 0.8, U = 0.8),
    "physically invalid",
    class = "luxR_polarization_physicality_error"
  )
  expect_equal(err$index, 1)
  expect_equal(err$operation, "degree_of_polarization")
  expect_true(all(c("model_version", "package_version", "code_commit",
                    "random_seed", "configuration") %in% names(err)))
})

test_that("Stokes validation is finite, typed, and length-safe", {
  expect_error(degree_of_polarization("1", 0, 0),
               class = "luxR_polarization_input_error")
  expect_error(degree_of_polarization(1, NA_real_, 0),
               class = "luxR_polarization_input_error")
  expect_error(degree_of_polarization(1, Inf, 0),
               class = "luxR_polarization_input_error")
  expect_error(degree_of_polarization(numeric(), 0, 0),
               class = "luxR_polarization_input_error")
  expect_error(
    degree_of_polarization(rep(1, 3), c(0.1, 0.2), 0),
    class = "luxR_polarization_length_error"
  )
  expect_equal(degree_of_polarization(c(1, 2), 0.5, 0), c(0.5, 0.25))
})

# ---- angle_of_polarization ---------------------------------------------

test_that("angle_of_polarization returns half-atan2 in (-90, 90]", {
  expect_equal(angle_of_polarization(1, 0), 0)
  expect_equal(angle_of_polarization(0, 1), 45)
  expect_equal(angle_of_polarization(-1, 0), 90)   # 0.5*atan2(0,-1)=90
  expect_equal(angle_of_polarization(0, -1), -45)
  expect_true(is.na(angle_of_polarization(0, 0)))
})

test_that("angle_of_polarization validates inputs and broadcasts scalars", {
  expect_equal(angle_of_polarization(c(1, 0), 1), c(22.5, 45))
  expect_error(angle_of_polarization(c(1, 0, -1), c(0, 1)),
               class = "luxR_polarization_length_error")
  expect_error(angle_of_polarization(NA_real_, 1),
               class = "luxR_polarization_input_error")
})

# ---- refracted_solar_angle ---------------------------------------------

test_that("refracted_solar_angle: 0 -> 0 and 90 -> Snell's window", {
  expect_equal(refracted_solar_angle(0), 0)
  expect_equal(refracted_solar_angle(90), snells_window(1.333), tolerance = 1e-9)
})

test_that("refracted_solar_angle rejects out-of-range zenith", {
  expect_error(refracted_solar_angle(120),
               class = "luxR_polarization_input_error")
  expect_error(refracted_solar_angle(30, n = 1),
               class = "luxR_polarization_input_error")
  expect_error(refracted_solar_angle(NA_real_),
               class = "luxR_polarization_input_error")
})

# ---- scattering_angle --------------------------------------------------

test_that("scattering_angle: known geometries", {
  # same direction -> 0
  expect_equal(scattering_angle(30, 10, 30, 10), 0, tolerance = 1e-9)
  # view horizontal, sun overhead -> 90
  expect_equal(scattering_angle(90, 0, 0, 0), 90, tolerance = 1e-9)
  # opposite azimuth at the horizon -> 180
  expect_equal(scattering_angle(90, 0, 90, 180), 180, tolerance = 1e-9)
})

test_that("scattering_angle validates geometry and vector lengths", {
  expect_error(scattering_angle(-1, 0, 30, 0),
               class = "luxR_polarization_input_error")
  expect_error(scattering_angle(30, 0, 181, 0),
               class = "luxR_polarization_input_error")
  expect_error(scattering_angle(1:3, 1:2, 30, 0),
               class = "luxR_polarization_length_error")
})

# ---- underwater_polarization -------------------------------------------

test_that("DoP is maximal at 90-degree scattering and near surface", {
  # sun overhead (refracted zenith 0), looking horizontally -> Theta = 90
  res <- underwater_polarization(view_zenith = 90, sun_zenith = 0,
                                 depth = 0, dop_max = 0.4)
  expect_equal(res$scattering_angle, 90, tolerance = 1e-9)
  expect_equal(res$dop, 0.4, tolerance = 1e-9)
})

test_that("DoP vanishes toward the sun", {
  # looking straight up at the overhead sun -> Theta = 0 -> dop_single = 0
  res <- underwater_polarization(view_zenith = 0, sun_zenith = 0, depth = 0)
  expect_equal(res$dop, 0, tolerance = 1e-9)
  expect_true(is.na(res$aop))   # e-vector undefined looking along the beam
})

test_that("DoP relaxes toward the asymptotic floor with depth", {
  shallow <- underwater_polarization(view_zenith = 90, sun_zenith = 0,
                                     depth = 0,    dop_max = 0.4, dop_asym = 0.03)$dop
  deep    <- underwater_polarization(view_zenith = 90, sun_zenith = 0,
                                     depth = 1000, dop_max = 0.4, dop_asym = 0.03)$dop
  expect_lt(deep, shallow)
  expect_equal(deep, 0.03, tolerance = 1e-3)
})

test_that("underwater_polarization is vectorised and bounded", {
  res <- underwater_polarization(view_zenith = seq(0, 90, 15),
                                 sun_zenith = 30, depth = 5)
  expect_equal(nrow(res), 7)
  expect_true(all(res$dop >= 0 & res$dop <= 1))
  expect_named(res, c("scattering_angle", "dop", "aop"))
})

test_that("underwater model records its uncalibrated status and parameters", {
  res <- underwater_polarization(90, sun_zenith = 0)
  metadata <- attr(res, "luxR.polarization", exact = TRUE)
  expect_equal(metadata$status, "uncalibrated_approximation")
  expect_false(metadata$quantitative_prediction)
  expect_equal(metadata$parameters$dop_max, 0.4)
  expect_match(metadata$model, "Rayleigh-like")
  expect_match(metadata$valid_domain, "requires calibration")
})

test_that("underwater model fails fast on invalid inputs and parameters", {
  invalid_calls <- list(
    function() underwater_polarization(NA_real_, sun_zenith = 0),
    function() underwater_polarization(181, sun_zenith = 0),
    function() underwater_polarization(90, sun_zenith = 91),
    function() underwater_polarization(90, sun_zenith = 0, depth = -1),
    function() underwater_polarization(90, sun_zenith = 0, dop_max = Inf),
    function() underwater_polarization(90, sun_zenith = 0, dop_asym = 0.5,
                                       dop_max = 0.4),
    function() underwater_polarization(90, sun_zenith = 0, z_p = 0),
    function() underwater_polarization(90, sun_zenith = 0, n = 1)
  )
  for (call in invalid_calls) {
    expect_error(call(), class = "luxR_polarization_input_error")
  }
  expect_error(
    underwater_polarization(1:3, view_azimuth = 1:2, sun_zenith = 0),
    class = "luxR_polarization_length_error"
  )
})

test_that("underwater model broadcasts only scalar geometry inputs", {
  res <- underwater_polarization(
    view_zenith = c(0, 45, 90), view_azimuth = 0,
    sun_zenith = 30, sun_azimuth = c(0, 45, 90), depth = 1
  )
  expect_equal(nrow(res), 3)
})

# ---- polarization_contrast ---------------------------------------------

test_that("identical polarization states give zero contrast", {
  r <- polarization_contrast(0.4, 30, 0.4, 30)
  expect_equal(r$delta_dop, 0)
  expect_equal(r$delta_aop, 0)
  expect_equal(r$distance, 0)
})

test_that("orthogonal e-vectors at equal DoP give maximal angular contrast", {
  r <- polarization_contrast(0.5, 0, 0.5, 90)   # 90 deg apart
  expect_equal(r$delta_aop, 90)
  expect_equal(r$distance, 1.0, tolerance = 1e-9)   # 2 * 0.5
})

test_that("polarized vs unpolarized distance equals the DoP", {
  r <- polarization_contrast(0.5, 20, 0, 0)
  expect_equal(r$distance, 0.5, tolerance = 1e-9)
})

test_that("angle-of-polarization difference is axial (period 180)", {
  # 170 deg vs 0 deg -> axial difference 10 deg, not 170
  r <- polarization_contrast(0.3, 170, 0.3, 0)
  expect_equal(r$delta_aop, 10, tolerance = 1e-9)
})

test_that("polarization_contrast validates states and lengths", {
  expect_error(polarization_contrast(1.1, 0, 0, 0),
               class = "luxR_polarization_input_error")
  expect_error(polarization_contrast(0.5, NA_real_, 0, 0),
               class = "luxR_polarization_input_error")
  expect_error(polarization_contrast(1:3 / 4, 1:2, 0, 0),
               class = "luxR_polarization_length_error")
  res <- polarization_contrast(c(0.2, 0.4), 0, 0.1, 90)
  expect_equal(nrow(res), 2)
})

# ---- fresnel_reflectance s/p components --------------------------------

test_that("fresnel components: unpolarized is the mean of s and p", {
  ang <- c(0, 30, 60)
  Rs <- fresnel_reflectance(ang, component = "s")
  Rp <- fresnel_reflectance(ang, component = "p")
  Ru <- fresnel_reflectance(ang, component = "unpolarized")
  expect_equal(Ru, 0.5 * (Rs + Rp))
  expect_equal(Rs[1], Rp[1], tolerance = 1e-12)   # equal at normal incidence
})

test_that("p-component nearly vanishes at Brewster's angle", {
  brewster <- atan(1.333) * 180 / pi            # ~53.1 deg
  expect_lt(fresnel_reflectance(brewster, component = "p"), 1e-6)
})
