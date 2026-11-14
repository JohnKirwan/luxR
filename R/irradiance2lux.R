# irradiance2lux

#' Provide lux values for measures of spectral irradiance.
#'
#' Computes photopic illuminance (lux) by weighting spectral irradiance with
#' the CIE 1931 V(\eqn{\lambda}) luminous efficiency function. The default
#' \code{LEF} argument can be swapped for \code{CIE_scotopic} to obtain
#' scotopic lux, or for any user-supplied spectral sensitivity curve.
#'
#' @details
#' Photopic illuminance is a spectrally weighted integral of irradiance using
#' the CIE 1931 photopic luminous efficiency function \eqn{V(\lambda)}.
#' The maximum luminous efficacy \eqn{K_m = 683} lm W\eqn{^{-1}} occurs at
#' 555 nm:
#' \deqn{E_v = 683 \int_{360}^{830} E(\lambda)\,V(\lambda)\,d\lambda}
#' With the default rectangular method, the integral is approximated as
#' \eqn{E_v \approx 683 \sum_i E(\lambda_i)\,V(\lambda_i)\,\Delta\lambda}.
#' For irregular numeric wavelength grids, callers can explicitly select
#' composite trapezoidal integration. This treats the weighted spectrum as
#' piecewise linear between measured wavelengths and integrates only over
#' \code{[min(lambda), max(lambda)]}; it does not infer outer bin edges.
#' \eqn{V(\lambda)} values are taken from the \code{LEF} data frame by linear
#' interpolation at each measured wavelength. Wavelengths outside the range of
#' the supplied \code{LEF} receive zero weight.
#'
#' @param irradiance Spectral irradiance (\eqn{W\,m^{-2}\,nm^{-1}}{W m^-2 nm^-1} or
#'   \eqn{photons\,m^{-2}\,s^{-1}\,nm^{-1}}{photons m^-2 s^-1 nm^-1}) at each
#'   wavelength bin, or a \code{lux_spectrum} object whose quantity is
#'   \code{"irradiance"}. Photonic \code{lux_spectrum} inputs are converted to
#'   energy units before photometric integration; radiance and reflectance
#'   spectra are rejected.
#' @param lambda Wavelength in nm (not needed for \code{lux_spectrum}).
#' @param photonic Logical; if \code{TRUE}, input is in photon or molar units
#'   — specify which via \code{molar_unit}. Note: \code{photonic = TRUE} means
#'   raw photon counts only in \code{\link{par_irradiance}}, and molar units
#'   only in \code{\link{n2W_spec_irradiance}}.
#' @param molar_unit If photonic, unit string such as \code{"umol"}. Defaults to
#'   \code{"photons"}.
#' @param total Logical; sum per-bin values into a scalar. Defaults to TRUE.
#' @param LEF Luminous efficiency function data frame. Defaults to CIE1931.
#' @param binwidth Wavelength bin width in nm for rectangular integration. For
#'   numeric input, inferred from a regularly spaced wavelength grid when
#'   \code{NULL}. A single-bin input requires an explicit width. Must be
#'   \code{NULL} for trapezoidal integration because the wavelength intervals
#'   determine the integration weights.
#' @param integration Integration method: \code{"rectangle"} (default) retains
#'   the existing bin-centre sum and requires a regular grid;
#'   \code{"trapezoid"} supports strictly increasing regular or irregular
#'   numeric grids with at least two wavelengths.
#' @param verbose Logical; emit diagnostic messages. Defaults to FALSE.
#' @return A scalar lux value (total = TRUE) or numeric vector.
#' @references
#'   CIE Publication 15: Colorimetry, 3rd edn (2004).
#'   Commission Internationale de l'Eclairage, Vienna.
#' @seealso \code{\link{lux2irradiance}}, \code{\link{scotopic_lux}},
#'   \code{\link{par_irradiance}}
#' @examples
#' utils::data(Naples)
#' irradiance2lux(Naples$depth_0m, Naples$wv, photonic = TRUE, molar_unit = "umol")
#' irradiance2lux(c(0.2, 0.8, 0.4), c(500, 515, 540),
#'                integration = "trapezoid")
#' @param ... Ignored.
#' @export
irradiance2lux <- function(irradiance, ...) UseMethod("irradiance2lux")

#' @rdname irradiance2lux
#' @export
irradiance2lux.default <- function(irradiance, ...) {
  .luxr_abort(
    paste0("`irradiance` must be a numeric vector or lux_spectrum; got ",
           paste(class(irradiance), collapse = "/"), "."),
    field = "irradiance", value = irradiance,
    kind = "type"
  )
}

.validate_LEF <- function(LEF) {
  if (!is.data.frame(LEF)) {
    .luxr_abort(
      "`LEF` must be a data frame with numeric `lambda` and `W` columns.",
      kind = "type", field = "LEF", value = LEF
    )
  }
  missing_columns <- setdiff(c("lambda", "W"), names(LEF))
  if (length(missing_columns) > 0L) {
    .luxr_abort(
      paste0("`LEF` is missing required column(s): ",
             paste(missing_columns, collapse = ", "), "."),
      kind = "value", field = "LEF", value = names(LEF)
    )
  }
  if (nrow(LEF) < 2L) {
    .luxr_abort(
      "`LEF` must contain at least two rows for interpolation.",
      kind = "dimension", field = "LEF", value = LEF
    )
  }
  for (field in c("lambda", "W")) {
    values <- LEF[[field]]
    if (!is.numeric(values) || is.complex(values) || is.object(values) ||
        !is.null(dim(values))) {
      .luxr_abort(
        paste0("`LEF$", field, "` must be a numeric vector."),
        kind = "type", field = paste0("LEF$", field), value = values
      )
    }
    invalid <- which(!is.finite(values))
    if (length(invalid) > 0L) {
      i <- invalid[1L]
      .luxr_abort(
        paste0("`LEF$", field, "` must contain only finite values; index ",
               i, " is ", format(values[i]), "."),
        kind = "value", field = paste0("LEF$", field), value = values[i]
      )
    }
  }
  if (any(diff(LEF$lambda) <= 0)) {
    .luxr_abort(
      "`LEF$lambda` must be strictly increasing and unique.",
      kind = "grid", field = "LEF$lambda", value = LEF$lambda
    )
  }
  invisible(LEF)
}

.resolve_photometric_binwidth <- function(irradiance, lambda, binwidth) {
  single_bin_without_width <- length(lambda) == 1L && is.null(binwidth)
  validation_binwidth <- if (single_bin_without_width) 1 else binwidth

  validated <- lux_spectrum(
    E = irradiance,
    lambda = lambda,
    quantity = "irradiance",
    unit = "W/m2/nm",
    binwidth = validation_binwidth
  )

  if (single_bin_without_width) {
    .luxr_abort(
      paste0(
        "`binwidth` is required for a single-bin numeric spectrum because ",
        "it cannot be inferred from one wavelength."
      ),
      field = "binwidth", value = binwidth,
      kind = "grid"
    )
  }
  validated$binwidth
}

.validate_trapezoid_input <- function(irradiance, lambda) {
  fail <- .lux_spectrum_fail()
  .check_numeric(irradiance, "irradiance", fail, lower = 0)
  .check_numeric(lambda, "lambda", fail)

  if (length(irradiance) != length(lambda)) {
    .luxr_abort(
      paste0("`irradiance` and `lambda` must have equal length; got ",
             length(irradiance), " and ", length(lambda), "."),
      field = c("irradiance", "lambda"),
      value = c(length(irradiance), length(lambda)),
      kind = "dimension"
    )
  }

  if (length(lambda) < 2L) {
    .luxr_abort(
      "Trapezoidal integration requires at least two wavelengths.",
      field = "lambda", value = lambda,
      kind = "grid"
    )
  }

  decreasing <- which(diff(lambda) <= 0)
  if (length(decreasing) > 0L) {
    i <- decreasing[1L] + 1L
    .luxr_abort(
      paste0("`lambda` must be strictly increasing and unique; index ", i,
             " has value ", format(lambda[i]), " after ",
             format(lambda[i - 1L]), "."),
      field = "lambda", value = lambda[i], index = i,
      kind = "grid"
    )
  }

  invisible(NULL)
}

.resolve_photometric_weights <- function(irradiance, lambda, binwidth,
                                          integration) {
  if (identical(integration, "rectangle")) {
    width <- .resolve_photometric_binwidth(irradiance, lambda, binwidth)
    return(rep(width, length(lambda)))
  }

  .validate_trapezoid_input(irradiance, lambda)
  if (!is.null(binwidth)) {
    .luxr_abort(
      paste0("`binwidth` must be NULL for trapezoidal integration; ",
             "weights are determined by `lambda`."),
      field = c("binwidth", "integration"),
      value = c(binwidth, integration),
      kind = "grid"
    )
  }

  intervals <- diff(lambda)
  interior_weights <- if (length(intervals) > 1L) {
    (intervals[-length(intervals)] + intervals[-1L]) / 2
  } else {
    numeric()
  }
  c(
    intervals[1L] / 2,
    interior_weights,
    intervals[length(intervals)] / 2
  )
}

#' @rdname irradiance2lux
#' @export
irradiance2lux.numeric <- function(irradiance, lambda,
                                    photonic   = FALSE,
                                    molar_unit = "photons",
                                    total      = TRUE,
                                    LEF        = CIE1931,
                                    binwidth   = NULL,
                                    integration = c("rectangle", "trapezoid"),
                                    verbose    = FALSE, ...) {
  integration <- match.arg(integration)
  .validate_LEF(LEF)
  integration_weights <- .resolve_photometric_weights(
    irradiance, lambda, binwidth, integration
  )
  LEF_W      <- LEF[, "W"]
  LEF_lambda <- LEF[, "lambda"]

  if (isTRUE(verbose))
    message("LEF V(lambda) range: ",
            signif(min(LEF_W), 3), " - ", signif(max(LEF_W), 3),
            " (", nrow(LEF), " bins)")

  if (isTRUE(photonic))
    irradiance <- n2W_spec_irradiance(irradiance, lambda,
                                      photonic   = (molar_unit != "photons"),
                                      molar_unit = molar_unit)

  lx <- irradiance2lux_FUN(
    W_spec_irradiance = irradiance,
    lambda_measured   = lambda,
    integration_weights = integration_weights,
    LEF_W             = LEF_W,
    LEF_lambda        = LEF_lambda,
    verbose           = verbose
  )

  if (isTRUE(total)) sum(lx) else lx
}

#' @rdname irradiance2lux
#' @export
irradiance2lux.lux_spectrum <- function(irradiance,
                                         total   = TRUE,
                                         LEF     = CIE1931,
                                         integration = c("rectangle", "trapezoid"),
                                         verbose = FALSE, ...) {
  integration <- match.arg(integration)
  x <- .as_energy_irradiance(irradiance, "Photometric integration")

  irradiance2lux.numeric(x$E, x$lambda,
                          photonic   = FALSE,
                          total      = total,
                          LEF        = LEF,
                          binwidth   = if (integration == "rectangle") {
                            x$binwidth
                          } else {
                            NULL
                          },
                          integration = integration,
                          verbose    = verbose)
}
