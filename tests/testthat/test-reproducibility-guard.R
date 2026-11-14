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

test_that(".luxr_code_commit reads only the installed DESCRIPTION", {
  sha <- strrep("a1", 20)
  commit <- function(...) luxR:::.luxr_code_commit(list(...))

  expect_identical(commit(RemoteSha = sha), sha)
  expect_identical(commit(GithubSHA1 = sha), sha)
  expect_identical(commit(RemoteSha = sha, GithubSHA1 = strrep("b2", 20)), sha)
  # CRAN installs via pak record the version string as RemoteSha.
  expect_identical(commit(RemoteSha = "0.1.0"), NA_character_)
  expect_identical(commit(), NA_character_)
  expect_identical(luxR:::.luxr_code_commit(NA), NA_character_)

  # An ambient GITHUB_SHA belongs to the caller's repository, not luxR.
  old <- Sys.getenv("GITHUB_SHA", unset = NA_character_)
  on.exit(if (is.na(old)) Sys.unsetenv("GITHUB_SHA")
          else Sys.setenv(GITHUB_SHA = old), add = TRUE)
  Sys.setenv(GITHUB_SHA = sha)
  expect_identical(commit(), NA_character_)
})
