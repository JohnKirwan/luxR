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
  expect_error(luxR:::.luxr_abort(c("a", "b"), "value"),
               class = "luxR_internal_error")
  expect_error(luxR:::.luxr_error_kind(simpleError("x")),
               class = "luxR_internal_error")
})
