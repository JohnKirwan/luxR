#' Band-integrated irradiance at one or more depths
#'
#' Propagates a spectrum from a known depth to one or more target depths via
#' Beer-Lambert attenuation and integrates the result over a wavelength band.
#' Works in both directions: set \code{from} > \code{depths} to recover
#' shallower values (including the surface) from a deeper measurement.
#'
#' @details
#' Two operations are applied in sequence. First, Beer-Lambert propagation at
#' each wavelength:
#' \deqn{E(z,\,\lambda) = E_0(\lambda)\,
#'       \exp\!\bigl[-K_d(\lambda)\,(z - z_0)\bigr]}
#' where \eqn{z_0} is the depth of the known spectrum (\code{from}) and
#' \eqn{K_d(\lambda)} is the diffuse attenuation coefficient. Second, the
#' propagated spectrum is integrated over the specified wavelength window
#' [\eqn{\lambda_{\min}}, \eqn{\lambda_{\max}}]:
#' \deqn{E_{\mathrm{band}}(z) =
#'       \int_{\lambda_{\min}}^{\lambda_{\max}} E(z,\,\lambda)\,d\lambda}
#' approximated as \eqn{\sum_i E(z,\lambda_i)\,\Delta\lambda} over bins within
#' the window. See \code{\link{propagate_spectrum}} for the full Beer-Lambert
#' documentation.
#'
#' @param E_lambda   Spectral irradiance (W/m^2/nm) at depth \code{from}.
#'   Length-N vector, or a \code{lux_spectrum} object.
#' @param Kd_lambda  Diffuse attenuation coefficients (1/m) at the same
#'   wavelengths. Length-N vector.
#' @param lambda     Wavelengths in nm. Length-N vector (not needed when
#'   \code{E_lambda} is a \code{lux_spectrum}).
#' @param depths     Target depth(s) in metres. Scalar or vector.
#' @param from       Depth of the known spectrum in metres. Default \code{0}
#'   (surface). Set to a positive value to propagate from a subsurface
#'   measurement.
#' @param lambda_min Lower wavelength bound in nm (inclusive). Defaults to
#'   \code{min(lambda)}.
#' @param lambda_max Upper wavelength bound in nm (inclusive). Defaults to
#'   \code{max(lambda)}.
#' @param photonic   Logical; if \code{TRUE} the result is returned in
#'   \eqn{\mu}mol photons m\eqn{^{-2}} s\eqn{^{-1}} rather than W/m^2.
#'   Default \code{FALSE}.
#' @param molar_unit Molar unit for photonic output. Default \code{"umol"}.
#' @param binwidth   Wavelength bin width in nm. Inferred from \code{lambda}
#'   if not supplied.
#' @param allow_above_surface Logical; permits target depths above the surface
#'   (negative values). Default \code{FALSE}.
#' @return A \code{data.frame} with columns:
#'   \describe{
#'     \item{depth}{Target depth in metres.}
#'     \item{E}{Band-integrated irradiance in W/m^2 (or \eqn{\mu}mol/m^2/s
#'       when \code{photonic = TRUE}).}
#'   }
#' @seealso \code{\link{propagate_spectrum}}, \code{\link{par_irradiance}}
#' @examples
#' sp  <- solar_irradiance("clear_noon")
#' keep <- sp$wavelength >= 350 & sp$wavelength <= 700
#' lam <- sp$wavelength[keep]
#' E0  <- sp$irradiance[keep]
#' Kd  <- jerlov_Kd("II", lam)
#'
#' # surface to depth profile, 500-600 nm band
#' band_irradiance(E0, Kd, lam, depths = c(0, 5, 10, 20, 50),
#'                 lambda_min = 500, lambda_max = 600)
#'
#' # recover surface from a 10 m measurement
#' E_10m <- E0 * exp(-Kd * 10)
#' band_irradiance(E_10m, Kd, lam, depths = 0, from = 10)
#' @param ... Ignored.
#' @export
band_irradiance <- function(E_lambda, ...) UseMethod("band_irradiance")

#' @rdname band_irradiance
#' @export
band_irradiance.numeric <- function(E_lambda, Kd_lambda, lambda, depths,
                                     from       = 0,
                                     lambda_min = NULL, lambda_max = NULL,
                                     photonic   = FALSE,
                                     molar_unit = "umol",
                                     binwidth   = NULL,
                                     allow_above_surface = FALSE, ...) {
  if (is.null(lambda_min)) lambda_min <- min(lambda)
  if (is.null(lambda_max)) lambda_max <- max(lambda)
  if (lambda_min >= lambda_max)
    stop("lambda_min must be less than lambda_max.")

  idx <- lambda >= lambda_min & lambda <= lambda_max
  if (!any(idx))
    stop("No wavelengths in [", lambda_min, ", ", lambda_max, "] nm. ",
         "Check lambda values.")

  lam_sub <- lambda[idx]
  E_sub   <- E_lambda[idx]
  Kd_sub  <- Kd_lambda[idx]

  if (is.null(binwidth))
    binwidth <- if (length(lam_sub) > 1) mean(diff(lam_sub)) else 1

  mat <- propagate_spectrum(E_sub, Kd_sub, from = from, to = depths,
                             format = "matrix",
                             allow_above_surface = allow_above_surface)

  if (isTRUE(photonic)) {
    photons_per_mol <- mol2photon_FUN(1, molar_unit)
    mat <- mat * (lam_sub / 1.98644585714893e-16) / photons_per_mol
  }

  data.frame(
    depth = depths,
    E     = colSums(mat) * binwidth
  )
}

#' @rdname band_irradiance
#' @export
band_irradiance.lux_spectrum <- function(E_lambda, Kd_lambda, depths,
                                          lambda = NULL, ...) {
  x <- E_lambda
  band_irradiance.numeric(x$E, Kd_lambda, x$lambda, depths,
                           binwidth = x$binwidth, ...)
}
