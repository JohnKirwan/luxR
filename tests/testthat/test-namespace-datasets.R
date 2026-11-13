# Package code refers to bundled datasets by bare name. Without attaching
# luxR those names resolve only if they are bound in the namespace itself.

test_that("bundled datasets are bound in the namespace", {
  namespace <- asNamespace("luxR")
  datasets <- get(".BUNDLED_DATASETS", envir = namespace)
  expect_setequal(datasets, utils::data(package = "luxR")$results[, "Item"])
  for (dataset in datasets) {
    expect_true(exists(dataset, envir = namespace, inherits = FALSE),
                info = dataset)
    expect_identical(get(dataset, envir = namespace, inherits = FALSE),
                     getExportedValue("luxR", dataset), info = dataset)
  }
})
