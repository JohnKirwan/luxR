library(luxR)

lam10 <- seq(400, 700, by = 10)
lam5  <- seq(400, 700, by = 5)
E10   <- sin(seq(0, pi, length.out = length(lam10)))
x10   <- lux_spectrum(E10, lam10, "irradiance", "W/m2/nm")

# ---- numeric method -------------------------------------------------------

test_that("resample_spectrum.numeric: known points are reproduced exactly", {
  result <- resample_spectrum(E10, lam5, from = lam10)
  # original grid points must survive unchanged
  at_orig <- result[as.character(lam10)]
  expect_equal(unname(at_orig), E10, tolerance = 1e-10)
})

test_that("resample_spectrum.numeric: returns named numeric", {
  result <- resample_spectrum(E10, lam5, from = lam10)
  expect_type(result, "double")
  expect_named(result)
  expect_length(result, length(lam5))
})

test_that("resample_spectrum.numeric: rule=1 gives NA outside range", {
  lam_wide <- seq(350, 750, by = 10)
  result   <- resample_spectrum(E10, lam_wide, from = lam10, rule = 1)
  expect_true(is.na(result["350"]))
  expect_true(is.na(result["750"]))
})

test_that("resample_spectrum.numeric: rule=2 extends with boundary values", {
  lam_wide <- seq(350, 750, by = 10)
  result   <- resample_spectrum(E10, lam_wide, from = lam10, rule = 2)
  expect_false(is.na(result["350"]))
})

test_that("resample_spectrum.numeric: errors without 'from'", {
  expect_error(resample_spectrum(E10, lam5), "'from'")
})

# ---- lux_spectrum method --------------------------------------------------

test_that("resample_spectrum.lux_spectrum: returns lux_spectrum", {
  result <- resample_spectrum(x10, lam5)
  expect_s3_class(result, "lux_spectrum")
})

test_that("resample_spectrum.lux_spectrum: unit and quantity preserved", {
  result <- resample_spectrum(x10, lam5)
  expect_equal(result$unit,     x10$unit)
  expect_equal(result$quantity, x10$quantity)
})

test_that("resample_spectrum.lux_spectrum: binwidth updated to target grid", {
  result <- resample_spectrum(x10, lam5)
  expect_equal(result$binwidth, 5)
})

test_that("resample_spectrum.lux_spectrum: known points reproduced exactly", {
  result  <- resample_spectrum(x10, lam5)
  at_orig <- result$E[result$lambda %in% lam10]
  expect_equal(at_orig, E10, tolerance = 1e-10)
})

test_that("resample_spectrum.lux_spectrum: cubic method runs without error", {
  result <- resample_spectrum(x10, lam5, method = "cubic")
  expect_s3_class(result, "lux_spectrum")
  expect_length(result$E, length(lam5))
})

test_that("resample_spectrum.lux_spectrum: rejects non-finite extrapolation", {
  lam_wide <- seq(350, 750, by = 10)
  expect_error(
    resample_spectrum(x10, lam_wide, rule = 1),
    "finite values",
    class = "lux_spectrum_value_error"
  )
  expect_no_error(resample_spectrum(x10, lam_wide, rule = 2))
})

test_that("resample_spectrum.lux_spectrum: rejects irregular target grids", {
  expect_error(
    resample_spectrum(x10, c(400, 410, 425, 440), rule = 2),
    "regularly spaced",
    class = "lux_spectrum_grid_error"
  )
})

test_that("resample_spectrum: Kd coarsening use-case works", {
  lam_naples <- from_naples("0m")$lambda
  lam_naples <- lam_naples[lam_naples >= 350 & lam_naples <= 700]
  lam_jerlov <- seq(350, 700, by = 25)
  Kd_coarse  <- jerlov_Kd("II", lam_jerlov)
  Kd_fine    <- resample_spectrum(Kd_coarse, lam_naples, from = lam_jerlov,
                                   rule = 1)
  expect_length(Kd_fine, length(lam_naples))
  expect_true(all(!is.na(Kd_fine)))
})
