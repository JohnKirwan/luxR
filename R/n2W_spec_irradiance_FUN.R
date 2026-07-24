# n2W_irradiance
#
# This is a function named 'n2W_irradiance'.
#
#' Provide W values for measures of spectral irradiance. The constant is Planck's constant times the speed of light in nm/s. It is an internal function applied to a single wavelength bin.
#'
#' @keywords internal
#' @param photons The spectral irradiance (in \eqn{W\,m^{-2}\,nm^{-1}}{W m^-2 nm^-1} or
#'   \eqn{photons\,m^{-2}\,s^{-1}\,nm^{-1}}{photons m^-2 s^-1 nm^-1}; see photon) at each wavelength bin.
#' @param lambda The wavelength in nanometres (nm), taken from the midpoint value of irradiance bins.
#' @return A scalar representing the spectral irradiance values transformed
#'   from \eqn{photons\,m^{-2}\,s^{-1}\,nm^{-1}}{photons m^-2 s^-1 nm^-1} into \eqn{W\,m^{-2}\,nm^{-1}}{W m^-2 nm^-1}.
#
n2W_spec_irradiance_FUN <- function(photons,lambda){
    W = photons * 1.98644585714893e-16 / lambda
    return(W)
}