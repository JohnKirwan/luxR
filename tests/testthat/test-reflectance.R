test_that("reflectance_to_radiance: uniform reflectance scales illuminant proportionally", {
  illuminant   <- c(10, 20, 30)
  reflectance  <- c(0.5, 0.5, 0.5)
  lambda       <- c(400, 500, 600)
  result <- reflectance_to_radiance(reflectance, illuminant, lambda)
  expect_equal(unname(result), illuminant * reflectance)
})

test_that("reflectance_to_radiance: zero reflectance gives zero radiance", {
  illuminant  <- c(5, 10, 15)
  reflectance <- c(0, 0, 0)
  lambda      <- c(400, 500, 600)
  expect_equal(unname(reflectance_to_radiance(reflectance, illuminant, lambda)),
               rep(0, 3))
})

test_that("reflectance_to_radiance: full reflectance returns illuminant unchanged", {
  illuminant  <- c(5, 10, 15)
  reflectance <- c(1, 1, 1)
  lambda      <- c(400, 500, 600)
  expect_equal(unname(reflectance_to_radiance(reflectance, illuminant, lambda)),
               illuminant)
})

test_that("reflectance_to_radiance: returns numeric vector of same length", {
  n           <- 10
  illuminant  <- runif(n, 0, 100)
  reflectance <- runif(n, 0, 1)
  lambda      <- seq(400, 400 + (n - 1) * 10, by = 10)
  result <- reflectance_to_radiance(reflectance, illuminant, lambda)
  expect_length(result, n)
  expect_type(result, "double")
})

test_that("reflectance_to_radiance: error when lengths differ", {
  expect_error(
    reflectance_to_radiance(c(0.5, 0.5), c(10, 20, 30), c(400, 500, 600)),
    "length"
  )
})

test_that("reflectance_to_radiance: error when reflectance outside [0,1]", {
  expect_error(
    reflectance_to_radiance(c(0.5, 1.5), c(10, 20), c(400, 500)),
    "[Rr]eflectance"
  )
})

test_that("reflectance_to_radiance: result names match lambda", {
  illuminant  <- c(5, 10, 15)
  reflectance <- c(0.2, 0.4, 0.6)
  lambda      <- c(400, 500, 600)
  result <- reflectance_to_radiance(reflectance, illuminant, lambda)
  expect_named(result, as.character(lambda))
})
