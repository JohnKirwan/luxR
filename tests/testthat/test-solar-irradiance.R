library(luxR)

test_that("solar_irradiance returns data frame with wavelength and irradiance", {
  out <- solar_irradiance("clear_noon")
  expect_s3_class(out, "data.frame")
  expect_named(out, c("wavelength", "irradiance"))
  expect_true(nrow(out) > 0)
  expect_true(all(out$irradiance >= 0))
})

test_that("solar_irradiance condition attribute matches request", {
  out <- solar_irradiance("overcast")
  expect_equal(attr(out, "condition"), "overcast")
})

test_that("every solar source records its reference depth and medium", {
  expected <- data.frame(
    condition = c("clear_noon", "clear_dawn", "overcast",
                  "underwater_1m", "underwater_10m"),
    reference_depth_m = c(0, 0, 0, 1, 10),
    reference_medium = c("air", "air", "air", "water", "water")
  )

  expect_setequal(names(solar_spectra), expected$condition)
  for (i in seq_len(nrow(expected))) {
    out <- solar_irradiance(expected$condition[i])
    expect_identical(attr(out, "reference_depth_m"),
                     expected$reference_depth_m[i])
    expect_identical(attr(out, "reference_medium"),
                     expected$reference_medium[i])
  }
})

test_that("underwater solar sources record historical Jerlov extrapolation", {
  for (condition in c("underwater_1m", "underwater_10m")) {
    out <- solar_irradiance(condition)
    expect_identical(range(out$wavelength), c(300, 800))
    expect_identical(attr(out, "jerlov_wavelength_policy"), "constant")
    expect_identical(
      attr(out, "jerlov_supported_wavelength_range_nm"), c(350, 700)
    )
    expect_identical(
      attr(out, "jerlov_input_wavelength_range_nm"), c(300, 800)
    )
    expect_match(attr(out, "jerlov_table_checksum_md5"), "^[0-9a-f]{32}$")
  }
})

test_that("invalid bundled source metadata raises a structured error", {
  bad <- solar_spectra[["clear_noon"]]
  attr(bad, "reference_medium") <- "vacuum"

  err <- expect_error(
    luxR:::.validate_solar_source_metadata(bad, "clear_noon"),
    "solar_spectra.*clear_noon.*reference_medium",
    class = "luxR_source_metadata_error"
  )
  expect_identical(err$dataset, "solar_spectra")
  expect_identical(err$source_condition, "clear_noon")
  expect_identical(err$field, "reference_medium")
  expect_identical(err$value, "vacuum")
})

test_that("solar_irradiance clear_noon brighter than overcast at peak", {
  noon    <- solar_irradiance("clear_noon")
  oc      <- solar_irradiance("overcast")
  expect_gt(max(noon$irradiance), max(oc$irradiance))
})

test_that("solar_irradiance throws informative error for unknown condition", {
  expect_error(solar_irradiance("midnight"), "unknown condition")
})

test_that("solar_irradiance lists available conditions when unknown", {
  err <- tryCatch(solar_irradiance("bad"), error = function(e) e$message)
  expect_match(err, "clear_noon")
})

test_that("solar_irradiance composes with broadband2spectrum", {
  spec   <- solar_irradiance("clear_noon")
  result <- broadband2spectrum(500, unit = "W", spectrum = spec)
  expect_s3_class(result, "data.frame")
  expect_true(all(result$irradiance >= 0))
  expect_true(any(result$irradiance > 0))
})

test_that("solar_irradiance composes with lux2irradiance", {
  spec <- solar_irradiance("clear_noon")
  out  <- lux2irradiance(10000, spectrum = spec)
  expect_length(out, nrow(spec))
  expect_true(all(out >= 0))
  expect_true(any(out > 0))
})
