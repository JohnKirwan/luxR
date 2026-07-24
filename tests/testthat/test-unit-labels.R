test_that("every unit in the controlled vocabulary has both rendered forms", {
  for (u in luxR:::.VALID_UNITS) {
    expect_type(unit_label(u), "character")
    expect_length(unit_label(u), 1L)
    expect_false(is.na(unit_label(u)))
    expect_true(is.language(unit_expression(u)))
  }
})

test_that("unit_label renders negative exponents, not a solidus", {
  expect_identical(unit_label("W/m2/nm"),
                   "W m\u207b\u00b2 nm\u207b\u00b9")
  expect_identical(unit_label("umol/m2/s/nm"),
                   "\u00b5mol m\u207b\u00b2 s\u207b\u00b9 nm\u207b\u00b9")
  expect_identical(unit_label("mW/m2/sr/nm"),
                   "mW m\u207b\u00b2 sr\u207b\u00b9 nm\u207b\u00b9")
  expect_false(grepl("/", unit_label("umol/m2/s/sr/nm"), fixed = TRUE))
  expect_false(grepl("m2", unit_label("umol/m2/s/sr/nm"), fixed = TRUE))
})

test_that("dimensionless is not given exponents", {
  expect_identical(unit_label("dimensionless"), "dimensionless")
  expect_identical(deparse(unit_expression("dimensionless")),
                   "dimensionless")
})

test_that("unit_expression returns a plotmath object base graphics accepts", {
  e <- unit_expression("umol/m2/s/nm")
  expect_true(is.language(e))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::plot(1, 1)
  expect_gt(graphics::strwidth(e, units = "inches"), 0)
})

test_that("an out-of-vocabulary unit fails fast", {
  expect_error(unit_label("W/m^2/nm"), "controlled vocabulary")
  expect_error(unit_expression("lux"), "controlled vocabulary")
  expect_error(unit_label(character(0)), "single non-NA character")
  expect_error(unit_label(c("W/m2/nm", "W/m2/nm")),
               "single non-NA character")
  expect_error(unit_label(NA_character_), "single non-NA character")
})

test_that("plot methods label the y axis with a rendered unit", {
  x <- lux_spectrum(rep(1, 3), c(400, 500, 600),
                    "irradiance", "umol/m2/s/nm", binwidth = 100)

  seen <- NULL
  testthat::local_mocked_bindings(
    plot = function(...) {
      seen <<- list(...)$ylab
      graphics::plot.new()
      graphics::plot.window(xlim = c(0, 1), ylim = c(0, 1))
      invisible(NULL)
    },
    .package = "base"
  )

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)

  plot(x)
  expect_true(is.language(seen))
  expect_identical(deparse(seen),
                   deparse(unit_expression("umol/m2/s/nm")))

  seen <- NULL
  plot_spectra(list(a = x, b = x))
  expect_true(is.language(seen))
  expect_identical(deparse(seen),
                   deparse(unit_expression("umol/m2/s/nm")))
})
