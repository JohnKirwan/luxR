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
               class = "luxR_value_error")
  expect_error(
    from_ocean_optics(get_oo_fixture(), "irradiance", "W/m2/nm", ""),
    class = "luxR_value_error"
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
               class = "luxR_value_error")
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
    class = "luxR_value_error"
  )
})

test_that("read_ocean_optics rejects malformed rows with source context", {
  input <- readLines(get_oo_fixture())
  input[[12L]] <- "450.000000\tnot-a-number"
  path <- tempfile(fileext = ".txt")
  on.exit(unlink(path))
  writeLines(input, path)
  error <- expect_error(read_ocean_optics(path),
                        class = "luxR_value_error")
  expect_identical(error$line, 12L)
  expect_identical(error$field, "signal")
  expect_match(error$source_checksum_md5, "^[0-9a-f]{32}$")
  expect_true(all(c("reader_model_version", "package_version", "code_commit",
                    "configuration") %in% names(error)))
  declared_error <- expect_error(
    from_ocean_optics(path, "irradiance", "W/m2/nm", "CAL-ROW-TEST"),
    class = "luxR_value_error"
  )
  expect_identical(declared_error$configuration$calibration, "CAL-ROW-TEST")
})

test_that("an imported irregular grid keeps its kind and the import marker", {
  input <- readLines(get_oo_fixture())
  input[[13L]] <- "520.000000\t0.003600"
  path <- tempfile(fileext = ".txt")
  on.exit(unlink(path))
  writeLines(input, path)
  err <- tryCatch(
    from_ocean_optics(path, "irradiance", "W/m2/nm", "test calibration"),
    error = identity
  )
  expect_s3_class(err, "luxR_grid_error")
  expect_s3_class(err, "luxR_import_error")
  expect_identical(err$field, "lambda")
})

test_that("from_ocean_optics enriches file errors with calibration context", {
  input <- readLines(get_oo_fixture())
  input <- input[-10L]
  path <- tempfile(fileext = ".txt")
  on.exit(unlink(path))
  writeLines(input, path)
  err <- tryCatch(
    from_ocean_optics(path, "irradiance", "W/m2/nm", "CAL-ENRICH"),
    error = identity
  )
  expect_s3_class(err, "luxR_format_error")
  expect_s3_class(err, "luxR_import_error")
  expect_identical(err$configuration$calibration, "CAL-ENRICH")
  expect_identical(err$operation, "from_ocean_optics")
})

# ---- Ocean Optics header variants (SpectraSuite / OceanView) -----------

write_oo <- function(header, rows = c("400.0\t1", "450.0\t2", "500.0\t3"),
                     begin = ">>>>>Begin Spectral Data<<<<<", end = NULL) {
  path <- tempfile(fileext = ".txt")
  writeLines(c(header, begin, rows, end), path)
  path
}

test_that("read_ocean_optics parses the SpectraSuite processed-spectrum header", {
  path <- write_oo(
    c("Spectrometers: USB4A00428",
      "Integration Time (usec): 20000 (USB4A00428)",
      "Number of Pixels in Processed Spectrum: 3"),
    begin = ">>>>>Begin Processed Spectral Data<<<<<",
    end = ">>>>>End Processed Spectral Data<<<<<"
  )
  on.exit(unlink(path))
  h <- attr(read_ocean_optics(path), "luxR.header")
  expect_equal(h$instrument, "USB4A00428")
  expect_equal(h$integration_time_us, 20000)
  expect_equal(h$declared_pixels, 3)
})

test_that("read_ocean_optics checks the processed-spectrum pixel count", {
  path <- write_oo(c("Number of Pixels in Processed Spectrum: 4"))
  on.exit(unlink(path))
  expect_error(read_ocean_optics(path), "declares 4 pixels",
               class = "luxR_import_error")
})

test_that("read_ocean_optics rejects a serial suffix naming another spectrometer", {
  path <- write_oo(c("Spectrometers: USB4A00428",
                     "Integration Time (usec): 20000 (JAZA1465)"))
  on.exit(unlink(path))
  expect_error(read_ocean_optics(path), "JAZA1465",
               class = "luxR_import_error")
})

test_that("read_ocean_optics rejects a serial suffix without a spectrometer", {
  path <- write_oo(c("Integration Time (usec): 20000 (USB4A00428)"))
  on.exit(unlink(path))
  expect_error(read_ocean_optics(path), class = "luxR_import_error")
})

test_that("read_ocean_optics converts an OceanView integration time in seconds", {
  path <- write_oo(c("Spectrometer: USB2+H09794",
                     "Integration Time (sec): 2.000000E-2"))
  on.exit(unlink(path))
  h <- attr(read_ocean_optics(path), "luxR.header")
  expect_equal(h$instrument, "USB2+H09794")
  expect_equal(h$integration_time_us, 20000)
})

test_that("read_ocean_optics reads a pixel-count mismatch only on explicit opt-in", {
  path <- write_oo(c("Number of Pixels in Spectrum: 2"))
  on.exit(unlink(path))
  expect_error(read_ocean_optics(path), "check_pixels = FALSE",
               class = "luxR_import_error")
  raw <- read_ocean_optics(path, check_pixels = FALSE)
  expect_equal(nrow(raw), 3L)
  expect_false(attr(raw, "luxR.import")$configuration$check_pixels)
  x <- from_ocean_optics(path, "irradiance", "W/m2/nm", "test calibration",
                         check_pixels = FALSE)
  expect_false(x$meta$import$configuration$check_pixels)
  expect_error(read_ocean_optics(path, check_pixels = NA),
               class = "luxR_type_error")
})

test_that("read_ocean_optics reads the lightr Ocean Optics sample files", {
  skip_if_not_installed("lightr")
  d <- system.file("testdata", package = "lightr")
  skip_if_not(all(file.exists(file.path(d, c("OOusb4000.txt", "OceanView.txt")))),
              "lightr no longer ships the Ocean Optics sample files")
  usb <- read_ocean_optics(file.path(d, "OOusb4000.txt"))
  expect_equal(nrow(usb), 3648L)
  expect_equal(attr(usb, "luxR.header")$integration_time_us, 20000)
  spliced <- file.path(d, "OceanView.txt")
  expect_error(read_ocean_optics(spliced), class = "luxR_import_error")
  ov <- read_ocean_optics(spliced, check_pixels = FALSE)
  expect_equal(nrow(ov), 2389L)
  expect_equal(attr(ov, "luxR.header")$integration_time_us, 20000)
})

test_that("Ocean Optics irradiance in uW/cm2/nm imports and converts", {
  x <- from_ocean_optics(get_oo_fixture(), "irradiance", "uW/cm2/nm",
                         "test calibration")
  expect_equal(x$unit, "uW/cm2/nm")
  expect_equal(convert_unit(x, "W/m2/nm")$E, x$E * 1e-2)
})
