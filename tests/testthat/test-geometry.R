library(luxR)

# ---- irradiance2radiance ------------------------------------------------

test_that("irradiance2radiance lambertian gives E/pi", {
  expect_equal(irradiance2radiance(pi), 1)
  expect_equal(irradiance2radiance(c(pi, 2*pi)), c(1, 2))
})

test_that("irradiance2radiance collimated returns E unchanged", {
  expect_equal(irradiance2radiance(5, geometry = "collimated"), 5)
})

test_that("irradiance2radiance custom requires solid_angle", {
  expect_error(irradiance2radiance(10, geometry = "custom"))
})

test_that("irradiance2radiance custom divides by solid_angle", {
  expect_equal(irradiance2radiance(10, geometry = "custom", solid_angle = 2), 5)
})

test_that("irradiance2radiance validates values and geometry parameters", {
  expect_error(irradiance2radiance(c(1, Inf)), class = "lux_detection_error")
  expect_error(irradiance2radiance(-1), class = "lux_detection_error")
  expect_error(
    irradiance2radiance(1, geometry = "custom", solid_angle = 4 * pi + 0.1),
    class = "lux_detection_error"
  )
  expect_error(
    irradiance2radiance(1, geometry = "lambertian", solid_angle = 1),
    class = "lux_detection_error"
  )
})

# ---- radiance2irradiance ------------------------------------------------

test_that("radiance2irradiance lambertian gives L*pi", {
  expect_equal(radiance2irradiance(1), pi)
  expect_equal(radiance2irradiance(c(1, 2)), c(pi, 2*pi))
})

test_that("radiance2irradiance collimated returns L unchanged", {
  expect_equal(radiance2irradiance(5, geometry = "collimated"), 5)
})

test_that("radiance2irradiance custom requires solid_angle", {
  expect_error(radiance2irradiance(10, geometry = "custom"))
})

test_that("radiance2irradiance custom multiplies by solid_angle", {
  expect_equal(radiance2irradiance(5, geometry = "custom", solid_angle = 2), 10)
})

test_that("radiance2irradiance validates values and geometry parameters", {
  expect_error(radiance2irradiance(NA_real_), class = "lux_detection_error")
  expect_error(radiance2irradiance(-1), class = "lux_detection_error")
  expect_error(
    radiance2irradiance(1, geometry = "custom", solid_angle = 0),
    class = "lux_detection_error"
  )
  expect_error(
    radiance2irradiance(1, geometry = "scalar", solid_angle = 1),
    class = "lux_detection_error"
  )
})

# ---- round-trips --------------------------------------------------------

test_that("irradiance2radiance and radiance2irradiance round-trip (lambertian)", {
  E <- 42.7
  expect_equal(radiance2irradiance(irradiance2radiance(E)), E, tolerance = 1e-10)
})

test_that("irradiance2radiance and radiance2irradiance round-trip (custom)", {
  E  <- 100
  sr <- 1.5
  expect_equal(
    radiance2irradiance(irradiance2radiance(E, "custom", sr), "custom", sr),
    E, tolerance = 1e-10
  )
})

# ---- scalar irradiance geometry -----------------------------------------

test_that("irradiance2radiance scalar: L = E / (2*pi)", {
  E <- 2 * pi * 5
  expect_equal(irradiance2radiance(E, "scalar"), 5)
})

test_that("radiance2irradiance scalar: E = 2*pi*L", {
  L <- 3
  expect_equal(radiance2irradiance(L, "scalar"), 2 * pi * L)
})

test_that("scalar round-trips: irradiance -> radiance -> irradiance", {
  E <- c(1, 10, 100)
  expect_equal(radiance2irradiance(irradiance2radiance(E, "scalar"), "scalar"), E)
})

test_that("scalar irradiance is 2x the planar (vector) irradiance for isotropic L", {
  # Johnsen, The Optics of Life ch.2: planar/vector irradiance is cosine-weighted
  # (pi*L over a hemisphere); scalar irradiance is not (2*pi*L). They are
  # DIFFERENT physical quantities, not two flavours of the same measurement.
  L <- 10
  expect_equal(radiance2irradiance(L, "scalar"),     2 * pi * L)
  expect_equal(radiance2irradiance(L, "lambertian"),      pi * L)
  expect_equal(radiance2irradiance(L, "scalar"),
               radiance2irradiance(L, "lambertian") * 2)
})

test_that("irradiance2radiance scalar is vectorised", {
  E <- c(2 * pi, 4 * pi, 6 * pi)
  expect_equal(irradiance2radiance(E, "scalar"), c(1, 2, 3))
})

test_that("the removed 'hemisphere' geometry is rejected", {
  expect_error(irradiance2radiance(1, "hemisphere"))
  expect_error(radiance2irradiance(1, "hemisphere"))
})
