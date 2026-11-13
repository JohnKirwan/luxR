# Package-level declarations

#' @importFrom graphics abline legend lines plot
#' @importFrom stats approx median optimize setNames spline
#' @importFrom utils data
NULL

.BUNDLED_DATASETS <- c(
  "CIE1931", "CIE_scotopic",
  "jerlov_types",
  "Naples",
  "solar_spectra",
  "species_sensitivities",
  "species_channels",
  "species_channel_support"
)

utils::globalVariables(.BUNDLED_DATASETS)

# LazyData objects live outside the namespace and are visible to package code
# only while luxR is attached. Bind them lazily into the namespace so
# `luxR::fn()` works without `library(luxR)`.
.onLoad <- function(libname, pkgname) {
  namespace <- parent.env(environment())
  for (dataset in .BUNDLED_DATASETS) {
    local({
      name <- dataset
      delayedAssign(name, getExportedValue(pkgname, name),
                    assign.env = namespace)
    })
  }
}
