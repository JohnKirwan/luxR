app_source_path <- function(...) {
  testthat::test_path("..", "..", ...)
}

expect_titles_in_order <- function(path, titles, start_pattern = NULL) {
  expect_true(file.exists(path), info = paste("missing", path))
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  text <- gsub("[[:space:]]+", " ", text)
  if (!is.null(start_pattern)) {
    start <- regexpr(start_pattern, text, fixed = TRUE)[[1L]]
    expect_true(start > 0L, info = paste("missing section marker in", path))
    text <- substring(text, start)
  }
  positions <- vapply(titles, function(title) {
    regexpr(title, text, fixed = TRUE)[[1L]]
  }, integer(1))
  expect_true(all(positions > 0L),
              info = paste("missing app tab title in", path))
  expect_true(all(diff(positions) > 0L),
              info = paste("app tab titles are out of order in", path))
}

test_that("the app tab registry has stable navigation IDs and titles", {
  tabs <- luxR:::.app_tabs()
  expect_identical(
    tabs$id,
    c("depth", "perception", "colour", "visibility", "detection")
  )
  expect_identical(
    tabs$title,
    c("Depth Propagation", "Species Perception", "Colour discrimination",
      "Visibility", "Detection")
  )
  expect_identical(anyDuplicated(tabs$id), 0L)
  expect_identical(anyDuplicated(tabs$title), 0L)
})

test_that("rendered app navigation follows the canonical registry", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- app_source_path("inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")

  app_env <- new.env(parent = globalenv())
  source(file.path(app_dir, "global.R"), local = app_env)
  ui <- source(file.path(app_dir, "ui.R"), local = app_env)$value
  html <- as.character(ui)
  expect_match(html, 'src="logo.png"', fixed = TRUE)
  expect_match(html, 'alt="luxR package logo"', fixed = TRUE)
  values <- regmatches(
    html,
    gregexpr('data-value="[^"]+', html, perl = TRUE)
  )[[1L]]
  values <- unique(sub('^data-value="', "", values))

  tabs <- luxR:::.app_tabs()
  expect_identical(values, tabs$id)
  expect_titles_in_order(file.path(app_dir, "ui.R"), tabs$id)
  expect_titles_in_order(file.path(app_dir, "global.R"),
                         c("APP_TABS", "APP_TAB_TITLES"))
})

test_that("app documentation follows the canonical tab order", {
  titles <- luxR:::.app_tabs()$title
  paths <- c(
    app_source_path("README.md"),
    app_source_path("R", "run_app.R"),
    app_source_path("NEWS.md")
  )
  skip_if(!all(file.exists(paths)),
          "source documentation is unavailable in an installed-package check")
  markers <- c("# Interactive explorer", "#' Opens", "- The Shiny explorer")
  for (i in seq_along(paths)) {
    expect_titles_in_order(paths[[i]], titles, markers[[i]])
  }

  wording <- paste(readLines(app_source_path("README.md"), warn = FALSE),
                   collapse = "\n")
  expect_false(grepl("Species Perception.{0,100}across the water column",
                     wording, perl = TRUE))
  expect_match(wording, "source's stated\\s+reference depth", perl = TRUE)
})

test_that("app results expose scientific context and model assumptions", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir)) app_dir <- app_source_path("inst", "app")
  skip_if(!dir.exists(app_dir), "app dir not found")
  flat <- function(x) paste(unlist(x), collapse = " ")

  shiny::testServer(app_dir, {
    session$setInputs(
      sp_species = "Danio rerio", sp_receptor = "L-cone",
      sp_solar = "underwater_1m", sp_od = 0.4, sp_calc = 1
    )
    perception <- flat(output$sp_qcatch)
    expect_match(perception, "reference 1.0 m in water")
    expect_match(perception, "Not an absolute photons per receptor per second rate")

    session$setInputs(
      jnd_solar = "clear_noon", jnd_wtype = "IA",
      jnd_wavelength_policy = "trim", jnd_depth = 5,
      jnd_species = "Danio rerio", jnd_r1 = "grey", jnd_r2 = "red",
      jnd_calc = 1
    )
    jnd <- flat(output$jnd_out)
    expect_match(jnd, "JND")
    expect_match(jnd, "target 5 m; Jerlov IA")
    expect_match(jnd, "spectral Beer-Lambert propagation")
    expect_match(jnd, "Vorobyev-Osorio receptor-noise")
    expect_match(jnd, "chromatic receptors")

    session$setInputs(
      vis_wtype = "IA", vis_lambda = 550, vis_photic = 0.01,
      vis_contrast = 0.02, vis_use_c = FALSE
    )
    visibility <- flat(output$vis_context)
    expect_match(visibility, "Kd in 1/m")
    expect_match(visibility, "proxy beam attenuation")
    expect_match(visibility, "unvalidated heuristic")

    session$setInputs(
      det_solar = "clear_noon", det_wtype = "IA",
      det_wavelength_policy = "trim", det_depth = 5,
      det_lambda = 490, det_species = "Danio rerio",
      det_obj = "red", det_bg = "grey", det_dir = "horizontal",
      det_contrast = 0.02, det_use_c = FALSE
    )
    detection <- flat(output$det_out)
    expect_match(detection, "target 5 m; Jerlov IA")
    expect_match(detection, "spectral Beer-Lambert propagation")
    expect_match(detection, "sighting wavelength 490 nm")
    expect_match(detection, "validated channel both")
    expect_match(detection, "proxy beam attenuation")
    expect_match(detection, "not empirically validated")
  })
})
