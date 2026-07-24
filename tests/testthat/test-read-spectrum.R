library(luxR)

lightr_file <- function(...) {
  testthat::skip_if_not_installed("lightr", minimum_version = "2.0.0")
  td <- system.file("testdata", package = "lightr")
  testthat::skip_if(!nzchar(td), "lightr testdata not available")
  file.path(td, ...)
}

test_that("read_instrument_spectrum preserves native Avantes sampling", {
  f <- lightr_file("compare", "Avantes", "30849.RFL8")
  x <- read_instrument_spectrum(
    f, measurement = "reflectance", value_scale = "percent",
    range = c(300, 700)
  )

  expect_s3_class(x, "lux_instrument_spectrum")
  expect_identical(x$measurement, "reflectance")
  expect_identical(x$value_scale, "percent")
  expect_true(length(unique(round(diff(x$lambda), 8L))) > 1L)
  expect_identical(x$meta$preprocessing$interpolation, "none")
  expect_identical(as.data.frame(x),
                   data.frame(lambda = x$lambda, value = x$value))
})

test_that("read_spectrum explicitly converts percent reflectance", {
  f <- lightr_file("compare", "Avantes", "30849.RFL8")
  raw <- read_instrument_spectrum(
    f, measurement = "reflectance", value_scale = "percent",
    range = c(300, 700), interpolate = TRUE
  )
  x <- read_spectrum(
    f, measurement = "reflectance", value_scale = "percent",
    quantity = "reflectance", unit = "dimensionless",
    calibration = "lightr fixture", range = c(300, 700),
    interpolate = TRUE
  )

  expect_s3_class(x, "lux_spectrum")
  expect_equal(x$E, raw$value / 100)
  expect_true(all(x$E >= 0 & x$E <= 1))
  expect_identical(x$meta$preprocessing$value_scale$factor, 0.01)
  expect_identical(x$meta$preprocessing$value_scale$output, "fraction")
  expect_identical(x$meta$import$operation, "read_spectrum")
  expect_identical(x$meta$import$conversion_operation, "as_lux_spectrum")
})

test_that("read_spectrum requires explicit interpolation for irregular grids", {
  f <- lightr_file("compare", "OceanInsight", "BB_PF21_4.txt")
  raw <- read_instrument_spectrum(
    f, measurement = "reflectance", value_scale = "percent",
    range = c(300, 700)
  )
  expect_error(
    as_lux_spectrum(
      raw, quantity = "reflectance", unit = "dimensionless",
      calibration = "lightr fixture"
    ),
    "regularly spaced",
    class = "luxR_spectrum_value_error"
  )

  x <- read_spectrum(
    f, measurement = "reflectance", value_scale = "percent",
    quantity = "reflectance", unit = "dimensionless",
    calibration = "lightr fixture", range = c(300, 700),
    interpolate = TRUE
  )
  expect_equal(range(x$lambda), c(300, 700))
  expect_true(all(diff(x$lambda) == 1))
})

test_that("known extensions reject contradictory measurement declarations", {
  f <- lightr_file("compare", "Avantes", "30849.RFL8")
  expect_error(
    read_instrument_spectrum(
      f, measurement = "irradiance", value_scale = "absolute",
      range = c(300, 700)
    ),
    "identifies a reflectance measurement",
    class = "luxR_spectrum_dimension_error"
  )
})

test_that("measurement and value scale combinations are validated", {
  f <- lightr_file("compare", "Avantes", "30849.RFL8")
  expect_error(
    read_instrument_spectrum(
      f, measurement = "reflectance", value_scale = "absolute",
      range = c(300, 700)
    ),
    "incompatible",
    class = "luxR_spectrum_dimension_error"
  )
})

test_that("unsupported physical kinds remain inspectable instrument records", {
  f <- lightr_file("avantes_trans.TRM")
  raw <- read_instrument_spectrum(
    f, measurement = "transmittance", value_scale = "percent",
    range = c(300, 700), interpolate = TRUE
  )
  expect_s3_class(raw, "lux_instrument_spectrum")
  expect_error(
    as_lux_spectrum(
      raw, quantity = "reflectance", unit = "dimensionless",
      calibration = "lightr fixture"
    ),
    "cannot be represented",
    class = "luxR_spectrum_dimension_error"
  )
})

test_that("negative processed values require an explicit recorded policy", {
  f <- lightr_file("procspec_files", "OceanOptics_badencode.ProcSpec")
  args <- list(
    path = f, measurement = "reflectance", value_scale = "percent",
    quantity = "reflectance", unit = "dimensionless",
    calibration = "lightr fixture", range = c(300, 700),
    interpolate = TRUE
  )
  expect_error(
    do.call(read_spectrum, args),
    "negative value",
    class = "luxR_spectrum_value_error"
  )

  args$negative_policy <- "zero"
  x <- do.call(read_spectrum, args)
  expect_true(all(x$E >= 0))
  expect_gt(x$meta$preprocessing$negative_values$affected_count, 0L)
  expect_identical(x$meta$preprocessing$negative_values$policy, "zero")
})

test_that("lightr provenance and exact parser configuration are recorded", {
  f <- lightr_file("compare", "Avantes", "30849.RFL8")
  x <- read_instrument_spectrum(
    f, measurement = "reflectance", value_scale = "percent",
    range = c(400, 600), interpolate = TRUE,
    parser_args = list(specnum = 1)
  )
  config <- x$meta$import$configuration

  expect_match(x$meta$import$source_checksum_md5, "^[0-9a-f]{32}$")
  expect_identical(config$lightr_version,
                   as.character(utils::packageVersion("lightr")))
  expect_identical(config$extension, "rfl8")
  expect_identical(config$parser_interface,
                   "lightr::lr_get_spec/lr_get_metadata")
  expect_identical(config$parser_args, list(specnum = 1))
  expect_identical(x$meta$import$operation, "read_instrument_spectrum")
})

test_that("parser arguments cannot override luxR import controls", {
  f <- lightr_file("compare", "Avantes", "30849.RFL8")
  expect_error(
    read_instrument_spectrum(
      f, measurement = "reflectance", value_scale = "percent",
      range = c(300, 700), parser_args = list(interpolate = TRUE)
    ),
    "cannot override",
    class = "luxR_spectrum_schema_error"
  )
})

test_that("policy and range schemas fail with typed errors", {
  f <- lightr_file("compare", "Avantes", "30849.RFL8")
  expect_error(
    read_instrument_spectrum(
      f, measurement = "reflectance", value_scale = "percent",
      range = matrix(c(300, 700), nrow = 1L)
    ),
    class = "luxR_spectrum_schema_error"
  )
  expect_error(
    read_instrument_spectrum(
      f, measurement = "reflectance", value_scale = "percent",
      range = c(300, 700), warning_policy = "ignore"
    ),
    class = "luxR_spectrum_schema_error"
  )
})

test_that("lightr parser warnings fail by default", {
  f <- lightr_file("failfile.fail")
  expect_error(
    read_instrument_spectrum(
      f, measurement = "raw", value_scale = "raw", range = c(300, 700)
    ),
    "parser warning",
    class = "luxR_spectrum_format_error"
  )
})

test_that("read_spectrum validates required declarations and paths", {
  testthat::skip_if_not_installed("lightr", minimum_version = "2.0.0")
  expect_error(read_spectrum("does_not_exist.txt"), "exist")

  f <- lightr_file("compare", "OceanInsight", "BB_PF21_4.txt")
  expect_error(
    read_spectrum(f),
    class = "luxR_spectrum_schema_error"
  )
  expect_error(
    read_spectrum(
      f, measurement = "reflectance", value_scale = "percent",
      quantity = "reflectance", unit = "dimensionless",
      calibration = "fixture"
    ),
    class = "luxR_spectrum_schema_error"
  )
})

test_that("files without extensions fail with structured context", {
  testthat::skip_if_not_installed("lightr", minimum_version = "2.0.0")
  tmp <- tempfile()
  file.create(tmp)
  on.exit(unlink(tmp))
  expect_error(
    read_instrument_spectrum(
      tmp, measurement = "raw", value_scale = "raw", range = c(300, 700)
    ),
    "extension",
    class = "luxR_spectrum_format_error"
  )
})
