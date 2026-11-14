test_that(".grid_binwidth returns the spacing of a regular grid", {
  expect_equal(.grid_binwidth(seq(400, 700, 10), operation = "f()"), 10)
  expect_equal(.grid_binwidth(550, 5, operation = "f()"), 5)
})

test_that(".grid_binwidth rejects bad grids", {
  expect_error(.grid_binwidth(c(400, 410, 430), operation = "f()"),
               class = "luxR_grid_error")
  expect_error(.grid_binwidth(c(410, 400), operation = "f()"),
               class = "luxR_grid_error")
  expect_error(.grid_binwidth(550, operation = "f()"),
               class = "luxR_value_error")
  expect_error(.grid_binwidth(seq(400, 700, 10), 5, operation = "f()"),
               class = "luxR_grid_error")
})

test_that(".check_input prefixes the operation", {
  expect_error(.check_input(NA_real_, "Kd", "g()"), "^g\\(\\): `Kd`",
               class = "luxR_value_error")
})
