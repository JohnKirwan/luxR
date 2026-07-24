test_that("michelson_contrast: equal intensities gives 0", {
  expect_equal(michelson_contrast(5, 5), 0)
})

test_that("michelson_contrast: black background gives 1", {
  expect_equal(michelson_contrast(10, 0), 1)
})

test_that("michelson_contrast: formula (I_max - I_min)/(I_max + I_min)", {
  expect_equal(michelson_contrast(8, 2), (8 - 2) / (8 + 2))
})

test_that("michelson_contrast: result in [0, 1]", {
  bright <- runif(20, 0.5, 1)
  dark   <- runif(20, 0, 0.5)
  expect_true(all(michelson_contrast(bright, dark) >= 0))
  expect_true(all(michelson_contrast(bright, dark) <= 1))
})

test_that("michelson_contrast: vectorised over equal-length inputs", {
  bright <- c(10, 20, 30)
  dark   <- c(5,  10, 10)
  expected <- (bright - dark) / (bright + dark)
  expect_equal(michelson_contrast(bright, dark), expected)
})

test_that("michelson_contrast: error when both zero", {
  expect_error(michelson_contrast(0, 0), "zero")
})

test_that("michelson_contrast: error when bright < dark", {
  expect_error(michelson_contrast(3, 7), "bright")
})

test_that("weber_contrast: target equals background gives 0", {
  expect_equal(weber_contrast(5, 5), 0)
})

test_that("weber_contrast: formula (I_target - I_background)/I_background", {
  expect_equal(weber_contrast(12, 8), (12 - 8) / 8)
})

test_that("weber_contrast: can be negative (target darker than background)", {
  expect_lt(weber_contrast(3, 10), 0)
})

test_that("weber_contrast: vectorised", {
  target <- c(10, 5, 20)
  bg     <- c(8, 8, 8)
  expect_equal(weber_contrast(target, bg), (target - bg) / bg)
})

test_that("weber_contrast: error when background is zero", {
  expect_error(weber_contrast(5, 0), "zero")
})
