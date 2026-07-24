library(luxR)

test_that("run_app errors informatively when shiny is absent (or finds app dir)", {
  # If shiny is installed, system.file must find the app directory.
  # If shiny is not installed, run_app() stops with an informative message.
  if (requireNamespace("shiny", quietly = TRUE)) {
    app_dir <- system.file("app", package = "luxR")
    expect_true(nzchar(app_dir))
    expect_true(dir.exists(app_dir))
  } else {
    expect_error(run_app(), "Install shiny")
  }
})

test_that("app directory contains ui.R, server.R, global.R", {
  app_dir <- system.file("app", package = "luxR")
  skip_if(!nzchar(app_dir), "app directory not installed")
  expect_true(file.exists(file.path(app_dir, "ui.R")))
  expect_true(file.exists(file.path(app_dir, "server.R")))
  expect_true(file.exists(file.path(app_dir, "global.R")))
})
