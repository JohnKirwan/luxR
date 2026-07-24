library(luxR)

# Converters bridging lux_spectrum <-> pavo rspec. pavo is a Suggests
# dependency, so these tests skip when it is absent.

test_that("as_rspec() turns a lux_spectrum into a valid pavo rspec", {
  skip_if_not_installed("pavo")
  lam <- 400:700
  x <- lux_spectrum(E = sin(lam / 50) + 2, lambda = lam,
                    quantity = "irradiance", unit = "W/m2/nm")
  r <- as_rspec(x, name = "test")
  expect_true(pavo::is.rspec(r))
  expect_equal(names(r), c("wl", "test"))
  expect_equal(range(r$wl), c(400, 700))
})

test_that("as_rspec() names the column from metadata when name is NULL", {
  skip_if_not_installed("pavo")
  x <- from_solar("clear_noon")          # meta$source == "ASTM G173-03"
  r <- as_rspec(x)
  expect_equal(names(r)[2], "ASTM G173-03")
})

test_that("as_rspec() merges a list of lux_spectrum into a multi-column rspec", {
  skip_if_not_installed("pavo")
  lam <- 400:700
  a <- lux_spectrum(sin(lam / 40) + 2, lam, "irradiance", "W/m2/nm")
  b <- lux_spectrum(cos(lam / 60) + 2, lam, "irradiance", "W/m2/nm")
  r <- as_rspec(list(coral = a, sand = b))
  expect_true(pavo::is.rspec(r))
  expect_equal(names(r), c("wl", "coral", "sand"))
})

test_that("lux_spectrum -> rspec -> lux_spectrum round-trips", {
  skip_if_not_installed("pavo")
  lam <- 400:700
  x <- lux_spectrum(E = cos(lam / 80) + 1.5, lambda = lam,
                    quantity = "irradiance", unit = "W/m2/nm")
  y <- as_lux_spectrum(as_rspec(x))
  expect_s3_class(y, "lux_spectrum")
  expect_equal(y$lambda, lam)
  expect_equal(y$E, x$E, tolerance = 1e-8)
})

test_that("as_lux_spectrum.rspec selects a named column and sets meta$source", {
  skip_if_not_installed("pavo")
  lam <- 400:700
  a <- lux_spectrum(sin(lam / 40) + 2, lam, "irradiance", "W/m2/nm")
  b <- lux_spectrum(cos(lam / 60) + 2, lam, "irradiance", "W/m2/nm")
  r <- as_rspec(list(coral = a, sand = b))
  y <- as_lux_spectrum(r, column = "sand")
  expect_equal(y$E, b$E, tolerance = 1e-8)
  expect_equal(y$meta$source, "sand")
})
