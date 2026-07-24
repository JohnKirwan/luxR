#!/usr/bin/env Rscript

# Validate that luxR's public documentation surface matches its namespace and
# that the generated pkgdown indexes do not point at missing files.

fail <- function(message, ...) {
  commit <- Sys.getenv("GITHUB_SHA", unset = "")
  if (!nzchar(commit)) {
    commit <- tryCatch(
      system2("git", c("rev-parse", "--verify", "HEAD"), stdout = TRUE,
              stderr = FALSE),
      error = function(e) "unavailable"
    )
  }
  pkgdown_version <- if (requireNamespace("pkgdown", quietly = TRUE)) {
    as.character(utils::packageVersion("pkgdown"))
  } else {
    "unavailable"
  }
  config_checksum <- if (file.exists("_pkgdown.yml")) {
    unname(tools::md5sum("_pkgdown.yml"))
  } else {
    "unavailable"
  }
  context <- c(list(...), list(
    code_commit = paste(commit, collapse = ""),
    config = "_pkgdown.yml",
    config_md5 = config_checksum,
    model = paste0("pkgdown ", pkgdown_version),
    random_seed = "not used",
    dataset = "not applicable"
  ))
  details <- if (length(context)) {
    paste0(
      "\n",
      paste(sprintf("  %s: %s", names(context), unlist(context)),
            collapse = "\n")
    )
  } else {
    ""
  }
  stop(paste0(message, details), call. = FALSE)
}

require_file <- function(path) {
  if (!file.exists(path)) {
    fail("Required pkgdown validation input is missing.", path = path)
  }
}

require_file("DESCRIPTION")
require_file("NAMESPACE")
require_file("_pkgdown.yml")

if (!requireNamespace("pkgdown", quietly = TRUE)) {
  fail("The pkgdown package is required for documentation validation.")
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  fail("The jsonlite package is required for documentation validation.")
}

pkg <- pkgdown::as_pkgdown(".")
all_topics <- pkg$topics
topics <- all_topics[!all_topics$internal, , drop = FALSE]

namespace <- readLines("NAMESPACE", warn = FALSE)
exports <- sub(
  "^export\\(([^)]+)\\)$",
  "\\1",
  grep("^export\\([^)]+\\)$", namespace, value = TRUE)
)
s3_methods <- sub(
  "^S3method\\(([^,]+),([^)]+)\\)$",
  "\\1.\\2",
  grep("^S3method\\([^,]+,[^)]+\\)$", namespace, value = TRUE)
)
public_aliases <- unique(c(exports, s3_methods))

is_data <- vapply(
  topics$keywords,
  function(keywords) "datasets" %in% keywords,
  logical(1)
)
is_package_topic <- topics$name == paste0(pkg$package, "-package")
has_public_alias <- vapply(
  topics$alias,
  function(aliases) any(aliases %in% public_aliases),
  logical(1)
)

orphan_topics <- topics$name[!(is_data | is_package_topic | has_public_alias)]
if (length(orphan_topics)) {
  fail(
    "Non-internal function documentation has no exported or registered S3 alias.",
    topics = paste(sort(orphan_topics), collapse = ", "),
    namespace = "NAMESPACE",
    model = as.character(pkg$version)
  )
}

require_file("docs/reference/index.html")
require_file("docs/articles/index.html")
require_file("docs/search.json")
require_file("docs/sitemap.xml")

expected_reference <- sort(all_topics$file_out)
actual_reference <- sort(basename(list.files(
  "docs/reference",
  pattern = "\\.html$",
  full.names = TRUE
)))
actual_reference <- setdiff(actual_reference, "index.html")

missing_reference <- setdiff(expected_reference, actual_reference)
extra_reference <- setdiff(actual_reference, expected_reference)
valid_redirect <- vapply(extra_reference, function(filename) {
  contents <- paste(
    readLines(file.path("docs/reference", filename), warn = FALSE),
    collapse = "\n"
  )
  target <- sub(
    ".*<meta http-equiv=\"refresh\" content=\"0;URL=[^\"]*/reference/([^\"]+)\".*",
    "\\1",
    contents
  )
  !identical(target, contents) && target %in% expected_reference
}, logical(1))
unexpected_reference <- extra_reference[!valid_redirect]
if (length(missing_reference) || length(unexpected_reference)) {
  fail(
    "Generated reference pages do not match current Rd topics.",
    missing = paste(missing_reference, collapse = ", "),
    unexpected = paste(unexpected_reference, collapse = ", "),
    site = normalizePath("docs", mustWork = TRUE)
  )
}

expected_articles <- sort(basename(pkg$vignettes$file_out))
actual_articles <- sort(basename(list.files(
  "docs/articles",
  pattern = "\\.html$",
  full.names = TRUE
)))
actual_articles <- setdiff(actual_articles, "index.html")

missing_articles <- setdiff(expected_articles, actual_articles)
unexpected_articles <- setdiff(actual_articles, expected_articles)
if (length(missing_articles) || length(unexpected_articles)) {
  fail(
    "Generated articles do not match current vignette sources.",
    missing = paste(missing_articles, collapse = ", "),
    unexpected = paste(unexpected_articles, collapse = ", "),
    site = normalizePath("docs", mustWork = TRUE)
  )
}

search <- jsonlite::fromJSON("docs/search.json", simplifyVector = TRUE)
if (!is.data.frame(search) || !"path" %in% names(search)) {
  fail(
    "The pkgdown search index must contain a path field.",
    path = "docs/search.json"
  )
}
search_paths <- unlist(search$path, use.names = FALSE)
if (!length(search_paths) || anyNA(search_paths) ||
    any(!nzchar(search_paths))) {
  fail(
    "The pkgdown search index contains no valid target paths.",
    path = "docs/search.json"
  )
}

sitemap <- paste(readLines("docs/sitemap.xml", warn = FALSE), collapse = "\n")
sitemap_paths <- regmatches(
  sitemap,
  gregexpr("(?<=<loc>)[^<]+(?=</loc>)", sitemap, perl = TRUE)
)[[1L]]
if (identical(sitemap_paths, character(0)) ||
    identical(sitemap_paths, "")) {
  fail("The pkgdown sitemap contains no locations.", path = "docs/sitemap.xml")
}

site_paths <- unique(c(search_paths, sitemap_paths))
site_paths <- sub("^https?://[^/]+", "", site_paths)
site_paths <- sub("[?#].*$", "", site_paths)
site_paths <- sub("^/", "", site_paths)
site_prefix <- sub("^https?://[^/]+/?", "", pkg$meta$url)
site_prefix <- sub("/$", "", site_prefix)
if (nzchar(site_prefix)) {
  prefixed <- startsWith(site_paths, paste0(site_prefix, "/"))
  site_paths[prefixed] <- substring(
    site_paths[prefixed],
    nchar(site_prefix) + 2L
  )
}
site_paths <- site_paths[nzchar(site_paths)]

missing_targets <- site_paths[!file.exists(file.path("docs", site_paths))]
if (length(missing_targets)) {
  fail(
    "Generated search or sitemap entries point to missing site files.",
    targets = paste(sort(unique(missing_targets)), collapse = ", "),
    site = normalizePath("docs", mustWork = TRUE)
  )
}

message(
  "pkgdown surface OK: ", nrow(topics), " public topics, ",
  nrow(pkg$vignettes), " articles, and ", length(site_paths),
  " indexed paths validated."
)
