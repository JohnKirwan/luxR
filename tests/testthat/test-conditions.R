test_that(".luxr_abort builds the documented class vector", {
  err <- tryCatch(luxR:::.luxr_abort("boom", "value", field = "x", value = 1),
                  error = identity)
  expect_identical(class(err),
                   c("luxR_value_error", "luxR_error", "error", "condition"))
  expect_identical(conditionMessage(err), "boom")
  expect_null(conditionCall(err))
  expect_identical(err$field, "x")
  expect_identical(err$value, 1)
  expect_identical(luxR:::.luxr_error_kind(err), "value")
})

test_that(".luxr_abort adds the import marker after the kind", {
  err <- tryCatch(luxR:::.luxr_abort("bad file", "format", import = TRUE),
                  error = identity)
  expect_identical(class(err), c("luxR_format_error", "luxR_import_error",
                                 "luxR_error", "error", "condition"))
  expect_identical(luxR:::.luxr_error_kind(err), "format")
})

test_that("every kind is raisable and rooted", {
  expect_identical(luxR:::.LUXR_ERROR_KINDS,
    c("type", "value", "dimension", "grid", "unit", "numerical",
      "format", "data", "dependency", "internal"))
  for (k in luxR:::.LUXR_ERROR_KINDS) {
    expect_error(luxR:::.luxr_abort("m", k),
                 class = paste0("luxR_", k, "_error"))
    expect_error(luxR:::.luxr_abort("m", k), class = "luxR_error")
  }
})

test_that(".luxr_abort rejects misuse as an internal error", {
  expect_error(luxR:::.luxr_abort("m", "vaule"), class = "luxR_internal_error")
  expect_error(luxR:::.luxr_abort("m", "value", 1),
               class = "luxR_internal_error")
  expect_error(luxR:::.luxr_abort("m", "value", call = quote(f())),
               class = "luxR_internal_error")
  expect_error(luxR:::.luxr_abort("m", "value", call. = FALSE),
               class = "luxR_internal_error")
  expect_error(luxR:::.luxr_abort("m", "value", import = NA),
               class = "luxR_internal_error")
  expect_error(luxR:::.luxr_abort(1, "value"), class = "luxR_internal_error")
  expect_error(luxR:::.luxr_abort("m", "value", .fields = list(message = "x")),
               class = "luxR_internal_error")
  expect_error(luxR:::.luxr_abort("m", "value", .fields = list(1)),
               class = "luxR_internal_error")
  expect_error(luxR:::.luxr_error_kind(simpleError("x")),
               class = "luxR_internal_error")
})

test_that(".luxr_abort collapses a vector message as stop() would", {
  expect_error(luxR:::.luxr_abort(c("a", "b"), "value"), "^ab$",
               class = "luxR_value_error")
})

test_that(".fields are stored verbatim and cannot rebind arguments", {
  err <- tryCatch(
    luxR:::.luxr_abort("m", "format", import = TRUE,
                       .fields = list(kind = "zzz", value = quote(nope))),
    error = identity
  )
  expect_s3_class(err, "luxR_format_error")
  expect_identical(err$kind, "zzz")
  expect_identical(err$value, quote(nope))
})

test_that("quoted inputs give typed errors and are never evaluated", {
  hit <- new.env()
  expect_error(jerlov_Kd(quote(nope), 500), class = "luxR_type_error")
  expect_error(jerlov_Kd(quote(assign("x", TRUE, envir = hit)), 500),
               class = "luxR_type_error")
  expect_false(exists("x", envir = hit, inherits = FALSE))
  expect_error(degree_of_polarization(quote(nope), 0, 0),
               class = "luxR_type_error")
  expect_error(from_ocean_optics(quote(nope)), class = "luxR_type_error")
})
