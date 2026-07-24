# irradiance2lux_FUN — internal per-bin lux computation

#' Per-bin lux computation (internal).
#'
#' @keywords internal
#' @param W_spec_irradiance Spectral irradiance (W/m^2/nm) at each wavelength bin.
#' @param lambda_measured Bin-centre wavelengths in nm.
#' @param integration_weights Validated finite, positive quadrature weights in
#'   nm, one per measured wavelength.
#' @param LEF_W V(lambda) values from the full luminous efficiency function vector.
#' @param LEF_lambda Wavelength grid matching \code{LEF_W}.
#' @param verbose Logical; emit per-bin diagnostic message if TRUE.
#' @return Numeric vector of lux contributions, one per wavelength bin.
irradiance2lux_FUN <- function(W_spec_irradiance, lambda_measured,
                                integration_weights,
                                LEF_W      = NULL,
                                LEF_lambda = NULL,
                                verbose    = FALSE) {
  if (length(W_spec_irradiance) != length(lambda_measured)) {
    .stop_lux_spectrum_validation(
      paste0("`W_spec_irradiance` and `lambda_measured` must have equal ",
             "length; got ", length(W_spec_irradiance), " and ",
             length(lambda_measured), "."),
      field = c("W_spec_irradiance", "lambda_measured"),
      value = c(length(W_spec_irradiance), length(lambda_measured)),
      subclass = "lux_spectrum_value_error"
    )
  }
  if (!is.numeric(integration_weights) || is.complex(integration_weights) ||
      is.object(integration_weights) || !is.null(dim(integration_weights)) ||
      length(integration_weights) != length(lambda_measured)) {
    .stop_lux_spectrum_validation(
      paste0("`integration_weights` must be a numeric vector with one value ",
             "per wavelength."),
      field = "integration_weights", value = integration_weights,
      subclass = "lux_spectrum_type_error"
    )
  }
  invalid_weight <- which(!is.finite(integration_weights) |
                            integration_weights <= 0)
  if (length(invalid_weight) > 0L) {
    i <- invalid_weight[1L]
    .stop_lux_spectrum_validation(
      paste0("`integration_weights` must be finite and positive; index ", i,
             " is ", format(integration_weights[i]), "."),
      field = "integration_weights", value = integration_weights[i],
      index = i,
      subclass = "lux_spectrum_value_error"
    )
  }
  if (is.null(LEF_W)) {
    LEF_W      <- CIE1931[, "W"]
    LEF_lambda <- CIE1931[, "lambda"]
  }
  LEF_interpolated <- stats::approx(
    x = LEF_lambda,
    y = LEF_W,
    xout = lambda_measured,
    rule = 1
  )$y
  outside_range <- lambda_measured < min(LEF_lambda) |
    lambda_measured > max(LEF_lambda)
  LEF_interpolated[outside_range] <- 0
  if (isTRUE(verbose)) {
    message(
      "Interpolated V(lambda): ",
      paste0(lambda_measured, " nm = ", signif(LEF_interpolated, 3),
             collapse = ", ")
    )
  }
  683 * W_spec_irradiance * integration_weights * LEF_interpolated
}
