library(luxR)

test_that("jerlov_Kd returns data frame for known type without lambda", {
  result <- jerlov_Kd("IA")
  expect_s3_class(result, "data.frame")
  expect_true(all(c("type", "lambda", "Kd") %in% names(result)))
  expect_true(all(result$type == "IA"))
  expect_true(all(result$Kd > 0))
})

test_that("jerlov_Kd is case-insensitive", {
  expect_equal(jerlov_Kd("ia"), jerlov_Kd("IA"))
  expect_equal(jerlov_Kd("ib"), jerlov_Kd("IB"))
})

test_that("jerlov_Kd interpolates to requested wavelengths", {
  result <- jerlov_Kd("IA", lambda = c(400, 450, 500))
  expect_type(result, "double")
  expect_length(result, 3)
  expect_true(all(result > 0))
})

test_that("jerlov_Kd linear interpolation returns value between neighbours", {
  kd_400 <- jerlov_Kd("IA", lambda = 400)
  kd_450 <- jerlov_Kd("IA", lambda = 450)
  kd_425 <- jerlov_Kd("IA", lambda = 425)
  expect_gte(kd_425, min(kd_400, kd_450))
  expect_lte(kd_425, max(kd_400, kd_450))
})

test_that("jerlov_Kd clearer water has lower Kd at blue wavelengths", {
  kd_I  <- jerlov_Kd("I",  lambda = 450)
  kd_IA <- jerlov_Kd("IA", lambda = 450)
  kd_II <- jerlov_Kd("II", lambda = 450)
  kd_C2 <- jerlov_Kd("C2", lambda = 450)
  expect_lt(kd_I, kd_IA)
  expect_lt(kd_IA, kd_II)
  expect_lt(kd_II, kd_C2)
})

test_that("jerlov_Kd throws informative error for unknown type", {
  expect_error(jerlov_Kd("Z"),  "unknown Jerlov type")
  expect_error(jerlov_Kd("IV"), "unknown Jerlov type")
})

test_that("jerlov_Kd composes with attenuate_spectrum", {
  lam <- c(450, 500, 550, 600)
  E0  <- rep(1, length(lam))
  Kd  <- jerlov_Kd("IA", lambda = lam)
  expect_no_error(attenuate_spectrum(E0, Kd, depths = c(10, 50), lambda = lam))
})

test_that("jerlov_Kd spline interpolation returns positive values", {
  result <- jerlov_Kd("I", lambda = seq(400, 700, by = 5), interp = "spline")
  expect_true(all(result > 0))
})

test_that("jerlov_types records a machine-readable supported domain", {
  expect_identical(
    attr(jerlov_types, "supported_wavelength_range_nm", exact = TRUE),
    c(350, 700)
  )
  expect_identical(attr(jerlov_types, "wavelength_step_nm", exact = TRUE), 25)
  expect_match(
    attr(jerlov_types, "table_checksum_md5", exact = TRUE),
    "^[0-9a-f]{32}$"
  )
  expect_match(
    attr(jerlov_types, "build_commit", exact = TRUE),
    "^[0-9a-f]{40}$"
  )
})

test_that("jerlov_Kd accepts exact domain boundaries for every method", {
  for (method in c("linear", "spline", "nearest")) {
    result <- jerlov_Kd("IA", c(350, 700), interp = method)
    expect_equal(as.numeric(result), c(0.076, 0.558))
    metadata <- attr(result, "luxR.jerlov", exact = TRUE)
    expect_identical(metadata$type, "IA")
    expect_identical(metadata$interp, method)
    expect_identical(metadata$extrapolation, "error")
    expect_identical(metadata$supported_wavelength_range_nm, c(350, 700))
    expect_identical(metadata$requested_wavelength_range_nm, c(350, 700))
    expect_false(metadata$extrapolated)
    expect_identical(metadata$extrapolated_wavelength_count, 0L)
    expect_match(metadata$table_checksum_md5, "^[0-9a-f]{32}$")
    expect_match(metadata$build_commit, "^[0-9a-f]{40}$")
  }
})

test_that("in-range Jerlov interpolation always records provenance", {
  result <- jerlov_Kd("II", c(425, 500, 675))
  metadata <- attr(result, "luxR.jerlov", exact = TRUE)

  expect_type(metadata, "list")
  expect_identical(metadata$type, "II")
  expect_identical(metadata$interp, "linear")
  expect_identical(metadata$extrapolation, "error")
  expect_identical(metadata$requested_wavelength_range_nm, c(425, 675))
  expect_false(metadata$extrapolated)
})

test_that("jerlov_Kd fails outside its supported range by default", {
  for (wavelength in c(350 - .Machine$double.eps^0.5, 349, 701,
                       700 + .Machine$double.eps^0.5)) {
    error <- expect_error(
      jerlov_Kd("IA", wavelength),
      "support wavelengths from 350 to 700",
      class = "luxR_jerlov_range_error"
    )
    expect_identical(error$field, "lambda")
    expect_identical(error$value, wavelength)
    expect_identical(error$supported_wavelength_range_nm, c(350, 700))
    expect_match(error$table_checksum_md5, "^[0-9a-f]{32}$")
    expect_match(error$build_commit, "^[0-9a-f]{40}$")
  }
})

test_that("jerlov_Kd identifies the first invalid wavelength", {
  error <- expect_error(
    jerlov_Kd("II", c(400, 701, 300)),
    "lambda\\[2\\].*701",
    class = "luxR_jerlov_range_error"
  )
  expect_identical(error$index, 2L)
  expect_identical(error$requested_wavelength_range_nm, c(300, 701))
  expect_identical(error$type, "II")
  expect_identical(error$interp, "linear")
  expect_identical(error$extrapolation, "error")
})

test_that("jerlov_Kd validates type and wavelength inputs", {
  expect_error(jerlov_Kd(c("IA", "II")), class = "luxR_jerlov_input_error")
  expect_error(jerlov_Kd(1), class = "luxR_jerlov_input_error")
  expect_error(jerlov_Kd("IA", numeric()), class = "luxR_jerlov_input_error")
  expect_error(jerlov_Kd("IA", "500"), class = "luxR_jerlov_input_error")
  for (value in c(NA_real_, NaN, Inf, -Inf)) {
    expect_error(
      jerlov_Kd("IA", value),
      "finite wavelengths",
      class = "luxR_jerlov_input_error"
    )
  }
})

test_that("constant Jerlov extrapolation is explicit and recorded", {
  for (method in c("linear", "spline", "nearest")) {
    result <- jerlov_Kd(
      "IA", c(300, 350, 700, 800),
      interp = method, extrapolation = "constant"
    )
    expect_equal(as.numeric(result), c(0.076, 0.076, 0.558, 0.558))
    metadata <- attr(result, "luxR.jerlov")
    expect_true(metadata$extrapolated)
    expect_identical(metadata$extrapolated_wavelength_count, 2L)
    expect_identical(metadata$extrapolation, "constant")
    expect_identical(metadata$requested_wavelength_range_nm, c(300, 800))
    expect_match(metadata$table_checksum_md5, "^[0-9a-f]{32}$")
  }
})

# Independent physical-structure validation of bundled jerlov_types Kd values.
# The numeric values are the Solonenko & Mobley (2015) digitization already
# checksummed in data-raw/dataset_manifest.csv (DOI 10.1364/AO.54.005392), so
# re-transcribing that table would be circular. These checks instead assert
# ocean-optics structure that holds regardless of digitization:
#   * turbidity ordering across water types (Jerlov 1976; Mobley 1994);
#   * blue-minimum spectral shape driven by pure-water absorption;
#   * clearest-water bound (Smith & Baker 1981; Morel 1974).

test_that("Kd increases monotonically across turbidity order in the blue-green", {
  ord <- c("I", "IA", "IB", "II", "III", "C1", "C2", "C3")
  for (w in c(450, 475, 500)) {
    k <- vapply(ord, function(t)
      jerlov_types$Kd[jerlov_types$type == t & jerlov_types$lambda == w],
      numeric(1))
    expect_true(all(diff(k) > 0),
                info = paste("wavelength", w, "not strictly increasing"))
  }
})

test_that("clear oceanic types have a blue minimum and strong red rise", {
  for (t in c("I", "IA", "IB")) {
    sub    <- jerlov_types[jerlov_types$type == t, ]
    blue   <- sub$Kd[sub$lambda <= 500]
    red675 <- sub$Kd[sub$lambda == 675]
    kd450  <- sub$Kd[sub$lambda == 450]
    expect_equal(min(sub$Kd), min(blue),
                 info = paste("type", t, "minimum not in the blue"))
    expect_gt(red675, 10 * kd450)   # pure-water absorption dominates the red
  }
})

test_that("clearest-water Kd sits in the accepted clear-ocean range", {
  # Smith & Baker (1981) / Morel (1974): clearest natural seawater Kd in the
  # blue is roughly 0.01-0.03 /m. Type I is Jerlov's clearest water.
  blue_I <- jerlov_types$Kd[jerlov_types$type == "I" &
                              jerlov_types$lambda >= 450 &
                              jerlov_types$lambda <= 490]
  expect_true(all(blue_I >= 0.005 & blue_I <= 0.035),
              info = "type I blue Kd outside clearest-water range")
})
