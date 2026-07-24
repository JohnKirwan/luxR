make_trios_file <- function(spectra, path) {
  # spectra: list of list(comment, data=data.frame(wv, value))
  lines <- character(0)
  for (s in spectra) {
    lines <- c(lines, paste0("Comment\t", s$comment))
    lines <- c(lines, rep("header_line", 29))
    for (i in seq_len(nrow(s$data))) {
      lines <- c(lines,
        paste(i, s$data$wv[i], s$data$value[i], sep = "\t"))
    }
    lines <- c(lines, "[END]")
  }
  writeLines(lines, path)
  path
}

test_that("read_trios: returns a data.frame with expected columns", {
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp))
  dat <- data.frame(wv = c(350, 400, 450), value = c(0.1, 0.2, 0.3))
  make_trios_file(list(list(comment = "sand_dark_1", data = dat)), tmp)
  result <- read_trios(tmp)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("lambda", "radiance", "spectrum") %in% names(result)))
})

test_that("read_trios: radiance values match file values", {
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp))
  dat <- data.frame(wv = c(350, 400, 450), value = c(1.5, 2.5, 3.5))
  make_trios_file(list(list(comment = "rock_dark_1", data = dat)), tmp)
  result <- read_trios(tmp)
  expect_equal(result$radiance, dat$value * 1e-3)  # mW -> W conversion
})

test_that("read_trios: wavelength column matches file", {
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp))
  dat <- data.frame(wv = c(350, 400, 450, 500), value = c(1, 2, 3, 4))
  make_trios_file(list(list(comment = "sand_light_1", data = dat)), tmp)
  result <- read_trios(tmp)
  expect_equal(result$lambda, dat$wv)
})

test_that("read_trios: multiple spectra parsed as separate groups", {
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp))
  dat <- data.frame(wv = c(400, 500, 600), value = c(1, 2, 3))
  make_trios_file(
    list(
      list(comment = "rock_dark_1",  data = dat),
      list(comment = "rock_light_1", data = dat)
    ), tmp)
  result <- read_trios(tmp)
  expect_equal(length(unique(result$spectrum)), 2L)
  expect_equal(nrow(result), 6L)
})

test_that("read_trios: spectrum label taken from Comment field", {
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp))
  dat <- data.frame(wv = 400:402, value = c(0.5, 0.6, 0.7))
  make_trios_file(list(list(comment = "kelp_dark_2", data = dat)), tmp)
  result <- read_trios(tmp)
  expect_equal(unique(result$spectrum), "kelp_dark_2")
})

test_that("read_trios: error on missing file", {
  expect_error(read_trios("/nonexistent/path.dat"), "does not exist")
})

test_that("read_trios preserves negative raw radiance values", {
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp))
  dat <- data.frame(wv = c(400, 450, 500), value = c(-0.5, 1.0, 2.0))
  make_trios_file(list(list(comment = "sand_dark_1", data = dat)), tmp)
  result <- read_trios(tmp)
  expect_equal(result$radiance, dat$value * 1e-3)
})

test_that("from_trios requires explicit negative preprocessing", {
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp))
  dat <- data.frame(wv = c(400, 450, 500), value = c(-0.5, 1.0, 2.0))
  make_trios_file(list(list(comment = "sand_dark_1", data = dat)), tmp)
  expect_error(from_trios(tmp), class = "luxR_spectrum_value_error")
  result <- from_trios(tmp, negative_policy = "zero")[[1L]]
  expect_equal(result$E, c(0, 0.001, 0.002))
  expect_equal(result$meta$preprocessing$method, "zero_floor")
  expect_identical(result$meta$preprocessing$affected_count, 1L)
})

test_that("read_trios rejects malformed rows instead of skipping them", {
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp))
  lines <- c("Comment\tbroken", rep("header_line", 29),
             "1\t400", "[END]")
  writeLines(lines, tmp)
  error <- expect_error(read_trios(tmp), class = "luxR_spectrum_schema_error")
  expect_identical(error$line, 31L)
  expect_identical(error$spectrum, "broken")
  expect_match(error$source_checksum_md5, "^[0-9a-f]{32}$")
})

test_that("read_trios rejects empty and unterminated blocks", {
  empty <- tempfile(fileext = ".dat")
  unterminated <- tempfile(fileext = ".dat")
  on.exit(unlink(c(empty, unterminated)))
  writeLines(c("Comment\tempty", rep("header_line", 29), "[END]"), empty)
  writeLines(c("Comment\topen", rep("header_line", 29), "1\t400\t2"),
             unterminated)
  expect_error(read_trios(empty), class = "luxR_spectrum_schema_error")
  expect_error(read_trios(unterminated), class = "luxR_spectrum_format_error")
})
