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
#' \code{lux_spectrum}. Non-finite values in the spectrum or in either
#' wavelength grid are an error rather than being dropped.
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
#' @param rule     Out-of-range behaviour for both methods: \code{1}
#'   (default) returns \code{NA}; \code{2} extends with boundary values.
#'   Any other value is an error.
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
  if (length(lambda) < 2L) {
    .luxr_abort(
      paste0("resample_spectrum(): a lux_spectrum needs at least two target ",
             "wavelengths to define its bin width; got ", length(lambda), "."),
      field = "lambda", value = lambda, kind = "value",
      context = x$meta
    )
  }
  binwidth_new <- .grid_binwidth(lambda, NULL, "resample_spectrum()")
  lux_spectrum(E_new, lambda, x$quantity, x$unit, binwidth_new, x$meta)
}

#' @rdname resample_spectrum
#' @export
resample_spectrum.numeric <- function(x, lambda, from = NULL,
                                       method = c("linear", "cubic"),
                                       rule   = 1) {
  if (is.null(from))
    .luxr_abort("'from' (source wavelength grid) is required when 'x' is numeric.", "value")
  method <- match.arg(method)
  out        <- .interp(x, from, lambda, method, rule)
  names(out) <- as.character(lambda)
  out
}

.interp <- function(y, x_from, x_to, method, rule) {
  if (!is.numeric(rule) || length(rule) != 1L || !rule %in% c(1, 2)) {
    .luxr_abort(
      "`rule` must be 1 (NA outside the source range) or 2 (boundary value).",
      field = "rule", value = rule, kind = "value"
    )
  }
  # approx() and spline() drop non-finite points silently, which would narrow
  # the source range, so every input must be finite.
  fail <- .lux_spectrum_fail()
  .check_numeric(y, "x", fail)
  .check_numeric(x_from, "from", fail)
  .check_numeric(x_to, "lambda", fail)
  if (length(y) != length(x_from)) {
    .luxr_abort(
      paste0("`x` has length ", length(y), " but its source wavelength grid ",
             "has length ", length(x_from), "."),
      field = "x", value = length(y), kind = "dimension"
    )
  }
  if (length(x_from) < 2L) {
    .luxr_abort(
      "Interpolation needs at least two source wavelengths.",
      field = "from", value = x_from, kind = "value"
    )
  }
  if (method == "linear") {
    return(stats::approx(x_from, y, xout = x_to, rule = rule)$y)
  }
  out <- stats::spline(x_from, y, xout = x_to, method = "natural")$y
  # A spline extrapolates; outside the source range apply `rule` as approx does.
  outside <- x_to < min(x_from) | x_to > max(x_from)
  out[outside] <- stats::approx(x_from, y, xout = x_to[outside], rule = rule)$y
  out
}
