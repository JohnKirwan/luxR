# n2W_spec_irradiance

#' Convert photon-count spectral irradiance to \eqn{W\,m^{-2}\,nm^{-1}}.
#'
#' Converts per-bin photon flux (photons m\eqn{^{-2}} s\eqn{^{-1}}
#' nm\eqn{^{-1}}, or molar equivalents) to energy-based spectral irradiance
#' in W m\eqn{^{-2}} nm\eqn{^{-1}}. The inverse operation is
#' \code{\link{W2mol_spec_irradiance}}.
#'
#' @details
#' Each photon at wavelength \eqn{\lambda} carries energy \eqn{E = hc/\lambda}.
#' Spectral irradiance in W m\eqn{^{-2}} nm\eqn{^{-1}} is therefore the photon
#' flux \eqn{N} (photons m\eqn{^{-2}} s\eqn{^{-1}} nm\eqn{^{-1}}) multiplied by
#' the per-photon energy:
#' \deqn{E(\lambda) = N(\lambda) \cdot \frac{hc}{\lambda}}
#' where \eqn{h = 6.626 \times 10^{-34}} J s (Planck constant) and
#' \eqn{c = 2.998 \times 10^8} m s\eqn{^{-1}} (speed of light). The constant
#' \eqn{hc} in nm-compatible units is \eqn{1.98645 \times 10^{-16}} J nm, the
#' value used internally.
#'
#' @param value Spectral irradiance in \eqn{photons\,m^{-2}\,s^{-1}\,nm^{-1}}
#'   (or molar units), or a
#'   \code{lux_spectrum} with a photonic irradiance or radiance unit.
#' @param lambda Wavelength in nm for each bin.
#' @param photonic Logical; if \code{TRUE}, \code{value} is in molar units
#'   (\eqn{\mu mol}, mmol, or \eqn{mol\,m^{-2}\,s^{-1}\,nm^{-1}}) — specify
#'   which via \code{molar_unit}.
#'   Defaults to \code{FALSE}. Note: \code{photonic = TRUE} means raw photon
#'   counts in \code{\link{par_irradiance}}, and photon-or-molar units in
#'   \code{\link{irradiance2lux}}.
#' @param molar_unit Molar unit string (e.g. \code{"umol"}). Defaults to
#'   \code{"photons"}.
#' @return Numeric vector of spectral irradiance in \eqn{W\,m^{-2}\,nm^{-1}}, or a
#'   \code{lux_spectrum} with \code{unit = "W/m2/nm"} or
#'   \code{"W/m2/sr/nm"} according to the input dimensionality.
#' @examples
#' utils::data(Naples)
#' n2W_spec_irradiance(Naples$depth_0m, Naples$wv, photonic = TRUE, molar_unit = "umol")
#' @param ... Ignored.
#' @export
n2W_spec_irradiance <- function(value, ...) UseMethod("n2W_spec_irradiance")

#' @rdname n2W_spec_irradiance
#' @export
n2W_spec_irradiance.numeric <- function(value, lambda,
                                         photonic   = FALSE,
                                         molar_unit = "photons", ...) {
  if (isTRUE(photonic))
    value <- mapply(mol2photon_FUN, value, molar_unit)
  mapply(n2W_spec_irradiance_FUN, value, lambda)
}

#' @rdname n2W_spec_irradiance
#' @export
n2W_spec_irradiance.lux_spectrum <- function(value, ...) {
  x             <- value
  .PHOTON_UNITS <- c("umol/m2/s/nm", "mmol/m2/s/nm", "mol/m2/s/nm",
                     "umol/m2/s/sr/nm", "mmol/m2/s/sr/nm",
                     "mol/m2/s/sr/nm")
  if (!x$unit %in% .PHOTON_UNITS)
    stop("n2W_spec_irradiance requires a photonic unit; x$unit is '",
         x$unit, "'.")
  radiance <- grepl("/sr/", x$unit, fixed = TRUE)
  mu   <- sub("/m2/s/sr/nm", "", x$unit, fixed = TRUE)
  mu   <- sub("/m2/s/nm", "", mu, fixed = TRUE)
  Enew <- n2W_spec_irradiance.numeric(x$E, x$lambda,
                                       photonic = TRUE, molar_unit = mu)
  new_unit <- if (radiance) "W/m2/sr/nm" else "W/m2/nm"
  lux_spectrum(Enew, x$lambda, x$quantity, new_unit, x$binwidth, x$meta)
}


#' Convert energy spectral irradiance to molar photon flux.
#'
#' Converts W m\eqn{^{-2}} nm\eqn{^{-1}} spectral irradiance to a
#' photon-count flux expressed in molar units (mol, mmol, or \eqn{\mu mol} photons
#' m\eqn{^{-2}} s\eqn{^{-1}} nm\eqn{^{-1}}). The inverse operation is
#' \code{\link{n2W_spec_irradiance}}. The same per-bin conversion factor
#' applies to spectral radiance (W m\eqn{^{-2}} sr\eqn{^{-1}}
#' nm\eqn{^{-1}}).
#'
#' @details
#' The inverse of \code{\link{n2W_spec_irradiance}}: photon flux is recovered
#' via \eqn{N = E\lambda/(hc)}, then divided by Avogadro's constant scaled to
#' the requested molar unit:
#' \deqn{\Phi(\lambda) = \frac{E(\lambda)\,\lambda}{hc\,N_A} \times s}
#' where \eqn{N_A = 6.022 \times 10^{23}} mol\eqn{^{-1}} and \eqn{s = 10^6}
#' for \code{"umol"}, \eqn{10^3} for \code{"mmol"}, or \eqn{1} for \code{"mol"}.
#'
#' @param W          Spectral irradiance in \eqn{W\,m^{-2}\,nm^{-1}}, or a \code{lux_spectrum}
#'   with an energy irradiance or radiance unit.
#' @param lambda     Wavelength in nm for each bin.
#' @param molar_unit Target molar unit: \code{"umol"}, \code{"mmol"}, or
#'   \code{"mol"}. Default \code{"umol"}.
#' @return Numeric vector of photon flux in the requested molar unit per nm,
#'   or a \code{lux_spectrum} with the updated unit. Radiance outputs retain
#'   the \code{"/sr"} term.
#' @examples
#' sp <- solar_irradiance("clear_noon")
#' W2mol_spec_irradiance(sp$irradiance, sp$wavelength, molar_unit = "umol")
#' @param ... Ignored.
#' @export
W2mol_spec_irradiance <- function(W, ...) UseMethod("W2mol_spec_irradiance")

#' @rdname W2mol_spec_irradiance
#' @export
W2mol_spec_irradiance.numeric <- function(W, lambda, molar_unit = "umol", ...) {
  photons         <- W2photon(W, lambda)
  photons_per_mol <- mol2photon_FUN(1, molar_unit)
  photons / photons_per_mol
}

#' @rdname W2mol_spec_irradiance
#' @export
W2mol_spec_irradiance.lux_spectrum <- function(W, molar_unit = "umol", ...) {
  x             <- W
  .ENERGY_UNITS <- c("W/m2/nm", "W/m2/sr/nm", "mW/m2/sr/nm")
  if (!x$unit %in% .ENERGY_UNITS)
    stop("W2mol_spec_irradiance requires an energy-based unit; x$unit is '",
         x$unit, "'. Use n2W_spec_irradiance() to convert photonic units.")
  radiance <- grepl("/sr/", x$unit, fixed = TRUE)
  E        <- if (x$unit == "mW/m2/sr/nm") x$E * 1e-3 else x$E
  Enew     <- W2mol_spec_irradiance.numeric(E, x$lambda, molar_unit)
  new_unit <- if (radiance) paste0(molar_unit, "/m2/s/sr/nm") else
    paste0(molar_unit, "/m2/s/nm")
  lux_spectrum(Enew, x$lambda, x$quantity, new_unit, x$binwidth, x$meta)
}
