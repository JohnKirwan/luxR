test_that("no pinned MD5 or SHA literals live in package functions or constants", {
  ns <- asNamespace("luxR")
  names_all <- ls(ns, all.names = TRUE)

  hex_pattern <- "(?<![0-9a-fA-F])[0-9a-fA-F]{32}(?![0-9a-fA-F])|(?<![0-9a-fA-F])[0-9a-fA-F]{40}(?![0-9a-fA-F])"

  offenders <- character(0)
  for (n in names_all) {
    obj <- get(n, envir = ns)
    src <- if (is.function(obj)) {
      paste(deparse(obj), collapse = "\n")
    } else if (is.character(obj)) {
      paste(obj, collapse = "\n")
    } else {
      next
    }
    if (grepl(hex_pattern, src, perl = TRUE)) {
      offenders <- c(offenders, n)
    }
  }

  expect_identical(offenders, character(0),
                   info = paste("Objects with pinned hex literals:",
                                paste(offenders, collapse = ", ")))
})

test_that(".luxr_code_commit resolves from GITHUB_SHA and falls back to NA", {
  skip_if(!is.null(utils::packageDescription("luxR")[["GithubSHA1"]]),
          "package installed with a pinned GithubSHA1")

  old <- Sys.getenv("GITHUB_SHA", unset = NA_character_)
  on.exit({
    if (is.na(old)) Sys.unsetenv("GITHUB_SHA") else Sys.setenv(GITHUB_SHA = old)
  }, add = TRUE)

  Sys.setenv(GITHUB_SHA = "sentinel-commit-value")
  expect_identical(luxR:::.luxr_code_commit(), "sentinel-commit-value")

  Sys.unsetenv("GITHUB_SHA")
  expect_identical(luxR:::.luxr_code_commit(), NA_character_)
})
