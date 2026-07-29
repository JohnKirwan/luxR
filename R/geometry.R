# geometry.R — irradiance <-> radiance conversion

#' Convert irradiance to radiance under a geometry assumption.
#'
#' The relationship between irradiance E and radiance L depends on the
#' angular distribution of the light field. The caller must supply the
#' geometry; the function refuses to silently apply the wrong identity.
#'
#' @param E          Irradiance value(s) in \eqn{W\,m^{-2}}{W m^-2} (or any energy unit).
#'   Vectorised.
#' @param geometry   One of:
#'   \describe{
#'     \item{\code{"lambertian"}}{Planar (vector) irradiance from a Lambertian
#'       surface, or equivalently from an isotropic hemisphere of radiance —
#'       the cosine-weighted integral \eqn{\int L \cos\theta\, d\Omega = \pi L}.
#'       This is what a cosine collector (e.g. a downwelling-irradiance sensor)
#'       measures: \eqn{L = E / \pi}. Default.}
#'     \item{\code{"scalar"}}{Scalar irradiance (fluence rate) over a
#'       \eqn{2\pi} sr hemisphere — the \emph{un}-weighted integral
#'       \eqn{\int L\, d\Omega = 2\pi L}, as measured by a spherical collector.
#'       Scalar and vector irradiance are different physical quantities, not
#'       two flavours of the same measurement (Johnsen 2012, ch. 2):
#'       \eqn{L = E / (2\pi)}.}
#'     \item{\code{"collimated"}}{Normal-incidence collimated beam:
#'       \eqn{L = E} (solid angle \eqn{\to 0}).}
#'     \item{\code{"custom"}}{User-specified solid angle \eqn{\Omega}:
#'       \eqn{L = E / \Omega}. Requires \code{solid_angle}.}
#'   }
#' @param solid_angle Finite solid angle in (0, 4 pi] steradians. Required when
#'   \code{geometry = "custom"} and rejected for other geometries.
#' @return Radiance in \eqn{W\,m^{-2}\,sr^{-1}}{W m^-2 sr^-1} (same numeric unit as \code{E}).
#' @references
#'   Johnsen S (2012) The Optics of Life: A Biologist's Guide to Light in
#'   Nature. Princeton University Press. (Ch. 2: vector vs scalar irradiance.)
#' @seealso \code{\link{radiance2irradiance}}
#' @examples
#' irradiance2radiance(pi)                              # lambertian: L = 1
#' irradiance2radiance(2 * pi, "scalar")                # scalar: L = 1
#' irradiance2radiance(10, "collimated")                # L = E
#' irradiance2radiance(10, "custom", solid_angle = 2)  # L = 5
#' @export
irradiance2radiance <- function(E,
                                 geometry    = c("lambertian", "scalar",
                                                 "collimated", "custom"),
                                 solid_angle = NULL) {
  geometry <- match.arg(geometry)
  .validate_detection_numeric(E, "E", "irradiance2radiance",
                              nonnegative = TRUE)
  if (!identical(geometry, "custom") && !is.null(solid_angle))
    .stop_detection(
      "`solid_angle` is only valid when `geometry = \"custom\"`.",
      field = "solid_angle", value = solid_angle,
      operation = "irradiance2radiance"
    )
  if (identical(geometry, "custom")) {
    .validate_detection_numeric(
      solid_angle, "solid_angle", "irradiance2radiance",
      scalar = TRUE, positive = TRUE
    )
    if (solid_angle > 4 * pi)
      .stop_detection(
        "`solid_angle` cannot exceed 4*pi steradians.",
        field = "solid_angle", value = solid_angle,
        operation = "irradiance2radiance"
      )
  }
  switch(geometry,
    lambertian = E / pi,
    scalar     = E / (2 * pi),
    collimated = E,
    custom     = {
      if (is.null(solid_angle))
        stop("`solid_angle` (sr) is required for geometry = 'custom'.")
      E / solid_angle
    }
  )
}


#' Convert radiance to irradiance under a geometry assumption.
#'
#' Inverse of \code{\link{irradiance2radiance}}. The geometry argument must
#' match the one used during collection.
#'
#' @param L          Radiance value(s) in \eqn{W\,m^{-2}\,sr^{-1}}{W m^-2 sr^-1}. Vectorised.
#' @param geometry   One of \code{"lambertian"} (default), \code{"scalar"},
#'   \code{"collimated"}, or \code{"custom"}. See
#'   \code{\link{irradiance2radiance}} for details.
#' @param solid_angle Finite solid angle in (0, 4 pi] steradians. Required for
#'   \code{geometry = "custom"} and rejected for other geometries.
#' @return Irradiance in \eqn{W\,m^{-2}}{W m^-2}.
#' @examples
#' radiance2irradiance(1)                              # lambertian: E = pi
#' radiance2irradiance(1, "scalar")                    # scalar: E = 2*pi
#' radiance2irradiance(5, "custom", solid_angle = 2)  # E = 10
#' @export
radiance2irradiance <- function(L,
                                 geometry    = c("lambertian", "scalar",
                                                 "collimated", "custom"),
                                 solid_angle = NULL) {
  geometry <- match.arg(geometry)
  .validate_detection_numeric(L, "L", "radiance2irradiance",
                              nonnegative = TRUE)
  if (!identical(geometry, "custom") && !is.null(solid_angle))
    .stop_detection(
      "`solid_angle` is only valid when `geometry = \"custom\"`.",
      field = "solid_angle", value = solid_angle,
      operation = "radiance2irradiance"
    )
  if (identical(geometry, "custom")) {
    .validate_detection_numeric(
      solid_angle, "solid_angle", "radiance2irradiance",
      scalar = TRUE, positive = TRUE
    )
    if (solid_angle > 4 * pi)
      .stop_detection(
        "`solid_angle` cannot exceed 4*pi steradians.",
        field = "solid_angle", value = solid_angle,
        operation = "radiance2irradiance"
      )
  }
  switch(geometry,
    lambertian = L * pi,
    scalar     = L * 2 * pi,
    collimated = L,
    custom     = {
      if (is.null(solid_angle))
        stop("`solid_angle` (sr) is required for geometry = 'custom'.")
      L * solid_angle
    }
  )
}
