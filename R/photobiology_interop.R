# photobiology_interop — converters between luxR's lux_spectrum and the generic
# spectral classes of the photobiology package.
#
# luxR handles the water (depth propagation, inherent optical properties, the
# in-water light field); photobiology handles generic spectral classes,
# integration, and photometry. photobiology is an optional (Suggests)
# dependency; the converters delegate to its constructors so the result is a
# genuine, validated photobiology object, and luxR reimplements none of its
# analysis.

.need_photobiology <- function() {
  if (!requireNamespace("photobiology", quietly = TRUE))
    stop("This function bridges luxR into the 'photobiology' package, which ",
         "is not installed.\nInstall it with ",
         "install.packages(\"photobiology\").", call. = FALSE)
}

# Every .UNIT_QUANTITIES entry whose quantity is "irradiance", mapped onto the
# photobiology column that carries it. photobiology's s.q.irrad is in
# mol/m2/s/nm, which fixes the factors below.
.PHOTOBIOLOGY_SOURCE_UNITS <- list(
  "W/m2/nm"      = list(column = "s.e.irrad", factor = 1),
  "mol/m2/s/nm"  = list(column = "s.q.irrad", factor = 1),
  "mmol/m2/s/nm" = list(column = "s.q.irrad", factor = 1e-3),
  "umol/m2/s/nm" = list(column = "s.q.irrad", factor = 1e-6)
)

# A one-line origin statement so a spectrum's luxR history survives the handoff
# into another package's ecosystem.
.photobiology_provenance <- function(x) {
  fields <- c("source", "label", "condition", "depth_m", "source_depth_m",
              "jerlov_type")
  present <- fields[vapply(fields,
                           function(f) !is.null(x$meta[[f]]), logical(1))]
  parts <- vapply(present,
                  function(f) paste0(f, "=",
                                     paste(format(x$meta[[f]]),
                                           collapse = ",")),
                  character(1))
  paste0("luxR ", utils::packageVersion("luxR"), ": ", x$quantity,
         " [", x$unit, "]",
         if (length(parts)) paste0("; ", paste(parts, collapse = "; ")) else "")
}

#' Convert luxR spectra to photobiology spectral classes
#'
#' Bridges luxR data into the \pkg{photobiology} ecosystem so its generic
#' spectral classes, integration, and photometry can be applied to luxR-derived
#' spectra. The division of labour: luxR handles the water (depth propagation,
#' inherent optical properties, the in-water light field); photobiology handles
#' generic spectral computation.
#'
#' \code{as_source_spct()} requires spectral irradiance and delegates to
#' \code{photobiology::source_spct()}. Energy units become \code{s.e.irrad} and
#' photon units become \code{s.q.irrad}, rescaled to photobiology's
#' \code{mol/m2/s/nm}. The spectrum is \strong{not} converted between energy and
#' photon bases: it arrives in the basis it already had, and
#' \code{photobiology::e2q()} or \code{q2e()} does any conversion, so only one
#' implementation of that conversion is ever in play.
#'
#' Radiance is refused, because \code{source_spct} has no per-steradian term.
#' \pkg{photobiology} is an optional (\code{Suggests}) dependency.
#'
#' @param x A \code{\link{lux_spectrum}}, or a (named) list of them.
#' @param strict.range Passed to the photobiology constructor. Defaults to
#'   \code{TRUE} so photobiology validates the values independently of luxR.
#' @param ... Passed to the photobiology constructor.
#' @return A \pkg{photobiology} \code{source_spct}.
#' @seealso \code{\link{as_reflector_spct}} for reflectance,
#'   \code{\link{as_lux_spectrum}} for the reverse conversion,
#'   \code{\link{as_rspec}} for the \pkg{pavo} bridge
#' @examples
#' \dontrun{
#'   # The downwelling light field at 15 m, as a photobiology source_spct:
#'   # Jerlov Kd data cover 350-700 nm, so trim before propagating.
#'   surface <- from_solar("clear_noon")[350, 700]
#'   at_depth <- propagate_spectrum(surface, jerlov_Kd("II", surface$lambda),
#'                                  from = 0, to = 15)
#'   s <- as_source_spct(at_depth[["15"]])
#'   photobiology::e_irrad(s)
#' }
#' @export
as_source_spct <- function(x, ...) UseMethod("as_source_spct")

#' @rdname as_source_spct
#' @export
as_source_spct.lux_spectrum <- function(x, strict.range = TRUE, ...) {
  .need_photobiology()
  if (!identical(x$quantity, "irradiance")) {
    hint <- switch(
      x$quantity,
      radiance = paste0(
        "photobiology::source_spct() carries no per-steradian term; convert ",
        "with radiance2irradiance() and state the geometry explicitly."),
      reflectance = "Use as_reflector_spct() for reflectance.",
      paste0("Supported units: ",
             paste(names(.PHOTOBIOLOGY_SOURCE_UNITS), collapse = ", "), "."))
    stop("as_source_spct() requires an irradiance lux_spectrum; got ",
         x$quantity, " [", x$unit, "].\n", hint, call. = FALSE)
  }
  map <- .PHOTOBIOLOGY_SOURCE_UNITS[[x$unit]]
  if (is.null(map))
    stop("Unit '", x$unit, "' has no photobiology source_spct mapping.\n",
         "Supported: ",
         paste(names(.PHOTOBIOLOGY_SOURCE_UNITS), collapse = ", "), ".",
         call. = FALSE)
  provenance <- .photobiology_provenance(x)
  args <- list(w.length = x$lambda, time.unit = "second",
               strict.range = strict.range, comment = provenance)
  args[[map$column]] <- x$E * map$factor
  out <- do.call(photobiology::source_spct, c(args, list(...)))
  out <- photobiology::setWhatMeasured(out, provenance)
  out
}

#' @rdname as_source_spct
#' @export
as_source_spct.list <- function(x, ...) {
  .need_photobiology()
  if (length(x) == 0 ||
      !all(vapply(x, inherits, logical(1), "lux_spectrum")))
    stop("as_source_spct() requires a non-empty list of lux_spectrum objects.",
         call. = FALSE)
  nms <- names(x)
  if (is.null(nms)) nms <- rep("", length(x))
  blank <- !nzchar(nms)
  nms[blank] <- paste0("spec", seq_along(x))[blank]
  out <- lapply(x, as_source_spct, ...)
  names(out) <- nms
  out
}

#' Convert luxR reflectance to a photobiology reflector_spct
#'
#' Bridges a reflectance \code{\link{lux_spectrum}} into \pkg{photobiology} as a
#' \code{reflector_spct}. luxR already constrains reflectance to \code{[0, 1]},
#' so values map onto \code{Rfr} directly.
#'
#' \code{Rfr.type} is required. Whether a reflectance is total or specular is a
#' fact about how it was measured, which luxR does not otherwise carry;
#' defaulting it would silently mislabel the measurement inside another
#' package's ecosystem. Record it once in the spectrum's
#' \code{meta$Rfr_type} to have it picked up automatically.
#'
#' @param x A reflectance \code{\link{lux_spectrum}}, or a (named) list of them.
#' @param Rfr.type Either \code{"total"} or \code{"specular"}. Defaults to
#'   \code{x$meta$Rfr_type}; an error is raised if neither is supplied.
#' @param strict.range Passed to \code{photobiology::reflector_spct()}.
#'   Defaults to \code{TRUE}.
#' @param ... Passed to \code{photobiology::reflector_spct()}.
#' @return A \pkg{photobiology} \code{reflector_spct}.
#' @seealso \code{\link{as_source_spct}}, \code{\link{as_lux_spectrum}}
#' @examples
#' \dontrun{
#'   r <- as_reflector_spct(my_reflectance, Rfr.type = "total")
#' }
#' @export
as_reflector_spct <- function(x, ...) UseMethod("as_reflector_spct")

#' @rdname as_reflector_spct
#' @export
as_reflector_spct.lux_spectrum <- function(x, Rfr.type = NULL,
                                           strict.range = TRUE, ...) {
  .need_photobiology()
  if (!identical(x$quantity, "reflectance")) {
    hint <- if (identical(x$quantity, "irradiance")) {
      "Use as_source_spct() for irradiance."
    } else {
      "Only reflectance can be represented as a reflector_spct."
    }
    stop("as_reflector_spct() requires a reflectance lux_spectrum; got ",
         x$quantity, " [", x$unit, "].\n", hint, call. = FALSE)
  }
  if (is.null(Rfr.type)) Rfr.type <- x$meta$Rfr_type
  if (is.null(Rfr.type))
    stop("`Rfr.type` is required: photobiology records whether a reflectance ",
         "is \"total\" or \"specular\", and luxR will not guess.\n",
         "Pass Rfr.type =, or record meta$Rfr_type on the spectrum.",
         call. = FALSE)
  if (!(is.character(Rfr.type) && length(Rfr.type) == 1L &&
        Rfr.type %in% c("total", "specular")))
    stop("`Rfr.type` must be a single string, either \"total\" or ",
         "\"specular\"; got ", paste(format(Rfr.type), collapse = ", "), ".",
         call. = FALSE)
  provenance <- .photobiology_provenance(x)
  out <- photobiology::reflector_spct(
    w.length = x$lambda, Rfr = x$E, Rfr.type = Rfr.type,
    strict.range = strict.range, comment = provenance, ...
  )
  out <- photobiology::setWhatMeasured(out, provenance)
  out
}

#' @rdname as_reflector_spct
#' @export
as_reflector_spct.list <- function(x, ...) {
  .need_photobiology()
  if (length(x) == 0 ||
      !all(vapply(x, inherits, logical(1), "lux_spectrum")))
    stop("as_reflector_spct() requires a non-empty list of lux_spectrum ",
         "objects.", call. = FALSE)
  nms <- names(x)
  if (is.null(nms)) nms <- rep("", length(x))
  blank <- !nzchar(nms)
  nms[blank] <- paste0("spec", seq_along(x))[blank]
  out <- lapply(x, as_reflector_spct, ...)
  names(out) <- nms
  out
}
