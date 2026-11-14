# Internal metadata for the bundled Shiny application. This is the canonical
# source for tab identity, order, and display titles.

#' Bundled Shiny application tabs
#' @keywords internal
#' @noRd
.app_tabs <- function() {
  tabs <- data.frame(
    id = c("depth", "perception", "colour", "visibility", "detection"),
    title = c(
      "Depth Propagation",
      "Species Perception",
      "Colour discrimination",
      "Visibility",
      "Detection"
    ),
    stringsAsFactors = FALSE
  )

  .validate_app_tabs(tabs)
  tabs
}

.validate_app_tabs <- function(tabs) {
  if (anyDuplicated(tabs$id) || anyDuplicated(tabs$title) ||
      any(!nzchar(tabs$id)) || any(!nzchar(tabs$title))) {
    .luxr_abort(
      "The Shiny tab registry must contain unique, non-empty IDs and titles.",
      "internal"
    )
  }
  invisible(tabs)
}
