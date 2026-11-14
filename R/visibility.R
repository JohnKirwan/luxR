# visibility.R — Secchi depth and underwater visual range

#' Secchi depth from diffuse attenuation coefficient(s).
#'
#' Estimates the Secchi disk visibility depth using the Tyler (1968)
#' approximation \eqn{z_S \approx 1.7 / K_d}. When a spectral irradiance
#' is supplied the function first computes an irradiance-weighted mean Kd
#' across 400–700 nm before applying the approximation.
#'
#' By default Kd is weighted by photon flux, because vision responds to
#' photons absorbed. Use \code{basis = "energy"} to weight by radiant energy;
#' this gives more weight to short wavelengths.
#'
#' Each sample is a bin centred on its wavelength on a regular grid; a bin
#' straddling 400 or 700 nm is weighted by its part inside the window.
#'
#' @param Kd         Diffuse attenuation coefficient(s) in 1/m, all positive.
#' @param lambda     Optional wavelength vector (nm) matching \code{Kd}.
#' @param irradiance Optional non-negative spectral irradiance matching
#'   \code{lambda}; supply with \code{lambda}.
#' @param spectrum   Optional \code{lux_spectrum}; when supplied its \code{E}
#'   and \code{lambda} slots replace the \code{irradiance} and \code{lambda}
#'   arguments. Its unit is read from the object; setting \code{photonic}
#'   as well is an error.
#' @param photonic   Logical. \code{FALSE} (default): numeric
#'   \code{irradiance} is in energy units (e.g. W m\eqn{^{-2}}
#'   nm\eqn{^{-1}}). \code{TRUE}: it is a photon or molar flux per nm.
#' @param basis      \code{"photon"} (default) or \code{"energy"}: what
#'   weights Kd.
#' @return Secchi depth in metres.
#' @references
#'   Tyler JE (1968) Limnol. Oceanogr. 13:1-6.
#'   Preisendorfer RW (1986) Limnol. Oceanogr. 31:909-926.
#' @seealso \code{\link{visual_range}}, \code{\link{jerlov_Kd}},
#'   \code{\link{photic_depth}}
#' @examples
#' secchi_depth(jerlov_Kd("IA", lambda = 490))
#' @export
secchi_depth <- function(Kd, lambda = NULL, irradiance = NULL,
                          spectrum = NULL, photonic = FALSE,
                          basis = c("photon", "energy")) {
  op <- "secchi_depth()"
  basis <- match.arg(basis)
  .check_input(Kd, "Kd", op, lower = 0, lower_open = TRUE)
  Kd <- as.vector(Kd)
  binwidth <- NULL
  if (!is.null(spectrum)) {
    if (!is.null(lambda) || !is.null(irradiance)) {
      .luxr_abort(
        paste0(op, ": supply either `spectrum` or `lambda` and `irradiance`, ",
               "not both."),
        field = c("spectrum", "lambda", "irradiance"),
        kind = "value"
      )
    }
    if (!inherits(spectrum, "lux_spectrum")) {
      .luxr_abort(
        paste0(op, ": `spectrum` must be a lux_spectrum; got ",
               paste(class(spectrum), collapse = "/"), "."),
        field = "spectrum", value = class(spectrum),
        kind = "type"
      )
    }
    x <- .as_energy_irradiance(spectrum, op)
    lambda <- x$lambda
    irradiance <- x$E
    binwidth <- x$binwidth
    if (!isFALSE(photonic)) {
      .luxr_abort(
        paste0(op, ": `photonic` applies to numeric `irradiance`; a ",
               "lux_spectrum records its own unit."),
        field = "photonic", value = photonic,
        kind = "value"
      )
    }
  }
  if (is.null(lambda) != is.null(irradiance)) {
    .luxr_abort(
      paste0(op, ": `lambda` and `irradiance` must be supplied together."),
      field = c("lambda", "irradiance"), kind = "value"
    )
  }
  if (is.null(lambda)) return(1.7 / Kd)

  .check_spectral_values(Kd, lambda, "Kd", op)
  irradiance <- .as_basis(irradiance, lambda, photonic, basis, op)
  weight <- irradiance * .band_widths(lambda, binwidth, 400, 700, op,
                                      cover = FALSE)
  if (sum(weight) == 0) {
    .luxr_abort(
      paste0(op, ": irradiance is zero over 400-700 nm, so the weighted Kd ",
             "is undefined."),
      field = "irradiance", value = 0, kind = "value"
    )
  }
  1.7 / (sum(Kd * weight) / sum(weight))
}


#' Heuristic horizontal visual-range estimate in water.
#'
#' Applies the Koschmieder–Berek law to estimate the maximum horizontal
#' sighting distance in water:
#' \eqn{V = -\ln(C_t) / c}
#' where \eqn{C_t} is the inherent contrast threshold and \eqn{c} is the
#' beam attenuation coefficient. Because \eqn{c} is rarely measured directly,
#' a conversion factor \code{kd_to_c} maps diffuse attenuation Kd to \eqn{c}.
#'
#' @param Kd                Diffuse attenuation coefficient in 1/m (scalar or
#'   vector).
#' @param contrast_threshold Inherent contrast threshold of the visual system
#'   or camera (dimensionless, typically 0.01–0.05). Default 0.02.
#' @param kd_to_c           Ratio \eqn{c / K_d}. Typical values: 1.2–1.5 for
#'   clear oceanic water, 2–4 for coastal/turbid water. Default 1.5. Ignored
#'   when \code{beam_c} is supplied.
#' @param beam_c            Optional measured beam attenuation coefficient
#'   \eqn{c} (1/m), e.g. from \code{beam_attenuation()}. When supplied it is used
#'   directly instead of the \code{Kd * kd_to_c} approximation.
#' @details
#' This is a contrast-threshold scenario estimate, not an empirically validated
#' prediction of detection by a particular observer or camera.
#'
#' The coefficient that governs horizontal sighting distance is the beam
#' attenuation coefficient \eqn{c}, not the diffuse attenuation \eqn{K_d}
#' (Johnsen 2012, ch. 5: as you move away from an object, veiling light
#' replaces it at a rate equal to \eqn{c}). If \code{beam_c} is not given, this
#' function approximates \eqn{c = K_d \times} \code{kd_to_c}. Note that
#' \eqn{c > K_d} always, so treating \eqn{K_d} as \eqn{c} (\code{kd_to_c = 1})
#' is an upper bound that overestimates range. The model assumes
#' \strong{horizontal} viewing; for an upward-looking observer the effective
#' coefficient is \eqn{c - K_L} (smaller, so ranges are longer), which is not
#' modelled here.
#' @return Heuristic visual-range estimate in metres. Same length as \code{Kd}.
#' @references
#'   Duntley SQ (1963) Light in the sea. J. Opt. Soc. Am. 53:214–233.
#'
#'   Zaneveld JRV, Pegau WS (2003) Robust underwater visibility parameter.
#'   Opt. Express 11:2997–3009.
#'
#'   Johnsen S (2012) The Optics of Life: A Biologist's Guide to Light in
#'   Nature. Princeton University Press. (Ch. 5: sighting distance and \eqn{c}.)
#' @examples
#' # Visual range for Jerlov IA water at 490 nm
#' visual_range(jerlov_Kd("IA", lambda = 490))
#'
#' # Compare water types
#' types <- c("I", "IA", "II", "C2")
#' sapply(types, function(t) visual_range(jerlov_Kd(t, lambda = 490)))
#' @export
visual_range <- function(Kd, contrast_threshold = 0.02, kd_to_c = 1.5,
                         beam_c = NULL) {
  .validate_detection_numeric(Kd, "Kd", "visual_range", positive = TRUE)
  .validate_detection_threshold(
    contrast_threshold, "contrast_threshold", upper = 1,
    operation = "visual_range"
  )
  .validate_detection_numeric(kd_to_c, "kd_to_c", "visual_range",
                              scalar = TRUE, positive = TRUE)
  if (!is.null(beam_c)) {
    .validate_detection_numeric(beam_c, "beam_c", "visual_range",
                                positive = TRUE)
    if (!(length(beam_c) %in% c(1L, length(Kd))))
      .stop_detection(
        "`beam_c` must be scalar or the same length as `Kd`.",
        field = "beam_c", value = beam_c, operation = "visual_range"
      )
  }
  c_eff <- if (is.null(beam_c)) {
    as.numeric(Kd) * kd_to_c
  } else {
    as.numeric(beam_c)
  }
  out <- -log(contrast_threshold) / c_eff
  if (any(!is.finite(out)) || any(out < 0))
    .stop_detection(
      "The visual-range heuristic produced a non-finite or negative result.",
      "lux_detection_calculation_error", operation = "visual_range",
      Kd = Kd, contrast_threshold = contrast_threshold,
      kd_to_c = kd_to_c, beam_c = beam_c, calculated_range = out
    )
  out
}
