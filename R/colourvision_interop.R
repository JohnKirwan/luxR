# colourvision_interop — reshapers from luxR's lux_spectrum into the plain
# data.frames colourvision consumes (illuminant I, reflectances R1/R2/Rb, and
# the sensitivity matrix C). colourvision has no dedicated spectral class: every
# argument is a data.frame whose first column is wavelength. luxR handles the
# water; colourvision handles the colour-space / visual model. colourvision is
# an optional (Suggests) dependency and its models are never wrapped here.

#' Convert luxR spectra to a colourvision input data frame
#'
#' Reshapes luxR data into the plain data frame \pkg{colourvision} expects for
#' an illuminant (\code{I}) or reflectance (\code{R1}, \code{R2}, \code{Rb}):
#' the first column is wavelength and each remaining column is one spectrum.
#' luxR handles the water (depth propagation, the in-water light field);
#' colourvision handles the colour-space / visual model
#' (\code{RNLmodel()}, \code{CTTKmodel()}, colour spaces). Build the receptor
#' matrix \code{C} with \code{\link{species_sensitivity_matrix}}.
#'
#' Unlike \code{\link{as_rspec}}, this performs no interpolation: colourvision
#' resamples inputs itself via its \code{nm}/\code{interpolate} arguments at
#' model time, so the converter is a pure reshape with no hidden resampling.
#' \pkg{colourvision} is an optional (\code{Suggests}) dependency.
#'
#' @param x A \code{\link{lux_spectrum}}, or a (named) list of them. Every list
#'   element must already share the first spectrum's wavelength grid; mismatched
#'   grids are an error, so resample explicitly before conversion rather than
#'   relying on silent extrapolation.
#' @param name Single-spectrum method only: the value column name. Defaults to
#'   the spectrum's \code{meta$label}, then \code{meta$source}, then \code{"spec"}.
#' @param ... Currently unused; present for method consistency.
#' @return A \code{data.frame} with a \code{wl} column plus one column per
#'   spectrum, ready to pass as colourvision's \code{I}, \code{R1}, \code{R2},
#'   or \code{Rb}.
#' @seealso \code{\link{species_sensitivity_matrix}} for the \code{C} matrix;
#'   \code{\link{as_rspec}} for the pavo equivalent; \code{colourvision::RNLmodel}
#' @examples
#' \dontrun{
#'   I  <- as_colourvision(from_solar("clear_noon"), name = "I")
#' }
#' @export
as_colourvision <- function(x, ...) UseMethod("as_colourvision")

.check_cv_colname <- function(name) {
  if (!is.character(name) || length(name) != 1 || !nzchar(name))
    stop("as_colourvision(): column name must be a single non-empty character string.",
         call. = FALSE)
  if (name == "wl")
    stop("as_colourvision(): \"wl\" is reserved for the wavelength column; rename that spectrum.",
         call. = FALSE)
  name
}

#' @rdname as_colourvision
#' @export
as_colourvision.lux_spectrum <- function(x, name = NULL, ...) {
  if (is.null(name)) {
    name <- x$meta$label
    if (is.null(name)) name <- x$meta$source
    if (is.null(name)) name <- "spec"
  }
  name <- .check_cv_colname(name)
  df <- data.frame(wl = x$lambda, value = x$E)
  names(df)[2] <- name
  df
}

#' @rdname as_colourvision
#' @export
as_colourvision.list <- function(x, ...) {
  if (length(x) == 0 ||
      !all(vapply(x, inherits, logical(1), "lux_spectrum")))
    stop("as_colourvision() requires a non-empty list of lux_spectrum objects.",
         call. = FALSE)
  nms <- names(x)
  if (is.null(nms)) nms <- rep("", length(x))
  blank <- !nzchar(nms)
  nms[blank] <- paste0("spec", seq_along(x))[blank]

  # Validate names: no "wl" (reserved), no duplicates
  if (any(nms == "wl"))
    stop("as_colourvision(): \"wl\" is reserved for the wavelength column; ",
         "rename that spectrum.",
         call. = FALSE)
  dups <- duplicated(nms)
  if (any(dups)) {
    dup_names <- paste0("\"", unique(nms[dups]), "\"", collapse = ", ")
    stop("as_colourvision(): spectrum names must be unique; duplicated: ",
         dup_names, ".",
         call. = FALSE)
  }

  grid <- x[[1]]$lambda
  df <- data.frame(wl = grid)
  for (i in seq_along(x)) {
    if (!identical(x[[i]]$lambda, grid))
      stop("as_colourvision() requires every spectrum to share the first ",
           "spectrum's wavelength grid; element ", i, " (\"", nms[i], "\") ",
           "differs. Resample explicitly (e.g. resample_spectrum()) before ",
           "conversion rather than relying on silent extrapolation.",
           call. = FALSE)
    df[[nms[i]]] <- x[[i]]$E
  }
  df
}

#' Photoreceptor sensitivity matrix for colourvision
#'
#' Assembles a species' validated chromatic receptors into the sensitivity
#' matrix \code{C} that \pkg{colourvision} models consume (a data frame whose
#' first column is wavelength and whose remaining columns are one photoreceptor
#' each). The receptors and their Govardovskii templates are exactly those
#' \code{\link{colour_jnd}} uses, so a colourvision model built on this matrix
#' reproduces luxR's own quantum catches.
#'
#' luxR integrates \strong{photon} catch (proportional to \eqn{E\lambda}) while
#' colourvision integrates energy (\eqn{\int I R C}). With
#' \code{weight = "photon"} (the default) the columns are the sensitivities
#' multiplied by wavelength (\eqn{S\lambda}), so colourvision's energy integral
#' reproduces luxR's photon catch; the proportionality constant cancels in the
#' log RNL model. Use \code{weight = "energy"} for the raw sensitivities.
#'
#' @param species Character scalar naming a species in
#'   \code{species_sensitivities} with at least one validated chromatic receptor.
#' @param lambda Numeric wavelength grid (nm); must be finite, strictly
#'   increasing, and unique. Defaults to \code{seq(300, 700, 1)}, colourvision's
#'   default \code{nm}.
#' @param receptor Optional character vector selecting a subset of the species'
#'   validated chromatic receptors; passed through to the same channel
#'   resolution \code{\link{colour_jnd}} uses.
#' @param weight One of \code{"photon"} (default, columns \eqn{S\lambda}) or
#'   \code{"energy"} (columns \eqn{S}).
#' @return A \code{data.frame} with a \code{wl} column plus one column per
#'   receptor, named and ordered as luxR's channel definitions.
#' @seealso \code{\link{as_colourvision}}, \code{\link{colour_jnd}},
#'   \code{colourvision::RNLmodel}
#' @examples
#' \dontrun{
#'   C <- species_sensitivity_matrix("Apis mellifera")
#' }
#' @export
species_sensitivity_matrix <- function(species,
                                       lambda   = seq(300, 700, 1),
                                       receptor = NULL,
                                       weight   = c("photon", "energy")) {
  weight <- match.arg(weight)

  if (!is.numeric(lambda) || length(lambda) < 2L ||
      anyNA(lambda) || any(!is.finite(lambda)))
    stop("`lambda` must be a finite numeric vector of length >= 2.",
         call. = FALSE)
  if (any(diff(lambda) <= 0))
    stop("`lambda` must be strictly increasing and unique.", call. = FALSE)

  # Same receptor resolution and templates colour_jnd() uses, so a colourvision
  # model on this matrix reproduces luxR's quantum catches.
  recs <- .default_channel_receptors(
    species = species,
    channel_role = "chromatic",
    receptor = receptor
  )

  if (any(recs$receptor == "wl"))
    stop("species_sensitivity_matrix(): a receptor named \"wl\" collides with the reserved wavelength column.",
         call. = FALSE)

  df <- data.frame(wl = lambda)
  for (i in seq_len(nrow(recs))) {
    S <- govardovskii_template(lambda,
                               lambda_max  = recs$lambda_max[i],
                               chromophore = recs$chromophore[i])$S
    if (weight == "photon") S <- S * lambda
    df[[recs$receptor[i]]] <- S
  }
  df
}
