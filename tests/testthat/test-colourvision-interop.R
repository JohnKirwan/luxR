library(luxR)

test_that("as_colourvision.lux_spectrum returns a wl + named value frame", {
  s <- from_solar("clear_noon")
  df <- as_colourvision(s, name = "noon")
  expect_s3_class(df, "data.frame")
  expect_identical(names(df), c("wl", "noon"))
  expect_identical(df$wl, s$lambda)
  expect_identical(df[[2]], s$E)
})

test_that("as_colourvision default name falls back through label/source/spec", {
  s <- from_solar("clear_noon")
  df <- as_colourvision(s)
  expect_identical(names(df)[1], "wl")
  expect_true(nzchar(names(df)[2]))
})

test_that("as_colourvision.list binds spectra sharing one grid", {
  a <- from_solar("clear_noon")
  b <- from_solar("clear_noon")
  df <- as_colourvision(list(x = a, y = b))
  expect_identical(names(df), c("wl", "x", "y"))
  expect_identical(df$wl, a$lambda)
})

test_that("as_colourvision.list errors on mismatched grids (no extrapolation)", {
  a <- from_solar("clear_noon")
  b <- a
  b$lambda <- b$lambda + 1        # shift grid
  expect_error(as_colourvision(list(a, b)), "wavelength grid")
})

test_that("as_colourvision.list rejects non-lux_spectrum input", {
  expect_error(as_colourvision(list(1, 2)), "lux_spectrum")
  expect_error(as_colourvision(list()), "lux_spectrum")
})

test_that("as_colourvision.list errors on reserved 'wl' spectrum name", {
  a <- from_solar("clear_noon")
  b <- from_solar("clear_noon")
  expect_error(as_colourvision(list(wl = a, y = b)), "wl")
})

test_that("as_colourvision.list errors on duplicate spectrum names", {
  a <- from_solar("clear_noon")
  b <- from_solar("clear_noon")
  expect_error(as_colourvision(list(x = a, x = b)), "duplicate")
})

test_that("as_colourvision.lux_spectrum errors on reserved 'wl' name", {
  s <- from_solar("clear_noon")
  expect_error(as_colourvision(s, name = "wl"), "wl")
})

test_that("as_colourvision.lux_spectrum errors on empty name", {
  s <- from_solar("clear_noon")
  expect_error(as_colourvision(s, name = ""), "non-empty")
})

test_that("as_colourvision.lux_spectrum rejects a meta-derived reserved 'wl' name", {
  s <- from_solar("clear_noon")
  s$meta$label <- "wl"
  expect_error(as_colourvision(s), "wl")
})

test_that("species_sensitivity_matrix returns wl + one col per chromatic receptor", {
  recs <- luxR:::.default_channel_receptors("Homo sapiens", "chromatic", NULL)
  C <- species_sensitivity_matrix("Homo sapiens", lambda = 300:700)
  expect_s3_class(C, "data.frame")
  expect_identical(names(C)[1], "wl")
  expect_identical(ncol(C) - 1L, nrow(recs))
  expect_identical(names(C)[-1], recs$receptor)
  expect_identical(C$wl, 300:700)
})

test_that("photon weighting equals energy weighting times wavelength", {
  Ce <- species_sensitivity_matrix("Homo sapiens", lambda = 300:700, weight = "energy")
  Cp <- species_sensitivity_matrix("Homo sapiens", lambda = 300:700, weight = "photon")
  for (j in 2:ncol(Ce))
    expect_equal(Cp[[j]], Ce[[j]] * Ce$wl)
})

test_that("energy columns match the govardovskii template used by colour_jnd", {
  lam <- 300:700
  recs <- luxR:::.default_channel_receptors("Homo sapiens", "chromatic", NULL)
  C <- species_sensitivity_matrix("Homo sapiens", lambda = lam, weight = "energy")
  for (i in seq_len(nrow(recs))) {
    S <- govardovskii_template(lam, recs$lambda_max[i], recs$chromophore[i])$S
    expect_equal(C[[i + 1L]], S)
  }
})

test_that("species_sensitivity_matrix inherits fail-fast channel validation", {
  expect_error(species_sensitivity_matrix("Not a species"))
})

test_that("species_sensitivity_matrix rejects a non-increasing grid", {
  expect_error(
    species_sensitivity_matrix("Homo sapiens", lambda = c(400, 400, 401)),
    "increasing"
  )
})
