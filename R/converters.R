# converters.R — inverse converters and unit helpers

#' Convert photon counts to watts at a given wavelength.
#'
#' Uses E_photon = hc / lambda, with hc = 1.98644585714893e-16 J·nm.
#' Vectorised over both \code{n} and \code{lambda}.
#'
#' @param n      Photon count(s) per second per \eqn{m^{-2}} per nm.
#' @param lambda Wavelength(s) in nm.
#' @return Numeric vector of spectral irradiance in \eqn{W\,m^{-2}\,nm^{-1}}.
#' @seealso \code{\link{W2photon}}
#' @examples
#' photon2W(1e15, 555)
#' @export
photon2W <- function(n, lambda) n * 1.98644585714893e-16 / lambda


#' Convert watts to photon counts at a given wavelength.
#'
#' Inverse of \code{\link{photon2W}}.
#'
#' @param W      Spectral irradiance in \eqn{W\,m^{-2}\,nm^{-1}}.
#' @param lambda Wavelength(s) in nm.
#' @return Numeric vector of photon counts per second per \eqn{m^{-2}} per nm.
#' @examples
#' W2photon(1, 555)
#' @export
W2photon <- function(W, lambda) W * lambda / 1.98644585714893e-16


#' Wavelength of light inside an optical medium.
#'
#' Returns the in-medium wavelength after accounting for the refractive index.
#' Frequency (and photon energy) are unchanged; only the spatial period shortens.
#'
#' @param lambda Wavelength in vacuum or air (nm, or any consistent unit).
#'   Vectorised.
#' @param n Refractive index of the medium (dimensionless). Must be >= 1.
#' @return Wavelength in the medium, in the same unit as \code{lambda}.
#' @examples
#' wavelength_in_medium(500, n = 1.336)  # seawater: ~374 nm in medium
#' wavelength_in_medium(c(400, 500, 600), n = 1.5)
#' @export
wavelength_in_medium <- function(lambda, n) {
  if (any(n < 1)) stop("`n` must be >= 1 (refractive index of vacuum = 1).")
  lambda / n
}


#' Convert feet to metres.
#'
#' Vectorised; passes through \code{NA}.
#'
#' @param z Depth or distance in feet.
#' @return Numeric vector in metres.
#' @seealso \code{\link{m2ft}}
#' @examples
#' propagate_depth(8260, Kd = 0.062, from = ft2m(72), to = 0)
#' @export
ft2m <- function(z) z * 0.3048


#' Convert metres to feet.
#'
#' Vectorised; passes through \code{NA}.
#'
#' @param z Depth or distance in metres.
#' @return Numeric vector in feet.
#' @seealso \code{\link{ft2m}}
#' @examples
#' m2ft(30)
#' @export
m2ft <- function(z) z / 0.3048


#' Compute scotopic illuminance (V'(lambda) weighting).
#'
#' Drop-in replacement for \code{\link{irradiance2lux}} using the CIE 1951
#' scotopic luminous efficiency function V'(lambda). The scotopic luminous
#' efficacy K_m' = 1700 lm/W replaces the photopic K_m = 683 lm/W.
#'
#' @details
#' Scotopic illuminance uses the CIE 1951 scotopic luminous efficiency function
#' \eqn{V'(\lambda)}, which peaks at 507 nm. The maximum scotopic luminous
#' efficacy is \eqn{K_m' = 1700} lm W\eqn{^{-1}}:
#' \deqn{E_v' = 1700 \int_{380}^{780} E(\lambda)\,V'(\lambda)\,d\lambda}
#' Computed internally by calling \code{\link{irradiance2lux}} with
#' \code{LEF = CIE_scotopic} and applying the efficacy ratio \eqn{1700/683}.
#'
#' @param irradiance Spectral irradiance (\eqn{W\,m^{-2}\,nm^{-1}} or
#'   \eqn{photons\,m^{-2}\,s^{-1}\,nm^{-1}}) at each
#'   wavelength bin, or a \code{lux_spectrum} object whose quantity is
#'   \code{"irradiance"}. Photonic \code{lux_spectrum} inputs are converted to
#'   energy units before photometric integration; radiance and reflectance
#'   spectra are rejected.
#' @param lambda     Wavelength in nm (not needed for \code{lux_spectrum}).
#' @param photonic   Logical; if \code{TRUE}, irradiance is in photon or molar
#'   units. Default \code{FALSE}.
#' @param molar_unit Molar unit string when \code{photonic = TRUE} (e.g.
#'   \code{"umol"}). Default \code{"photons"}.
#' @param total      Logical; sum per-bin values into a scalar. Default
#'   \code{TRUE}.
#' @param binwidth   Wavelength bin width in nm. Inferred from a regular
#'   multi-bin wavelength grid when \code{NULL}; required for a single bin
#'   under rectangular integration. Must be \code{NULL} for trapezoidal
#'   integration.
#' @param integration Integration method passed to
#'   \code{\link{irradiance2lux}}: \code{"rectangle"} (default) or
#'   \code{"trapezoid"}.
#' @param verbose    Logical; emit diagnostic messages. Default \code{FALSE}.
#' @param ...        Ignored.
#' @return A scalar scotopic lux value (when \code{total = TRUE}) or numeric
#'   vector.
#' @note The scotopic/photopic crossover occurs near 10 lx. Below that
#'   threshold — twilight, moonlight, deep water — scotopic readings better
#'   reflect perceived brightness.
#' @examples
#' data(Naples)
#' scotopic_lux(Naples$depth_10m, Naples$wv,
#'              photonic = TRUE, molar_unit = "umol")
#' @param ... Ignored.
#' @export
scotopic_lux <- function(irradiance, ...) UseMethod("scotopic_lux")

#' @rdname scotopic_lux
#' @export
scotopic_lux.default <- function(irradiance, ...) {
  .stop_lux_spectrum_validation(
    paste0("`irradiance` must be a numeric vector or lux_spectrum; got ",
           paste(class(irradiance), collapse = "/"), "."),
    field = "irradiance", value = irradiance,
    subclass = "lux_spectrum_type_error"
  )
}

#' @rdname scotopic_lux
#' @export
scotopic_lux.numeric <- function(irradiance, lambda,
                                  photonic   = FALSE,
                                  molar_unit = "photons",
                                  total      = TRUE,
                                  binwidth   = NULL,
                                  integration = c("rectangle", "trapezoid"),
                                  verbose    = FALSE, ...) {
  integration <- match.arg(integration)
  irradiance2lux.numeric(irradiance, lambda,
                          photonic   = photonic,
                          molar_unit = molar_unit,
                          total      = total,
                          LEF        = CIE_scotopic,
                          binwidth   = binwidth,
                          integration = integration,
                          verbose    = verbose) * (1700 / 683)
}

#' @rdname scotopic_lux
#' @export
scotopic_lux.lux_spectrum <- function(irradiance, total = TRUE,
                                       integration = c("rectangle", "trapezoid"),
                                       verbose = FALSE, ...) {
  integration <- match.arg(integration)
  irradiance2lux.lux_spectrum(irradiance,
                               total   = total,
                               LEF     = CIE_scotopic,
                               integration = integration,
                               verbose = verbose) * (1700 / 683)
}


#' Distribute integrated lux across a reference spectral shape.
#'
#' lux is a single scalar; a spectrum has many degrees of freedom. This
#' function takes a reference \emph{shape} and rescales it so its photopic
#' integral equals \code{lx}. The shape assumption must be supplied by the
#' caller.
#'
#' @param lx       Target illuminance in lux.
#' @param spectrum Reference spectral shape. Either a data frame with columns
#'   \code{lambda} and \code{irradiance}, or a bare numeric vector (in which
#'   case \code{lambda} must be supplied separately).
#' @param lambda   Wavelength grid in nm. Required when \code{spectrum} is a
#'   bare vector; ignored when \code{spectrum} is a data frame.
#' @param LEF      Luminous efficiency function. Defaults to \code{CIE1931}.
#' @param binwidth Wavelength bin width in nm. Inferred from a regular
#'   multi-bin wavelength grid when \code{NULL}; required for a single bin
#'   under rectangular integration. Must be \code{NULL} for trapezoidal
#'   integration.
#' @param integration Integration method passed to
#'   \code{\link{irradiance2lux}}: \code{"rectangle"} (default) or
#'   \code{"trapezoid"}.
#' @return Numeric vector of rescaled spectral irradiance (same length as the
#'   wavelength grid).
#' @examples
#' spec <- data.frame(lambda = CIE1931$lambda, irradiance = CIE1931$W)
#' irr  <- lux2irradiance(5000, spec)
#' @export
lux2irradiance <- function(lx, spectrum, lambda = NULL,
                            LEF = CIE1931, binwidth = NULL,
                            integration = c("rectangle", "trapezoid")) {
  integration <- match.arg(integration)
  if (is.data.frame(spectrum)) {
    lambda <- if (!is.null(spectrum$lambda)) spectrum$lambda else spectrum$wavelength
    shape  <- spectrum$irradiance
  } else {
    shape <- spectrum
  }
  lx_shape <- irradiance2lux(shape, lambda, total = TRUE,
                              LEF = LEF, binwidth = binwidth,
                              integration = integration)
  shape * (lx / lx_shape)
}


#' Convert a broadband scalar reading into a plausible spectrum.
#'
#' Given a single measured value and a reference spectral shape, returns a
#' rescaled spectrum whose forward operator reproduces the input. The shape
#' assumption must be provided by the caller (e.g. from
#' \code{solar_irradiance()}).
#'
#' Supported units and their forward operators:
#' \describe{
#'   \item{\code{"lx"}}{photopic integral via \code{irradiance2lux()}}
#'   \item{\code{"W"}}{broadband integral \eqn{\sum E \cdot \Delta\lambda}}
#'   \item{\code{"kW"}}{same as \code{"W"} divided by 1000}
#'   \item{\code{"umol"}}{PAR-band photon flux (400–700 nm) in \eqn{\mu mol\,s^{-1}\,m^{-2}}}
#'   \item{\code{"radiance_W"}}{Lambertian radiance: \eqn{E = \pi L}, then integrate}
#'   \item{\code{"cd"}}{photometric radiance: \eqn{L = \text{lux} / \pi}}
#' }
#'
#' @param value      The measured scalar (e.g. 18200 lux, 480 W, 1.2 kW).
#' @param unit       One of \code{"lx"}, \code{"W"}, \code{"kW"},
#'   \code{"umol"}, \code{"radiance_W"}, \code{"cd"}.
#' @param spectrum   Reference spectral shape as a data frame with columns
#'   \code{wavelength} and \code{irradiance}.
#' @param water_type Optional Jerlov water type string (e.g. \code{"IA"}).
#'   If supplied, the reference shape is pre-attenuated to \code{depth} before
#'   rescaling — use when the measurement was taken at depth.
#' @param depth      Depth in metres at which the measurement was taken.
#'   Only used when \code{water_type} is not \code{NULL}. Default 0.
#' @param wavelength_policy Policy for wavelengths outside the bundled Jerlov
#'   domain when attenuation is requested: \code{"error"} (default), explicit
#'   restriction to the supported intersection with \code{"trim"}, or explicit
#'   constant endpoint extension with \code{"constant"}.
#' @return A data frame with columns \code{wavelength} and \code{irradiance},
#'   with a \code{luxR.assumption} attribute recording the provenance.
#' @examples
#' lam  <- seq(400, 700, by = 10)
#' spec <- data.frame(wavelength = lam, irradiance = rep(1, length(lam)))
#' broadband2spectrum(480, unit = "W", spectrum = spec)
#' @export
broadband2spectrum <- function(value,
                                unit       = c("lx", "W", "kW", "umol",
                                               "radiance_W", "cd"),
                                spectrum,
                                water_type = NULL,
                                depth      = 0,
                                wavelength_policy = c("error", "trim",
                                                      "constant")) {
  unit   <- match.arg(unit)
  wavelength_policy <- match.arg(wavelength_policy)
  shape  <- spectrum$irradiance
  lambda <- spectrum$wavelength
  jerlov_metadata <- NULL

  if (!is.null(water_type) && depth > 0) {
    domain <- .prepare_jerlov_domain(
      lambda, shape, wavelength_policy = wavelength_policy,
      type = water_type, operation = "broadband2spectrum"
    )
    lambda <- domain$lambda
    shape <- domain$values * exp(-domain$Kd * depth)
    jerlov_metadata <- domain$metadata
  }

  binwidth <- median(diff(lambda))

  v_shape <- switch(unit,
    lx         = irradiance2lux(shape, lambda, total = TRUE,
                                binwidth = binwidth),
    W          = sum(shape) * binwidth,
    kW         = sum(shape) * binwidth / 1e3,
    umol       = {
      par <- lambda >= 400 & lambda <= 700
      sum(W2photon(shape[par], lambda[par])) * binwidth / 6.02214076e17
    },
    radiance_W = sum(shape) * binwidth / pi,
    cd         = irradiance2lux(shape, lambda, total = TRUE,
                                binwidth = binwidth) / pi
  )

  k   <- value / v_shape
  out <- data.frame(wavelength = lambda, irradiance = shape * k)

  attr(out, "luxR.assumption") <- list(
    input_value       = value,
    input_unit        = unit,
    water_type        = water_type,
    measurement_depth = depth,
    jerlov             = jerlov_metadata,
    rescale_factor    = k,
    generated_at      = Sys.time()
  )
  out
}


#' Convert spectral reflectance to spectral radiance
#'
#' Multiplies a reflectance spectrum by an illuminant spectrum bin-by-bin.
#' For a \code{lux_spectrum} irradiance illuminant, a Lambertian reflector is
#' assumed: radiance is \eqn{L = \rho E / \pi}, and the output unit gains the
#' steradian term. For a radiance illuminant, the values are multiplied
#' directly and its radiance unit is retained.
#'
#' @param reflectance Numeric vector of reflectance values in [0, 1], or a
#'   \code{lux_spectrum} with \code{quantity = "reflectance"}.
#' @param illuminant Numeric vector of spectral irradiance/radiance, or a
#'   \code{lux_spectrum} with quantity \code{"irradiance"} or \code{"radiance"}.
#' @param lambda Numeric vector of wavelengths in nm (not needed when both
#'   inputs are \code{lux_spectrum}).
#' @return Named numeric vector, or a \code{lux_spectrum} with
#'   \code{quantity = "radiance"} and a dimensionally compatible radiance unit.
#'   The numeric method performs only element-wise multiplication because
#'   numeric vectors do not carry irradiance/radiance dimensional metadata.
#' @examples
#' sp   <- solar_irradiance("clear_noon")
#' lam  <- sp$wavelength
#' refl <- rep(0.5, length(lam))
#' reflectance_to_radiance(refl, sp$irradiance, lam)
#' @param ... Ignored.
#' @export
reflectance_to_radiance <- function(reflectance, ...) UseMethod("reflectance_to_radiance")

#' @rdname reflectance_to_radiance
#' @export
reflectance_to_radiance.numeric <- function(reflectance, illuminant, lambda, ...) {
  if (length(reflectance) != length(illuminant) ||
      length(reflectance) != length(lambda))
    stop("reflectance, illuminant, and lambda must all have the same length.")
  if (any(reflectance < 0) || any(reflectance > 1))
    stop("Reflectance values must be in [0, 1].")
  out        <- reflectance * illuminant
  names(out) <- as.character(lambda)
  out
}

#' @rdname reflectance_to_radiance
#' @export
reflectance_to_radiance.lux_spectrum <- function(reflectance, illuminant, ...) {
  if (!inherits(illuminant, "lux_spectrum"))
    stop("illuminant must be a lux_spectrum when reflectance is a lux_spectrum.")
  if (reflectance$quantity != "reflectance")
    stop("reflectance$quantity must be 'reflectance'; got '",
         reflectance$quantity, "'.")
  if (!illuminant$quantity %in% c("irradiance", "radiance"))
    stop("illuminant$quantity must be 'irradiance' or 'radiance'.")
  if (!identical(reflectance$lambda, illuminant$lambda))
    stop("lambda grids must be identical.")

  if (illuminant$quantity == "irradiance") {
    unit_map <- c(
      "W/m2/nm"      = "W/m2/sr/nm",
      "umol/m2/s/nm" = "umol/m2/s/sr/nm",
      "mmol/m2/s/nm" = "mmol/m2/s/sr/nm",
      "mol/m2/s/nm"  = "mol/m2/s/sr/nm"
    )
    new_unit <- unname(unit_map[[illuminant$unit]])
    if (is.null(new_unit))
      stop("No radiance unit is defined for irradiance unit '",
           illuminant$unit, "'.")
    E_new <- reflectance$E * illuminant$E / pi
  } else {
    new_unit <- illuminant$unit
    E_new <- reflectance$E * illuminant$E
  }

  lux_spectrum(E_new, illuminant$lambda, "radiance",
               new_unit, illuminant$binwidth, illuminant$meta)
}
