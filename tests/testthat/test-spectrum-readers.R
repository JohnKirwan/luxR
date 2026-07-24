# tests/testthat/test-spectrum-readers.R
library(luxR)

lam <- seq(400, 700, by = 10)
E   <- rep(1, length(lam))

# ---- as_lux_spectrum ---------------------------------------------------

test_that("as_lux_spectrum.numeric: wraps bare vectors", {
  x <- as_lux_spectrum(E, lambda = lam, unit = "W/m2/nm")
  expect_s3_class(x, "lux_spectrum")
  expect_equal(x$E,      E)
  expect_equal(x$lambda, lam)
  expect_equal(x$unit,   "W/m2/nm")
})

test_that("as_lux_spectrum.data.frame: finds lambda column by priority", {
  df <- data.frame(lambda = lam, E = E)
  x  <- as_lux_spectrum(df)
  expect_equal(x$lambda, lam)
  expect_equal(x$E, E)
})

test_that("as_lux_spectrum.data.frame: falls back to 'wavelength' column", {
  df <- data.frame(wavelength = lam, value = E)
  x  <- as_lux_spectrum(df)
  expect_equal(x$lambda, lam)
})

test_that("as_lux_spectrum.data.frame: falls back to 'wv' column", {
  df <- data.frame(wv = lam, irradiance = E)
  x  <- as_lux_spectrum(df)
  expect_equal(x$lambda, lam)
})

test_that("as_lux_spectrum.data.frame: explicit lambda_col and E_col override search", {
  df <- data.frame(nm = lam, flux = E)
  x  <- as_lux_spectrum(df, lambda_col = "nm", E_col = "flux")
  expect_equal(x$lambda, lam)
  expect_equal(x$E, E)
})

test_that("as_lux_spectrum.data.frame: error when lambda column not found", {
  df <- data.frame(x = lam, E = E)
  expect_error(as_lux_spectrum(df), "[Ll]ambda column")
})

test_that("as_lux_spectrum.lux_spectrum: identity", {
  x <- lux_spectrum(E, lam)
  expect_identical(as_lux_spectrum(x), x)
})

test_that("as.data.frame / as_lux_spectrum round-trip", {
  x   <- lux_spectrum(E, lam, "irradiance", "W/m2/nm")
  df  <- as.data.frame(x)
  x2  <- as_lux_spectrum(df, quantity = "irradiance", unit = "W/m2/nm")
  expect_equal(x2$E,      x$E)
  expect_equal(x2$lambda, x$lambda)
  expect_equal(x2$unit,   x$unit)
})

# ---- from_naples -------------------------------------------------------

test_that("from_naples: returns lux_spectrum with correct unit", {
  x <- from_naples("0m")
  expect_s3_class(x, "lux_spectrum")
  expect_equal(x$unit,     "umol/m2/s/nm")
  expect_equal(x$quantity, "irradiance")
})

test_that("from_naples: E values match Naples dataset column", {
  x <- from_naples("5m")
  expect_equal(x$E, Naples$depth_5m)
})

test_that("from_naples: lambda values match Naples$wv", {
  x <- from_naples("10m")
  expect_equal(x$lambda, Naples$wv)
})

test_that("from_naples: depth is stored in meta", {
  x <- from_naples("0m")
  expect_equal(x$meta$depth, "0m")
})

test_that("from_naples: reference depth and medium are stored in meta", {
  expected_depths <- c("0m" = 0, "5m" = 5, "10m" = 10)
  for (depth in names(expected_depths)) {
    x <- from_naples(depth)
    expect_identical(x$meta$reference_depth_m, unname(expected_depths[depth]))
    expect_identical(x$meta$reference_medium, "water")
  }
})

test_that("from_naples: errors on unknown depth", {
  expect_error(from_naples("20m"), "[Aa]rg")
})

# ---- from_solar --------------------------------------------------------

test_that("from_solar: returns lux_spectrum with W/m2/nm unit", {
  x <- from_solar("clear_noon")
  expect_s3_class(x, "lux_spectrum")
  expect_equal(x$unit,     "W/m2/nm")
  expect_equal(x$quantity, "irradiance")
})

test_that("from_solar: E matches solar_spectra values", {
  x  <- from_solar("overcast")
  sp <- solar_spectra[["overcast"]]
  expect_equal(x$E,      sp$irradiance)
  expect_equal(x$lambda, sp$wavelength)
})

test_that("from_solar: condition stored in meta", {
  x <- from_solar("clear_dawn")
  expect_equal(x$meta$condition, "clear_dawn")
})

test_that("from_solar: source reference metadata is preserved", {
  air <- from_solar("clear_noon")
  expect_identical(air$meta$reference_depth_m, 0)
  expect_identical(air$meta$reference_medium, "air")

  water <- from_solar("underwater_10m")
  expect_identical(water$meta$reference_depth_m, 10)
  expect_identical(water$meta$reference_medium, "water")
})

test_that("from_solar: errors on unknown condition", {
  expect_error(from_solar("night"), "[Cc]ondition|arg")
})

# ---- from_trios --------------------------------------------------------

# Reuse the make_trios_file helper logic inline:
make_trios_fixture <- function() {
  tmp <- tempfile(fileext = ".dat")
  block <- function(label) {
    header <- c(
      paste("Comment", label),
      rep("HeaderLine", 29)
    )
    data_rows <- paste(seq_along(seq(400, 700, by = 10)) - 1,
                       seq(400, 700, by = 10),
                       seq(400, 700, by = 10) * 2)
    c(header, data_rows, "[END]")
  }
  writeLines(c(block("SpecA"), block("SpecB")), tmp)
  tmp
}

test_that("from_trios: returns named list of lux_spectrum", {
  f    <- make_trios_fixture()
  lst  <- from_trios(f)
  expect_type(lst, "list")
  expect_true(all(vapply(lst, inherits, logical(1), "lux_spectrum")))
})

test_that("from_trios: list names match Comment labels", {
  f   <- make_trios_fixture()
  lst <- from_trios(f)
  expect_setequal(names(lst), c("SpecA", "SpecB"))
})

test_that("from_trios: unit is W/m2/sr/nm (read_trios converts mW -> W)", {
  f   <- make_trios_fixture()
  lst <- from_trios(f)
  expect_true(all(vapply(lst, function(s) s$unit == "W/m2/sr/nm", logical(1))))
})

test_that("from_trios: quantity is radiance", {
  f   <- make_trios_fixture()
  lst <- from_trios(f)
  expect_true(all(vapply(lst, function(s) s$quantity == "radiance", logical(1))))
})

test_that("from_trios: E values match read_trios radiance column", {
  f    <- make_trios_fixture()
  df   <- read_trios(f)
  lst  <- from_trios(f)
  e_a  <- df[df$spectrum == "SpecA", "radiance"]
  expect_equal(lst[["SpecA"]]$E, e_a)
})

# ---- from_ocean_optics -------------------------------------------------

get_oo_fixture <- function() {
  path <- testthat::test_path("fixtures", "ocean_optics_sample.txt")
  if (!file.exists(path))
    path <- system.file("testthat", "fixtures", "ocean_optics_sample.txt",
                        package = "luxR")
  path
}

test_that("from_ocean_optics: returns a single lux_spectrum", {
  x <- from_ocean_optics(get_oo_fixture(), "irradiance", "W/m2/nm",
                         "test calibration")
  expect_s3_class(x, "lux_spectrum")
})

test_that("from_ocean_optics: parses wavelength and E values", {
  x <- from_ocean_optics(get_oo_fixture(), "irradiance", "W/m2/nm",
                         "test calibration")
  expect_equal(x$lambda, c(400, 450, 500))
  expect_equal(x$E,      c(0.0012, 0.0024, 0.0036))
})

test_that("from_ocean_optics: stores instrument in meta", {
  x <- from_ocean_optics(get_oo_fixture(), "irradiance", "W/m2/nm",
                         "test calibration")
  expect_equal(x$meta$instrument, "USB2E0034")
})

test_that("from_ocean_optics: stores integration time in meta", {
  x <- from_ocean_optics(get_oo_fixture(), "irradiance", "W/m2/nm",
                         "test calibration")
  expect_equal(x$meta$integration_time_us, 10000)
})

test_that("from_ocean_optics: stores date in meta", {
  x <- from_ocean_optics(get_oo_fixture(), "irradiance", "W/m2/nm",
                         "test calibration")
  expect_equal(x$meta$date, "26-May-2026")
})

test_that("from_ocean_optics: requires physical and calibration declarations", {
  expect_error(from_ocean_optics(get_oo_fixture()),
               class = "luxR_spectrum_calibration_error")
  expect_error(
    from_ocean_optics(get_oo_fixture(), "irradiance", "W/m2/nm", ""),
    class = "luxR_spectrum_calibration_error"
  )
})

test_that("from_ocean_optics: preserves declared unit and provenance", {
  x <- from_ocean_optics(get_oo_fixture(), "irradiance", "W/m2/nm",
                         "test calibration")
  expect_equal(x$unit, "W/m2/nm")
  expect_equal(x$meta$calibration, "test calibration")
  expect_match(x$meta$import$source_checksum_md5, "^[0-9a-f]{32}$")
  expect_equal(x$meta$preprocessing$method, "none")
})

test_that("from_ocean_optics: errors when file not found", {
  expect_error(from_ocean_optics("nonexistent.txt"), "[Nn]ot exist",
               class = "luxR_spectrum_format_error")
})

test_that("read_ocean_optics preserves raw negative instrument signal", {
  input <- readLines(get_oo_fixture())
  input[length(input)] <- "500.000000\t-0.003600"
  path <- tempfile(fileext = ".txt")
  on.exit(unlink(path))
  writeLines(input, path)
  raw <- read_ocean_optics(path)
  expect_equal(raw$signal[[3L]], -0.0036)
  expect_error(
    from_ocean_optics(path, "irradiance", "W/m2/nm", "test calibration"),
    class = "luxR_spectrum_value_error"
  )
})

test_that("read_ocean_optics rejects malformed rows with source context", {
  input <- readLines(get_oo_fixture())
  input[[12L]] <- "450.000000\tnot-a-number"
  path <- tempfile(fileext = ".txt")
  on.exit(unlink(path))
  writeLines(input, path)
  error <- expect_error(read_ocean_optics(path),
                        class = "luxR_spectrum_value_error")
  expect_identical(error$line, 12L)
  expect_identical(error$field, "signal")
  expect_match(error$source_checksum_md5, "^[0-9a-f]{32}$")
  expect_true(all(c("reader_model_version", "package_version", "code_commit",
                    "configuration") %in% names(error)))
  declared_error <- expect_error(
    from_ocean_optics(path, "irradiance", "W/m2/nm", "CAL-ROW-TEST"),
    class = "luxR_spectrum_value_error"
  )
  expect_identical(declared_error$configuration$calibration, "CAL-ROW-TEST")
})
