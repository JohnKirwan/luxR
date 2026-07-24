# optical_properties.R — inherent optical properties, Beer-Lambert, and the
# air-water interface (Johnsen 2012, ch. 4-5).

#' Beam attenuation coefficient from absorption and scattering.
#'
#' The beam (total) attenuation coefficient is the sum of the absorption and
#' scattering coefficients, \eqn{c = a + b} (Johnsen 2012, ch. 5). It governs
#' how a collimated beam — and the contrast of a sighted object — fades with
#' distance, and is always larger than the diffuse attenuation \eqn{K_d}.
#'
#' @param absorption Absorption coefficient \eqn{a} (1/m). Vectorised.
#' @param scattering Scattering coefficient \eqn{b} (1/m). Vectorised.
#' @return Beam attenuation coefficient \eqn{c} (1/m).
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.
#' @seealso \code{\link{single_scattering_albedo}}, \code{\link{transmittance}},
#'   \code{\link{visual_range}}
#' @examples
#' beam_attenuation(absorption = 0.1, scattering = 0.05)   # 0.15
#' @export
beam_attenuation <- function(absorption, scattering) {
  if (any(absorption < 0, na.rm = TRUE) || any(scattering < 0, na.rm = TRUE))
    stop("`absorption` and `scattering` must be >= 0.")
  absorption + scattering
}


#' Single-scattering albedo.
#'
#' The fraction of beam attenuation due to scattering rather than absorption,
#' \eqn{\omega_0 = b / (a + b) = b / c} (Johnsen 2012, ch. 5). Values near 1
#' indicate a strongly scattering, weakly absorbing medium (e.g. fog or milk);
#' values near 0 a strongly absorbing one.
#'
#' @param absorption Absorption coefficient \eqn{a} (1/m). Vectorised.
#' @param scattering Scattering coefficient \eqn{b} (1/m). Vectorised.
#' @return Single-scattering albedo \eqn{\omega_0} (dimensionless, 0-1).
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.
#' @seealso \code{\link{beam_attenuation}}
#' @examples
#' single_scattering_albedo(absorption = 0.1, scattering = 0.05)   # 0.333
#' @export
single_scattering_albedo <- function(absorption, scattering) {
  if (any(absorption < 0, na.rm = TRUE) || any(scattering < 0, na.rm = TRUE))
    stop("`absorption` and `scattering` must be >= 0.")
  cc <- absorption + scattering
  if (any(cc <= 0, na.rm = TRUE))
    stop("absorption + scattering must be > 0.")
  scattering / cc
}


#' Beer-Lambert transmittance over a path.
#'
#' Fraction of collimated light transmitted through a path of length
#' \code{path_length} in a medium with attenuation \code{coefficient}:
#' \eqn{T = e^{-c\,\ell}} (Johnsen 2012, ch. 4). The fraction \emph{absorbed}
#' (or attenuated) is \eqn{1 - T}; note that absorbances add over stacked paths
#' while transmittances multiply.
#'
#' @param coefficient Attenuation (or absorption) coefficient (1/length).
#'   Vectorised.
#' @param path_length Path length in the same length unit. Vectorised.
#' @return Transmittance (0-1).
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 4.
#' @seealso \code{\link{absorbance}}, \code{\link{beam_attenuation}}
#' @examples
#' transmittance(coefficient = 0.15, path_length = 10)
#' 1 - transmittance(0.064, 10)   # hatchetfish rod: ~47% absorbed
#' @export
transmittance <- function(coefficient, path_length) {
  if (any(coefficient < 0, na.rm = TRUE))
    stop("`coefficient` must be >= 0.")
  if (any(path_length < 0, na.rm = TRUE))
    stop("`path_length` must be >= 0.")
  exp(-coefficient * path_length)
}


#' Absorbance (optical density) from transmittance.
#'
#' The negative logarithm of transmittance. Natural-log absorbance
#' (\code{base = "e"}) is used by vision scientists and oceanographers;
#' base-10 absorbance (\code{base = "10"}) is "optical density" (OD), used by
#' chemists and filter makers. They differ by a constant: \eqn{OD = A\log_{10}e
#' \approx 0.4343\,A} (Johnsen 2012, ch. 4).
#'
#' @param transmittance Transmittance (0-1]. Vectorised.
#' @param base \code{"e"} (natural-log absorbance, default) or \code{"10"}
#'   (optical density).
#' @return Absorbance / optical density (dimensionless, \eqn{\geq 0}).
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 4.
#' @seealso \code{\link{transmittance}}
#' @examples
#' absorbance(0.01, base = "10")   # OD = 2 (1% transmitted)
#' absorbance(exp(-1.5))           # natural-log absorbance = 1.5
#' @export
absorbance <- function(transmittance, base = c("e", "10")) {
  base <- match.arg(base)
  if (any(transmittance <= 0 | transmittance > 1, na.rm = TRUE))
    stop("`transmittance` must be in (0, 1].")
  if (base == "e") -log(transmittance) else -log10(transmittance)
}


#' Snell's window half-angle.
#'
#' Underwater, the entire above-water hemisphere is refracted into a cone — the
#' "Snell's window" or "optical manhole" — of half-angle
#' \eqn{\theta_c = \arcsin(1/n)} (Johnsen 2012, ch. 5). For seawater
#' (\eqn{n \approx 1.333}) this is about 48.6 degrees, so the whole sky is
#' compressed into a ~97 degree cone overhead.
#'
#' @param n Refractive index of the water relative to air. Default 1.333.
#'   Vectorised.
#' @return Half-angle of Snell's window, in degrees.
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.
#' @seealso \code{\link{fresnel_reflectance}}, \code{\link{wavelength_in_medium}}
#' @examples
#' snells_window()        # ~48.6 degrees
#' @export
snells_window <- function(n = 1.333) {
  if (any(n <= 1, na.rm = TRUE))
    stop("`n` (refractive index relative to air) must be > 1.")
  asin(1 / n) * 180 / pi
}


#' Fresnel reflectance at the air-water interface.
#'
#' Unpolarised Fresnel reflectance for light crossing a flat air-water boundary,
#' as a function of incidence angle (Johnsen 2012, ch. 5). At normal incidence
#' about 2\% of downwelling light is reflected (\eqn{R = ((n-1)/(n+1))^2}).
#' Going from water to air, total internal reflection (\eqn{R = 1}) occurs beyond
#' the critical angle (the edge of \code{\link{snells_window}}).
#'
#' @param angle Angle of incidence from the surface normal, in degrees (0-90).
#'   Vectorised.
#' @param n     Refractive index of water relative to air. Default 1.333.
#' @param from  Incident medium: \code{"air"} (default) or \code{"water"}.
#' @param component Which polarization component to return: \code{"unpolarized"}
#'   (default; the mean of the two), \code{"s"} (perpendicular / TE), or
#'   \code{"p"} (parallel / TM). The difference between the s- and p-components
#'   is why reflection off water partially polarizes light (vanishing for the
#'   p-component at Brewster's angle).
#' @return Reflectance (0-1); the transmitted fraction is \eqn{1 - R}.
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.
#' @seealso \code{\link{snells_window}}, \code{\link{underwater_polarization}}
#' @examples
#' fresnel_reflectance(0)                       # ~0.02 at normal incidence
#' fresnel_reflectance(60, from = "water")      # total internal reflection -> 1
#' fresnel_reflectance(53.1, component = "p")   # ~0 near Brewster's angle
#' @export
fresnel_reflectance <- function(angle = 0, n = 1.333,
                                from = c("air", "water"),
                                component = c("unpolarized", "s", "p")) {
  from      <- match.arg(from)
  component <- match.arg(component)
  if (length(n) != 1L || n <= 1)
    stop("`n` (refractive index relative to air) must be a single value > 1.")
  if (any(angle < 0 | angle > 90, na.rm = TRUE))
    stop("`angle` must be in [0, 90] degrees.")

  n1 <- if (from == "air") 1 else n
  n2 <- if (from == "air") n else 1

  ti    <- angle * pi / 180
  ci    <- cos(ti)
  sin_t <- (n1 / n2) * sin(ti)
  tir   <- sin_t >= 1                       # total internal reflection
  ct    <- suppressWarnings(sqrt(1 - sin_t^2))

  Rs <- ((n1 * ci - n2 * ct) / (n1 * ci + n2 * ct))^2
  Rp <- ((n1 * ct - n2 * ci) / (n1 * ct + n2 * ci))^2
  R  <- switch(component,
               unpolarized = 0.5 * (Rs + Rp),
               s           = Rs,
               p           = Rp)
  R[tir] <- 1
  R
}


#' Fraction of downwelling irradiance transmitted across the water surface.
#'
#' The fraction of above-surface downwelling irradiance that enters the water
#' after Fresnel reflection at a flat air-water interface — the surface term of
#' an above-vs-below-water light budget: \eqn{E_{\text{below}} \approx
#' \tau\,E_{\text{above}}} (Johnsen 2012, ch. 5).
#'
#' For a \code{"direct"} (collimated, e.g. solar-beam) source at a given
#' incidence angle, \eqn{\tau = 1 - R(\theta)}. For a \code{"diffuse"} (isotropic
#' sky) source it is the cosine-weighted hemispherical average of
#' \eqn{1 - R(\theta)}, about 0.93 for seawater (i.e. ~7\% is reflected). This is
#' the planar-irradiance transmittance; in-water \emph{radiance} is additionally
#' boosted by \eqn{n^2} because the refracted beam is compressed into
#' \code{\link{snells_window}}.
#'
#' @param angle Solar/incidence angle from the surface normal, in degrees (0-90).
#'   Required for \code{source = "direct"}; ignored for \code{"diffuse"}.
#' @param n     Refractive index of water relative to air. Default 1.333.
#' @param source \code{"direct"} (collimated beam at \code{angle}) or
#'   \code{"diffuse"} (isotropic sky).
#' @return Transmitted fraction of downwelling irradiance (0-1).
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.
#' @seealso \code{\link{fresnel_reflectance}}, \code{\link{snells_window}}
#' @examples
#' surface_transmittance(angle = 0)              # overhead sun: ~0.98
#' surface_transmittance(source = "diffuse")     # isotropic sky: ~0.93
#' @export
surface_transmittance <- function(angle = NULL, n = 1.333,
                                   source = c("direct", "diffuse")) {
  source <- match.arg(source)
  if (source == "direct") {
    if (is.null(angle))
      stop("`angle` is required for source = 'direct'.")
    return(1 - fresnel_reflectance(angle, n = n, from = "air"))
  }
  # diffuse: cosine-weighted hemispherical average of (1 - R(theta)),
  # normalised by int_0^{pi/2} cos*sin dtheta = 1/2.
  integrand <- function(th) {
    deg <- pmin(th * 180 / pi, 90)
    (1 - fresnel_reflectance(deg, n = n, from = "air")) * cos(th) * sin(th)
  }
  stats::integrate(integrand, 0, pi / 2)$value / 0.5
}
