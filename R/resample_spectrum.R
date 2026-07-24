# resample_spectrum — interpolate a spectrum to a new wavelength grid

#' Resample a spectrum to a new wavelength grid
#'
#' Interpolates spectral values onto a target wavelength grid using
#' \code{\link[stats]{approx}} (linear, default) or
#' \code{\link[stats]{spline}} (cubic). The most common use case is
#' harmonising spectra from two instruments before arithmetic or comparison
#' (e.g. aligning a TriOS RAMSES spectrum at 3.3 nm resolution with a
#' Jerlov-based Kd vector at 25 nm steps).
#'
#' @details
#' Values are not extrapolated beyond the source wavelength range. By
#' default (\code{rule = 1}) wavelengths outside that range receive
#' \code{NA}; set \code{rule = 2} to extend using the nearest boundary
#' value instead. Because a \code{lux_spectrum} cannot contain non-finite
#' values, its method raises a validation error when \code{rule = 1} produces
#' \code{NA}. The target grid for a \code{lux_spectrum} must also be strictly
#' increasing and regular. The numeric method can be used to resample raw
#' values from an irregular source grid before constructing a
#' \code{lux_spectrum}.
#'
#' @param x        A \code{lux_spectrum} object or numeric spectral-value
#'   vector.
#' @param lambda   Target wavelength grid in nm (numeric vector). When
#'   \code{x} is a \code{lux_spectrum} this argument is required.
#' @param from     Source wavelength grid in nm. Required when \code{x} is
#'   a numeric vector; ignored when \code{x} is a \code{lux_spectrum}
#'   (wavelengths are taken from \code{x$lambda}).
#' @param method   Interpolation method: \code{"linear"} (default) or
#'   \code{"cubic"}.
#' @param rule     Integer passed to \code{\link[stats]{approx}} controlling
#'   out-of-range behaviour. Default \code{1} (return \code{NA}); use
#'   \code{2} to extend with boundary values.
#' @return A \code{lux_spectrum} (when \code{x} is a \code{lux_spectrum})
#'   or a named numeric vector, resampled onto \code{lambda}.
#' @seealso \code{\link{lux_spectrum}}, \code{\link{as_lux_spectrum}}
#' @examples
#' # Resample a solar spectrum from 10 nm to 5 nm bins
#' sp  <- solar_irradiance("clear_noon")
#' x   <- as_lux_spectrum(sp)
#' x5  <- resample_spectrum(x, lambda = seq(300, 800, by = 5))
#' x5
#'
#' # Align a Jerlov Kd vector to the Naples wavelength grid
#' lam_naples <- from_naples("0m")$lambda
#' lam_naples <- lam_naples[lam_naples >= 350 & lam_naples <= 700]
#' lam_jerlov <- seq(350, 700, by = 25)
#' Kd_coarse  <- jerlov_Kd("II", lam_jerlov)
#' Kd_fine    <- resample_spectrum(Kd_coarse, lambda = lam_naples,
#'                                  from = lam_jerlov, rule = 1)
#' @export
resample_spectrum <- function(x, lambda, from = NULL,
                               method = c("linear", "cubic"),
                               rule   = 1) {
  method <- match.arg(method)
  UseMethod("resample_spectrum")
}

#' @rdname resample_spectrum
#' @export
resample_spectrum.lux_spectrum <- function(x, lambda, from = NULL,
                                            method = c("linear", "cubic"),
                                            rule   = 1) {
  method  <- match.arg(method)
  E_new   <- .interp(x$E, x$lambda, lambda, method, rule)
  binwidth_new <- if (length(lambda) > 1) mean(diff(lambda)) else 1
  lux_spectrum(E_new, lambda, x$quantity, x$unit, binwidth_new, x$meta)
}

#' @rdname resample_spectrum
#' @export
resample_spectrum.numeric <- function(x, lambda, from = NULL,
                                       method = c("linear", "cubic"),
                                       rule   = 1) {
  if (is.null(from))
    stop("'from' (source wavelength grid) is required when 'x' is numeric.")
  method <- match.arg(method)
  out        <- .interp(x, from, lambda, method, rule)
  names(out) <- as.character(lambda)
  out
}

.interp <- function(y, x_from, x_to, method, rule) {
  if (method == "cubic") {
    stats::spline(x_from, y, xout = x_to, method = "natural")$y
  } else {
    stats::approx(x_from, y, xout = x_to, rule = rule)$y
  }
}
