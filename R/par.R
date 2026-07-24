# par.R — Photosynthetically Active Radiation (PAR) quantification

#' PAR irradiance from a spectral irradiance measurement.
#'
#' Integrates spectral irradiance over the photosynthetically active range
#' 400–700 nm and returns the result in µmol photons m\eqn{^{-2}}
#' s\eqn{^{-1}}. Accepts energy units (W m\eqn{^{-2}} nm\eqn{^{-1}}),
#' raw photon counts, or a \code{lux_spectrum} object in any supported unit.
#'
#' @details
#' PAR is the photon flux integrated over the photosynthetically active range
#' 400–700 nm, expressed in µmol photons m\eqn{^{-2}} s\eqn{^{-1}}. When
#' input is in energy units (W m\eqn{^{-2}} nm\eqn{^{-1}}), each bin is first
#' converted to photon flux via \eqn{N = E\lambda/(hc)}, then the total is
#' divided by Avogadro's constant scaled to µmol:
#' \deqn{Q_{\mathrm{PAR}} = \frac{1}{N_A \times 10^{-6}}
#'       \int_{400}^{700} \frac{E(\lambda)\,\lambda}{hc}\,d\lambda}
#' where \eqn{N_A = 6.022 \times 10^{23}} mol\eqn{^{-1}} and
#' \eqn{hc = 1.98645 \times 10^{-16}} J nm. The result is in
#' µmol photons m\eqn{^{-2}} s\eqn{^{-1}}.
#'
#' @param irradiance Spectral irradiance (W m\eqn{^{-2}} nm\eqn{^{-1}} or
#'   photons s\eqn{^{-1}} m\eqn{^{-2}} nm\eqn{^{-1}}) at each bin, or a
#'   \code{lux_spectrum} object.
#' @param lambda     Wavelength vector in nm (not needed for \code{lux_spectrum}).
#' @param photonic   Logical. If \code{FALSE} (default), input is in
#'   W m\eqn{^{-2}} nm\eqn{^{-1}}. If \code{TRUE}, input is in \emph{raw}
#'   photon counts (photons m\eqn{^{-2}} s\eqn{^{-1}} nm\eqn{^{-1}}), not
#'   molar units. For molar-unit (µmol/m²/s/nm) input, either wrap in a
#'   \code{\link{lux_spectrum}} or convert to W/m²/nm first with
#'   \code{\link{n2W_spec_irradiance}}. Note: \code{photonic = TRUE} means
#'   molar units in \code{\link{n2W_spec_irradiance}} and photon-or-molar
#'   units in \code{\link{irradiance2lux}}.
#' @param binwidth   Bin width in nm. Inferred from \code{lambda} if \code{NULL}.
#' @return Scalar PAR irradiance in µmol photons m\eqn{^{-2}} s\eqn{^{-1}}.
#' @references
#'   Thimijan RW, Heins RD (1983) HortScience 18:818-822.
#' @seealso \code{\link{par_fraction}}, \code{\link{irradiance2lux}},
#'   \code{\link{band_irradiance}}
#' @examples
#' sp  <- solar_irradiance("clear_noon")
#' par_irradiance(sp$irradiance, sp$wavelength)
#' @param ... Ignored.
#' @export
par_irradiance <- function(irradiance, ...) UseMethod("par_irradiance")

#' @rdname par_irradiance
#' @export
par_irradiance.numeric <- function(irradiance, lambda, photonic = FALSE,
                                    binwidth = NULL, ...) {
  idx <- lambda >= 400 & lambda <= 700
  if (!any(idx))
    stop("No wavelengths in PAR range (400-700 nm). Check lambda values.")

  E   <- irradiance[idx]
  lam <- lambda[idx]

  if (is.null(binwidth))
    binwidth <- if (length(lam) > 1) mean(diff(lam)) else 1

  if (!photonic) E <- W2photon(E, lam)
  sum(E * binwidth) / 6.02214076e17
}

#' @rdname par_irradiance
#' @export
par_irradiance.lux_spectrum <- function(irradiance, ...) {
  x <- irradiance
  .PHOTON_UNITS <- c("umol/m2/s/nm", "mmol/m2/s/nm", "mol/m2/s/nm")
  if (x$unit %in% .PHOTON_UNITS)
    x <- convert_unit(x, "W/m2/nm")
  par_irradiance.numeric(x$E, x$lambda, photonic = FALSE, binwidth = x$binwidth)
}


#' Fraction of spectral irradiance in the PAR window.
#'
#' Returns the ratio of band-integrated irradiance over 400–700 nm to the
#' total integrated irradiance across the full wavelength range supplied.
#' Useful for characterising how spectrally narrowed a light field has become
#' (e.g. at depth, where red wavelengths are preferentially removed).
#'
#' @param irradiance Spectral irradiance (any consistent energy unit per nm),
#'   or a \code{lux_spectrum} object.
#' @param lambda     Wavelength vector in nm.
#' @param binwidth   Bin width in nm. Inferred from \code{lambda} if \code{NULL}.
#' @return Numeric scalar in (0, 1].
#' @examples
#' sp <- solar_irradiance("clear_noon")
#' par_fraction(sp$irradiance, sp$wavelength)
#' @param ... Ignored.
#' @export
par_fraction <- function(irradiance, ...) UseMethod("par_fraction")

#' @rdname par_fraction
#' @export
par_fraction.numeric <- function(irradiance, lambda, binwidth = NULL, ...) {
  if (is.null(binwidth))
    binwidth <- if (length(lambda) > 1) mean(diff(lambda)) else 1
  total <- sum(irradiance * binwidth)
  if (total == 0) return(NA_real_)
  idx <- lambda >= 400 & lambda <= 700
  sum(irradiance[idx] * binwidth) / total
}

#' @rdname par_fraction
#' @export
par_fraction.lux_spectrum <- function(irradiance, ...) {
  x <- irradiance
  par_fraction.numeric(x$E, x$lambda, binwidth = x$binwidth)
}
