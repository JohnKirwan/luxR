#' Launch the luxR Shiny explorer.
#'
#' Opens an interactive Shiny application for analysing underwater light
#' environments. It has five guided tabs:
#' \itemize{
#'   \item \strong{Depth Propagation} -- attenuate a built-in or uploaded
#'     irradiance spectrum through a Jerlov water type and download the
#'     per-depth lux and photon-flux table.
#'   \item \strong{Species Perception} -- photoreceptor quantum catch for a
#'     chosen species under a selected bundled light-source condition at that
#'     source's stated reference depth.
#'   \item \strong{Colour discrimination} -- Vorobyev-Osorio just-noticeable
#'     difference (JND) between two reflectances under the in-water light field.
#'   \item \strong{Visibility} -- Secchi depth, photic depth, and horizontal
#'     visual-range scenario estimate.
#'   \item \strong{Detection} -- explicitly unvalidated object-background
#'     contrast-threshold distance scenarios.
#' }
#' Requires the \code{shiny} package.
#'
#' @param ... Arguments passed to \code{\link[shiny]{runApp}}.
#' @return Invisible \code{NULL}; called for its side effect of starting the app.
#' @examples
#' \dontrun{
#' run_app()
#' }
#' @export
run_app <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE))
    stop("Install shiny to use the interactive explorer:\n",
         "  install.packages(\"shiny\")")
  app_dir <- system.file("app", package = "luxR")
  if (!nzchar(app_dir))
    stop("App directory not found. Reinstall luxR.")
  invisible(shiny::runApp(app_dir, ...))
}
