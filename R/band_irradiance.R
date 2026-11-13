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
#' approximated as \eqn{\sum_i E(z,\lambda_i)\,w_i}. Each sample is a bin of
#' width \code{binwidth} centred on its wavelength, and \eqn{w_i} is the part
#' of that bin inside the window, so a bin straddling a band edge counts only
#' its overlap. The wavelength grid must be regularly spaced and its bins must
#' span the window. See \code{\link{propagate_spectrum}} for the full Beer-Lambert
#' documentation.
#'
#' @param E_lambda   Spectral irradiance (\eqn{W\,m^{-2}\,nm^{-1}}{W m^-2 nm^-1}) at depth \code{from}.
#'   Length-N vector, or an irradiance \code{lux_spectrum}, which is
#'   converted to \eqn{W\,m^{-2}\,nm^{-1}}{W m^-2 nm^-1} first.
#' @param Kd_lambda  Diffuse attenuation coefficients (1/m) at the same
#'   wavelengths. Length-N vector.
#' @param lambda     Wavelengths in nm. Length-N vector (not needed when
#'   \code{E_lambda} is a \code{lux_spectrum}).
#' @param depths     Target depth(s) in metres. Scalar or vector.
#' @param from       Depth of the known spectrum in metres. Default \code{0}
#'   (surface). Set to a positive value to propagate from a subsurface
#'   measurement.
#' @param lambda_min Lower wavelength bound in nm. Defaults to the outer edge
#'   of the first bin, \code{min(lambda) - binwidth / 2}.
#' @param lambda_max Upper wavelength bound in nm. Defaults to the outer edge
#'   of the last bin, \code{max(lambda) + binwidth / 2}.
#' @param photonic   Logical; if \code{TRUE} the result is returned in
#'   \eqn{\mu}mol photons m\eqn{^{-2}} s\eqn{^{-1}} rather than \eqn{W\,m^{-2}}{W m^-2}.
#'   Default \code{FALSE}.
#' @param molar_unit Molar unit for photonic output. Default \code{"umol"}.
#' @param binwidth   Wavelength bin width in nm. Inferred from \code{lambda}
#'   if not supplied; if supplied it must equal the wavelength spacing.
#' @param allow_above_surface Logical; permits target depths above the surface
#'   (negative values). Default \code{FALSE}.
#' @return A \code{data.frame} with columns:
#'   \describe{
#'     \item{depth}{Target depth in metres.}
#'     \item{E}{Band-integrated irradiance in \eqn{W\,m^{-2}}{W m^-2} (or \eqn{\mu}mol m\eqn{^{-2}} s\eqn{^{-1}}
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
  op <- "band_irradiance()"
  .check_spectral_values(E_lambda, lambda, "E_lambda", op)
  .check_spectral_values(Kd_lambda, lambda, "Kd_lambda", op)
  w    <- .band_widths(lambda, binwidth, lambda_min, lambda_max, op)
  keep <- w > 0

  mat <- propagate_spectrum(E_lambda[keep], Kd_lambda[keep], from = from,
                             to = depths, format = "matrix",
                             allow_above_surface = allow_above_surface)

  if (isTRUE(photonic)) {
    photons_per_mol <- mol2photon_FUN(1, molar_unit)
    mat <- W2photon(mat, lambda[keep]) / photons_per_mol
  }

  data.frame(
    depth = depths,
    E     = colSums(mat * w[keep])
  )
}

#' @rdname band_irradiance
#' @export
band_irradiance.lux_spectrum <- function(E_lambda, Kd_lambda, depths,
                                          lambda = NULL, ...) {
  x <- .as_energy_irradiance(E_lambda, "band_irradiance()")
  band_irradiance.numeric(x$E, Kd_lambda, x$lambda, depths,
                           binwidth = x$binwidth, ...)
}


# Width (nm) of each wavelength bin that lies inside the band [lo, hi].
#
# A sample is a bin of width `binwidth` centred on its wavelength, so a band
# integral is `sum(E * .band_widths(...))` and a bin straddling a band edge
# counts only its overlap. `lo`/`hi` default to the outer bin edges. With
# `cover = TRUE` the bins must span the whole band.
.band_widths <- function(lambda, binwidth = NULL, lo = NULL, hi = NULL,
                         operation, cover = TRUE) {
  fail <- .input_fail(operation)
  binwidth <- .grid_binwidth(lambda, binwidth, operation)
  left  <- lambda - binwidth / 2
  right <- lambda + binwidth / 2
  if (is.null(lo)) lo <- left[1L] else
    .check_input(lo, "lambda_min", operation, scalar = TRUE)
  if (is.null(hi)) hi <- right[length(right)] else
    .check_input(hi, "lambda_max", operation, scalar = TRUE)
  if (lo >= hi) {
    fail(paste0("the band's lower limit (", format(lo), " nm) must be below ",
                "its upper limit (", format(hi), " nm)."),
         c("lambda_min", "lambda_max"), c(lo, hi), NULL, "value")
  }
  tolerance <- .grid_tolerance(lo, hi)
  if (cover && (lo < left[1L] - tolerance ||
                hi > right[length(right)] + tolerance)) {
    fail(paste0("the wavelength bins span ", format(left[1L]), "-",
                format(right[length(right)]), " nm and do not cover the band ",
                format(lo), "-", format(hi), " nm."),
         "lambda", range(lambda), NULL, "grid")
  }
  pmax(0, pmin(hi, right) - pmax(lo, left))
}

# Spectral values must be finite (a non-finite value outside the band would
# otherwise reach the result as NA * 0) and match the wavelength grid.
.check_spectral_values <- function(x, lambda, field, operation) {
  .check_input(x, field, operation)
  if (length(x) != length(lambda)) {
    .stop_lux_spectrum_validation(
      paste0(operation, ": `", field, "` has length ", length(x),
             " but `lambda` has length ", length(lambda), "."),
      field = field, value = length(x),
      subclass = "lux_spectrum_dimension_error"
    )
  }
}
