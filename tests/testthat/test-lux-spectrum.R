# tests/testthat/test-lux-spectrum.R
library(luxR)

lam <- seq(400, 700, by = 10)
E   <- rep(1, length(lam))

# ---- constructor -------------------------------------------------------

test_that("lux_spectrum: constructs with required fields", {
  x <- lux_spectrum(E, lam)
  expect_s3_class(x, "lux_spectrum")
  expect_equal(x$E,        E)
  expect_equal(x$lambda,   lam)
  expect_equal(x$quantity, "irradiance")
  expect_equal(x$unit,     "W/m2/nm")
  expect_equal(x$binwidth, 10)
  expect_equal(x$meta,     list())
})

test_that("lux_spectrum: infers binwidth from lambda spacing", {
  x <- lux_spectrum(E, lam)
  expect_equal(x$binwidth, mean(diff(lam)))
})

test_that("lux_spectrum: explicit binwidth is preserved", {
  x <- lux_spectrum(E, lam, binwidth = 10)
  expect_equal(x$binwidth, 10)
})

test_that("lux_spectrum: single-bin defaults binwidth to 1", {
  x <- lux_spectrum(1, 550)
  expect_equal(x$binwidth, 1)
})

test_that("lux_spectrum: meta is stored", {
  x <- lux_spectrum(E, lam, meta = list(depth = 10))
  expect_equal(x$meta$depth, 10)
})

# ---- validator ---------------------------------------------------------

test_that("lux_spectrum: error on length mismatch", {
  expect_error(
    lux_spectrum(E, lam[-1]),
    "equal length",
    class = "lux_spectrum_value_error"
  )
})

test_that("lux_spectrum: requires non-empty numeric vectors", {
  invalid <- list(
    character(),
    numeric(),
    as.factor(c("1", "2")),
    list(1, 2),
    matrix(1:4, nrow = 2),
    c(1 + 1i, 2 + 0i),
    as.Date(c("2026-01-01", "2026-01-02"))
  )

  expect_error(
    lux_spectrum(numeric(), numeric()),
    "non-empty",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    lux_spectrum(character(), numeric()),
    "numeric vector",
    class = "lux_spectrum_type_error"
  )
  for (x in invalid[-c(1, 2)]) {
    expect_error(
      lux_spectrum(x, seq_along(x)),
      class = "lux_spectrum_type_error"
    )
    expect_error(
      lux_spectrum(rep(1, length(x)), x),
      class = "lux_spectrum_type_error"
    )
  }
})

test_that("lux_spectrum: error on invalid unit", {
  expect_error(
    lux_spectrum(E, lam, unit = "furlongs"),
    "vocabulary",
    class = "lux_spectrum_dimension_error"
  )
})

test_that("lux_spectrum: error on reflectance out of range", {
  expect_error(
    lux_spectrum(c(-0.1, rep(0.5, length(lam) - 1)), lam,
                 quantity = "reflectance", unit = "dimensionless"),
    "\\[0, 1\\]",
    class = "lux_spectrum_value_error"
  )
  expect_error(
    lux_spectrum(c(1.1, rep(0.5, length(lam) - 1)), lam,
                 quantity = "reflectance", unit = "dimensionless"),
    "\\[0, 1\\]",
    class = "lux_spectrum_value_error"
  )
  expect_no_error(
    lux_spectrum(c(0, 1), c(400, 410),
                 quantity = "reflectance", unit = "dimensionless")
  )
})

test_that("lux_spectrum: rejects non-finite wavelengths and values", {
  for (bad in list(NA_real_, NaN, Inf, -Inf)) {
    E_bad <- E
    E_bad[3] <- bad
    err_E <- expect_error(
      lux_spectrum(E_bad, lam),
      "finite values",
      class = "lux_spectrum_value_error"
    )
    expect_identical(err_E$field, "E")
    expect_identical(err_E$index, 3L)

    lam_bad <- lam
    lam_bad[3] <- bad
    err_lambda <- expect_error(
      lux_spectrum(E, lam_bad),
      "finite values",
      class = "lux_spectrum_value_error"
    )
    expect_identical(err_lambda$field, "lambda")
    expect_identical(err_lambda$index, 3L)
  }
})

test_that("lux_spectrum: requires strictly increasing unique wavelengths", {
  expect_error(
    lux_spectrum(1:3, c(400, 390, 410)),
    "strictly increasing",
    class = "lux_spectrum_grid_error"
  )
  err <- expect_error(
    lux_spectrum(1:3, c(400, 400, 410)),
    "strictly increasing",
    class = "lux_spectrum_grid_error"
  )
  expect_identical(err$field, "lambda")
  expect_identical(err$index, 2L)
})

test_that("lux_spectrum: rejects irregular wavelength grids", {
  err <- expect_error(
    lux_spectrum(1:4, c(400, 410, 425, 435)),
    "regularly spaced",
    class = "lux_spectrum_grid_error"
  )
  expect_identical(err$field, "lambda")
  expect_match(conditionMessage(err), "Resample raw vectors")
})

test_that("lux_spectrum: accepts floating-point-equivalent regular spacing", {
  x <- lux_spectrum(c(1, 2, 3), c(0.1, 0.2, 0.3), binwidth = 0.1)
  expect_equal(x$binwidth, 0.1)
})

test_that("lux_spectrum: validates binwidth and grid compatibility", {
  invalid <- list(0, -1, NA_real_, NaN, Inf, c(10, 10), "10", 10 + 0i)
  for (binwidth in invalid) {
    expect_error(
      lux_spectrum(E, lam, binwidth = binwidth),
      class = "lux_spectrum_validation_error"
    )
  }
  expect_error(
    lux_spectrum(E, lam, binwidth = 5),
    "must match",
    class = "lux_spectrum_grid_error"
  )
  expect_no_error(lux_spectrum(1, 550, binwidth = 5))
})

test_that("lux_spectrum: accepts exactly the valid quantity-unit pairs", {
  pairs <- list(
    irradiance = c("W/m2/nm", "umol/m2/s/nm", "mmol/m2/s/nm",
                   "mol/m2/s/nm"),
    radiance = c("W/m2/sr/nm", "mW/m2/sr/nm",
                 "umol/m2/s/sr/nm", "mmol/m2/s/sr/nm",
                 "mol/m2/s/sr/nm"),
    reflectance = "dimensionless"
  )

  for (quantity in names(pairs)) {
    values <- if (quantity == "reflectance") rep(0.5, length(lam)) else E
    for (unit in pairs[[quantity]]) {
      expect_s3_class(
        lux_spectrum(values, lam, quantity = quantity, unit = unit),
        "lux_spectrum"
      )
    }
  }
})

test_that("lux_spectrum: rejects mismatched quantity and unit dimensions", {
  invalid <- list(
    c("irradiance", "W/m2/sr/nm"),
    c("irradiance", "dimensionless"),
    c("radiance", "W/m2/nm"),
    c("radiance", "dimensionless"),
    c("reflectance", "W/m2/nm"),
    c("reflectance", "W/m2/sr/nm")
  )

  for (pair in invalid) {
    expect_error(
      lux_spectrum(E, lam, quantity = pair[1], unit = pair[2]),
      "different dimensions",
      class = "lux_spectrum_dimension_error"
    )
  }
})

test_that("lux_spectrum: rejects negative physical spectra", {
  for (pair in list(
    c("irradiance", "W/m2/nm"),
    c("irradiance", "umol/m2/s/nm"),
    c("radiance", "W/m2/sr/nm"),
    c("radiance", "umol/m2/s/sr/nm")
  )) {
    err <- expect_error(
      lux_spectrum(c(1, -0.1), c(400, 410),
                   quantity = pair[1], unit = pair[2]),
      "non-negative",
      class = "lux_spectrum_value_error"
    )
    expect_identical(err$field, "E")
    expect_identical(err$index, 2L)
  }
})

test_that("lux_spectrum: validates quantity, unit, and metadata schemas", {
  for (quantity in list("irr", "", NA_character_, c("irradiance", "radiance"),
                        1)) {
    expect_error(
      lux_spectrum(E, lam, quantity = quantity),
      class = "lux_spectrum_validation_error"
    )
  }
  for (unit in list("", NA_character_, c("W/m2/nm", "mol/m2/s/nm"), 1)) {
    expect_error(
      lux_spectrum(E, lam, unit = unit),
      class = "lux_spectrum_validation_error"
    )
  }
  expect_error(
    lux_spectrum(E, lam, meta = "source"),
    class = "lux_spectrum_type_error"
  )
  expect_error(
    lux_spectrum(E, lam, meta = list("source")),
    "unique, non-empty names",
    class = "lux_spectrum_value_error"
  )
  duplicate_meta <- structure(list("a", "b"), names = c("source", "source"))
  expect_error(
    lux_spectrum(E, lam, meta = duplicate_meta),
    class = "lux_spectrum_value_error"
  )
})

test_that("lux_spectrum: validation conditions retain supplied context", {
  meta <- list(
    source = "instrument.dat",
    checksum = "sha256:test",
    seed = 42L,
    config = "calibrated"
  )
  err <- expect_error(
    lux_spectrum(c(1, NA_real_), c(400, 410), meta = meta),
    class = "lux_spectrum_value_error"
  )
  expect_identical(err$context, meta)
})

# ---- print and summary -------------------------------------------------

test_that("lux_spectrum: print produces expected one-line output", {
  x   <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  out <- capture.output(print(x))
  expect_match(out[1], "lux_spectrum")
  expect_match(out[1], "irradiance")
  expect_match(out[1], "W/m2/nm")
  expect_match(out[1], "400")
  expect_match(out[1], "700")
  expect_match(out[1], "31")
})

test_that("lux_spectrum: print shows meta fields", {
  x   <- lux_spectrum(E, lam, meta = list(depth = 10))
  out <- capture.output(print(x))
  expect_true(any(grepl("depth", out)))
  expect_true(any(grepl("10",    out)))
})

test_that("lux_spectrum: summary adds E statistics", {
  x   <- lux_spectrum(E, lam)
  out <- capture.output(summary(x))
  expect_true(any(grepl("min|mean|max", out, ignore.case = TRUE)))
})

test_that("lux_spectrum: summary adds peak wavelength", {
  E2  <- c(rep(1, 15), 10, rep(1, 15))  # peak at position 16 => lambda 550
  x   <- lux_spectrum(E2, lam)
  out <- capture.output(summary(x))
  expect_true(any(grepl("550", out)))
})

# ---- subsetting --------------------------------------------------------

test_that("lux_spectrum: [ returns lux_spectrum with correct range", {
  x   <- lux_spectrum(E, lam)
  sub <- x[500, 600]
  expect_s3_class(sub, "lux_spectrum")
  expect_true(all(sub$lambda >= 500 & sub$lambda <= 600))
})

test_that("lux_spectrum: [ preserves metadata", {
  x   <- lux_spectrum(E, lam, "irradiance", "W/m2/nm",
                      meta = list(depth = 5))
  sub <- x[450, 650]
  expect_equal(sub$meta$depth, 5)
})

test_that("lux_spectrum: [ inherits quantity and unit", {
  x   <- lux_spectrum(E, lam, "radiance", "mW/m2/sr/nm")
  sub <- x[400, 550]
  expect_equal(sub$quantity, "radiance")
  expect_equal(sub$unit,     "mW/m2/sr/nm")
})

test_that("lux_spectrum: [ recalculates binwidth", {
  lam2 <- seq(400, 700, by = 5)
  E2   <- rep(1, length(lam2))
  x    <- lux_spectrum(E2, lam2)
  sub  <- x[500, 600]
  expect_equal(sub$binwidth, 5)
})

test_that("lux_spectrum: one-bin subset preserves source binwidth", {
  x <- lux_spectrum(E, lam)
  sub <- x[550, 550]
  expect_equal(sub$lambda, 550)
  expect_equal(sub$binwidth, x$binwidth)
})

test_that("lux_spectrum: [ errors when range has no wavelengths", {
  x <- lux_spectrum(E, lam)
  expect_error(x[800, 900], "[Nn]o wavelength")
})

# ---- arithmetic --------------------------------------------------------

test_that("lux_spectrum: spectrum + spectrum is element-wise", {
  a <- lux_spectrum(E, lam)
  b <- lux_spectrum(E * 2, lam)
  r <- a + b
  expect_s3_class(r, "lux_spectrum")
  expect_equal(r$E, E * 3)
})

test_that("lux_spectrum: spectrum + scalar is element-wise", {
  a <- lux_spectrum(E, lam)
  r <- a + 5
  expect_equal(r$E, E + 5)
  expect_equal(r$unit, a$unit)
})

test_that("lux_spectrum: scalar + spectrum works", {
  a <- lux_spectrum(E, lam)
  r <- 3 + a
  expect_equal(r$E, 3 + E)
})

test_that("lux_spectrum: spectrum - spectrum is element-wise", {
  a <- lux_spectrum(E * 3, lam)
  b <- lux_spectrum(E,     lam)
  r <- a - b
  expect_equal(r$E, E * 2)
})

test_that("lux_spectrum: spectrum * scalar preserves unit", {
  a <- lux_spectrum(E, lam)
  r <- a * 2
  expect_equal(r$E, E * 2)
  expect_equal(r$unit, a$unit)
})

test_that("lux_spectrum: reflectance * irradiance -> irradiance", {
  refl  <- lux_spectrum(rep(0.5, length(lam)), lam,
                        quantity = "reflectance", unit = "dimensionless")
  illum <- lux_spectrum(E, lam, quantity = "irradiance", unit = "W/m2/nm")
  r     <- refl * illum
  expect_equal(r$quantity, "irradiance")
  expect_equal(r$unit,     "W/m2/nm")
  expect_equal(r$E,        rep(0.5, length(lam)))
})

test_that("lux_spectrum: reflectance * radiance -> radiance", {
  refl <- lux_spectrum(rep(0.5, length(lam)), lam,
                       quantity = "reflectance", unit = "dimensionless")
  rad <- lux_spectrum(E, lam, quantity = "radiance",
                      unit = "W/m2/sr/nm")
  r <- refl * rad
  expect_equal(r$quantity, "radiance")
  expect_equal(r$unit, "W/m2/sr/nm")
  expect_equal(r$E, rep(0.5, length(lam)))
})

test_that("lux_spectrum: incompatible addition and subtraction error", {
  irradiance <- lux_spectrum(E, lam, quantity = "irradiance",
                             unit = "W/m2/nm")
  photon_flux <- lux_spectrum(E, lam, quantity = "irradiance",
                              unit = "umol/m2/s/nm")
  radiance <- lux_spectrum(E, lam, quantity = "radiance",
                           unit = "W/m2/sr/nm")

  expect_error(irradiance + photon_flux, "different quantities or units")
  expect_error(irradiance - radiance, "different quantities or units")
})

test_that("lux_spectrum: unsupported spectrum products and quotients error", {
  irradiance <- lux_spectrum(E, lam, quantity = "irradiance",
                             unit = "W/m2/nm")
  radiance <- lux_spectrum(E, lam, quantity = "radiance",
                           unit = "W/m2/sr/nm")

  expect_error(irradiance * radiance, "Unsupported lux_spectrum multiplication")
  expect_error(irradiance / irradiance, "Unsupported lux_spectrum division")
  expect_error(2 / irradiance, "reciprocal dimensions")
})

test_that("lux_spectrum: spectrum / scalar is element-wise", {
  a <- lux_spectrum(E * 4, lam)
  r <- a / 2
  expect_equal(r$E, E * 2)
})

test_that("lux_spectrum: arithmetic cannot construct negative physical values", {
  a <- lux_spectrum(E, lam)
  b <- lux_spectrum(E * 2, lam)

  expect_error(a - b, "non-negative", class = "lux_spectrum_value_error")
  expect_error(-a, "non-negative", class = "lux_spectrum_value_error")
  expect_error(a - 2, "non-negative", class = "lux_spectrum_value_error")
})

test_that("lux_spectrum: arithmetic errors on mismatched grids", {
  a <- lux_spectrum(E,          seq(400, 700, by = 10))
  b <- lux_spectrum(rep(1, 31), seq(401, 701, by = 10))
  expect_error(a + b, "identical lambda")
})

# ---- as.data.frame -----------------------------------------------------

test_that("lux_spectrum: as.data.frame returns two columns", {
  x  <- lux_spectrum(E, lam)
  df <- as.data.frame(x)
  expect_s3_class(df, "data.frame")
  expect_setequal(names(df), c("lambda", "E"))
  expect_equal(nrow(df), length(lam))
})

test_that("lux_spectrum: as.data.frame carries unit and quantity as attributes", {
  x  <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  df <- as.data.frame(x)
  expect_equal(attr(df, "unit"),     "W/m2/nm")
  expect_equal(attr(df, "quantity"), "irradiance")
})

test_that("lux_spectrum: round-trip via as.data.frame + as_lux_spectrum", {
  x   <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  df  <- as.data.frame(x)
  x2  <- as_lux_spectrum(df, quantity = "irradiance", unit = "W/m2/nm")
  expect_equal(x2$E,      x$E)
  expect_equal(x2$lambda, x$lambda)
})

# ---- convert_unit ------------------------------------------------------

test_that("convert_unit: W/m2/nm -> umol/m2/s/nm -> W/m2/nm round-trips", {
  x      <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  x_mol  <- convert_unit(x, "umol/m2/s/nm")
  x_back <- convert_unit(x_mol, "W/m2/nm")
  expect_equal(x_back$E, x$E, tolerance = 1e-8)
  expect_equal(x_back$unit, "W/m2/nm")
})

test_that("convert_unit: W/m2/sr/nm <-> mW/m2/sr/nm", {
  x   <- lux_spectrum(E, lam, "radiance", "W/m2/sr/nm")
  xmW <- convert_unit(x, "mW/m2/sr/nm")
  expect_equal(xmW$E,   x$E * 1e3)
  expect_equal(xmW$unit, "mW/m2/sr/nm")
  xW  <- convert_unit(xmW, "W/m2/sr/nm")
  expect_equal(xW$E, x$E, tolerance = 1e-12)
})

test_that("convert_unit: radiance energy and photon units round-trip", {
  x <- lux_spectrum(rep(1e-3, length(lam)), lam,
                    quantity = "radiance", unit = "W/m2/sr/nm")
  photons <- convert_unit(x, "umol/m2/s/sr/nm")
  expect_equal(photons$quantity, "radiance")
  expect_equal(photons$unit, "umol/m2/s/sr/nm")
  back <- convert_unit(photons, "W/m2/sr/nm")
  expect_equal(back$E, x$E, tolerance = 1e-12)

  mW <- convert_unit(photons, "mW/m2/sr/nm")
  expect_equal(mW$E, x$E * 1e3, tolerance = 1e-12)
  expect_equal(mW$unit, "mW/m2/sr/nm")
})

test_that("convert_unit: does not mix irradiance and radiance dimensions", {
  x <- lux_spectrum(E, lam, quantity = "radiance", unit = "W/m2/sr/nm")
  expect_error(convert_unit(x, "umol/m2/s/nm"), "irradiance and radiance")
})

test_that("convert_unit: umol -> mmol -> mol scale correctly", {
  x    <- lux_spectrum(rep(1e3, length(lam)), lam, unit = "umol/m2/s/nm")
  xmm  <- convert_unit(x, "mmol/m2/s/nm")
  xmol <- convert_unit(x, "mol/m2/s/nm")
  expect_equal(xmm$E,  rep(1,    length(lam)))
  expect_equal(xmol$E, rep(1e-3, length(lam)))
})

test_that("convert_unit: same unit returns identical object", {
  x <- lux_spectrum(E, lam)
  expect_identical(convert_unit(x, "W/m2/nm"), x)
})

test_that("convert_unit: errors on dimensionless target", {
  x <- lux_spectrum(E, lam)
  expect_error(convert_unit(x, "dimensionless"), "[Dd]imensionless")
})

test_that("convert_unit: errors on unknown conversion path", {
  x <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  expect_error(convert_unit(x, "mW/m2/sr/nm"), "[Nn]o conversion")
})

# ---- plot --------------------------------------------------------------

test_that("lux_spectrum: plot produces no error for single spectrum", {
  x <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  expect_no_error(plot(x))
})

test_that("lux_spectrum: plot produces no error for list of spectra", {
  a <- lux_spectrum(E,     lam, meta = list(label = "a"))
  b <- lux_spectrum(E * 2, lam, meta = list(label = "b"))
  expect_no_error(plot(list(a, b)))
})
