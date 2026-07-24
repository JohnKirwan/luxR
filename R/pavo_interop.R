# pavo_interop — converters between luxR's lux_spectrum and pavo's rspec.
#
# These are the bridge into the pavo ecosystem: luxR handles the water (depth
# propagation, inherent optical properties, the in-water light field) and pavo
# handles the colour space (vismodel, coldist, colspace, plotting). pavo is an
# optional (Suggests) dependency; the converters delegate to pavo so the result
# is a genuine, validated rspec and luxR wraps none of pavo's analysis itself.

.need_pavo <- function() {
  if (!requireNamespace("pavo", quietly = TRUE))
    stop("This function bridges luxR into the 'pavo' package, which is not ",
         "installed.\nInstall it with install.packages(\"pavo\").",
         call. = FALSE)
}

#' Convert luxR spectra to a pavo \code{rspec} object
#'
#' Bridges luxR data into the \pkg{pavo} ecosystem so pavo's colour-space and
#' visual-modelling tools (\code{vismodel()}, \code{coldist()},
#' \code{colspace()}, plotting) can be applied to luxR-derived spectra. The
#' division of labour: luxR handles the water (depth propagation, inherent
#' optical properties, the in-water light field); pavo handles the colour space.
#'
#' Delegates to \code{pavo::as.rspec()}, which validates the input and, by
#' default, interpolates onto a 1 nm grid, so the result is a genuine
#' \code{rspec} object. \pkg{pavo} is an optional (\code{Suggests}) dependency.
#'
#' @param x A \code{\link{lux_spectrum}}, or a (named) list of them — for
#'   example the output of \code{\link{from_trios}}. List elements are
#'   interpolated onto the first spectrum's wavelength grid before merging.
#' @param name Single-spectrum method only: the column name to give the spectrum
#'   in the \code{rspec}. Defaults to the spectrum's \code{meta$label}, then
#'   \code{meta$source}, then \code{"spec"}.
#' @param ... Passed to \code{pavo::as.rspec()} (e.g. \code{lim}, \code{interp}).
#' @return A \pkg{pavo} \code{rspec} data frame: a \code{wl} column plus one
#'   column per spectrum.
#' @seealso \code{\link{as_lux_spectrum}} for the reverse conversion;
#'   \code{pavo::as.rspec}, \code{pavo::vismodel}
#' @examples
#' \dontrun{
#'   # A bundled solar spectrum as an rspec, ready for the pavo toolkit:
#'   r <- as_rspec(from_solar("clear_noon"))
#'
#'   # Several spectra at once (e.g. TriOS radiance scans):
#'   r2 <- as_rspec(from_trios(system.file("extdata/trios.dat", package = "luxR")))
#' }
#' @export
as_rspec <- function(x, ...) UseMethod("as_rspec")

#' @rdname as_rspec
#' @export
as_rspec.lux_spectrum <- function(x, name = NULL, ...) {
  .need_pavo()
  if (is.null(name)) {
    name <- x$meta$label
    if (is.null(name)) name <- x$meta$source
    if (is.null(name)) name <- "spec"
  }
  df <- data.frame(wl = x$lambda, value = x$E)
  names(df)[2] <- name
  pavo::as.rspec(df, ...)
}

#' @rdname as_rspec
#' @export
as_rspec.list <- function(x, ...) {
  .need_pavo()
  if (length(x) == 0 ||
      !all(vapply(x, inherits, logical(1), "lux_spectrum")))
    stop("as_rspec() requires a non-empty list of lux_spectrum objects.")
  nms <- names(x)
  if (is.null(nms)) nms <- rep("", length(x))
  blank <- !nzchar(nms)
  nms[blank] <- paste0("spec", seq_along(x))[blank]
  grid <- x[[1]]$lambda
  df <- data.frame(wl = grid)
  for (i in seq_along(x))
    df[[nms[i]]] <- stats::approx(x[[i]]$lambda, x[[i]]$E, grid, rule = 2)$y
  pavo::as.rspec(df, ...)
}
