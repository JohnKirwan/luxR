# par.R — Photosynthetically Active Radiation (PAR) quantification

#' PAR irradiance from a spectral irradiance measurement.
#'
#' Integrates spectral irradiance over the photosynthetically active range
#' 400–700 nm and returns the result in µmol photons m\eqn{^{-2}}
#' s\eqn{^{-1}}. Accepts energy units (W m\eqn{^{-2}} nm\eqn{^{-1}}),
#' raw photon counts, or an irradiance \code{lux_spectrum} in any supported
#' irradiance unit. Radiance and reflectance spectra are rejected.
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
#' Each sample is treated as a bin of width \code{binwidth} centred on its
#' wavelength. A bin that straddles 400 or 700 nm contributes only the part
#' inside the PAR window, so the result does not depend on where the grid
#' points fall. The wavelength grid must be regularly spaced and its bins
#' must span 400–700 nm; otherwise an error is raised.
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
#' @param binwidth   Bin width in nm. Inferred from \code{lambda} if
#'   \code{NULL}; if supplied it must equal the wavelength spacing.
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
  .check_same_length(irradiance, lambda, "irradiance", "par_irradiance()")
  w <- .band_widths(lambda, binwidth, 400, 700, "par_irradiance()")
  if (!photonic) irradiance <- W2photon(irradiance, lambda)
  sum(irradiance * w) / (.AVOGADRO * 1e-6)
}

#' @rdname par_irradiance
#' @export
par_irradiance.lux_spectrum <- function(irradiance, ...) {
  x <- .as_energy_irradiance(irradiance, "par_irradiance()")
  par_irradiance.numeric(x$E, x$lambda, photonic = FALSE, binwidth = x$binwidth)
}


#' Fraction of spectral irradiance in the PAR window.
#'
#' Returns the ratio of band-integrated irradiance over 400–700 nm to the
#' total integrated irradiance across the full wavelength range supplied.
#' Useful for characterising how spectrally narrowed a light field has become
#' (e.g. at depth, where red wavelengths are preferentially removed).
#'
#' Samples are bins of width \code{binwidth} centred on their wavelengths, on
#' a regularly spaced grid. A bin straddling 400 or 700 nm contributes only
#' its part inside the PAR window. The grid need not span the whole window.
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
  op <- "par_fraction()"
  .check_same_length(irradiance, lambda, "irradiance", op)
  total <- sum(irradiance * .band_widths(lambda, binwidth, operation = op))
  if (total == 0) return(NA_real_)
  sum(irradiance * .band_widths(lambda, binwidth, 400, 700, op,
                                cover = FALSE)) / total
}

#' @rdname par_fraction
#' @export
par_fraction.lux_spectrum <- function(irradiance, ...) {
  x <- irradiance
  par_fraction.numeric(x$E, x$lambda, binwidth = x$binwidth)
}
