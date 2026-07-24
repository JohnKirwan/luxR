# polarization — linear polarization of the underwater light field.
#
# Lightweight, analytic single-scattering model (no vector radiative transfer;
# see SCOPE.md). Angles are in degrees throughout. Directions are specified by a
# zenith angle (0 = straight up, 90 = horizontal, 180 = straight down) and an
# azimuth (degrees, measured in the horizontal plane from a common reference).

.POLARIZATION_MODEL_VERSION <- "0.1.0-rayleigh-like"

.polarization_runtime_context <- function(operation, configuration = list()) {
  random_seed <- if (exists(".Random.seed", envir = .GlobalEnv,
                            inherits = FALSE)) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NA_integer_
  }
  list(
    operation = operation,
    model_version = .POLARIZATION_MODEL_VERSION,
    package_version = .luxr_package_version(),
    code_commit = .luxr_code_commit(),
    random_seed = random_seed,
    configuration = configuration
  )
}

.stop_polarization <- function(message, operation,
                               class = "luxR_polarization_input_error",
                               field = NULL, value = NULL, index = NULL,
                               configuration = list()) {
  condition <- structure(
    c(
      list(message = message, call = NULL, field = field, value = value,
           index = index),
      .polarization_runtime_context(operation, configuration)
    ),
    class = c(class, "luxR_polarization_error", "luxR_error",
              "error", "condition")
  )
  stop(condition)
}

.validate_polarization_numeric <- function(x, field, operation,
                                           scalar = FALSE,
                                           lower = NULL, upper = NULL,
                                           lower_open = FALSE,
                                           configuration = list()) {
  if (!is.numeric(x) || is.complex(x) || is.object(x) ||
      !is.null(dim(x)) || length(x) == 0L) {
    .stop_polarization(
      paste0("`", field, "` must be a non-empty, unclassed numeric vector."),
      operation, field = field, value = x, configuration = configuration
    )
  }
  if (scalar && length(x) != 1L) {
    .stop_polarization(
      paste0("`", field, "` must contain exactly one value; got length ",
             length(x), "."),
      operation, field = field, value = x, configuration = configuration
    )
  }
  invalid <- which(!is.finite(x))
  if (length(invalid)) {
    i <- invalid[[1L]]
    .stop_polarization(
      paste0("`", field, "` must contain only finite values; index ", i,
             " is ", format(x[[i]]), "."),
      operation, field = field, value = x[[i]], index = i,
      configuration = configuration
    )
  }
  if (!is.null(lower)) {
    invalid <- if (lower_open) which(x <= lower) else which(x < lower)
    if (length(invalid)) {
      i <- invalid[[1L]]
      relation <- if (lower_open) "greater than" else "at least"
      .stop_polarization(
        paste0("`", field, "` must be ", relation, " ", format(lower),
               "; index ", i, " is ", format(x[[i]]), "."),
        operation, field = field, value = x[[i]], index = i,
        configuration = configuration
      )
    }
  }
  if (!is.null(upper)) {
    invalid <- which(x > upper)
    if (length(invalid)) {
      i <- invalid[[1L]]
      .stop_polarization(
        paste0("`", field, "` must be at most ", format(upper),
               "; index ", i, " is ", format(x[[i]]), "."),
        operation, field = field, value = x[[i]], index = i,
        configuration = configuration
      )
    }
  }
  invisible(x)
}

.broadcast_polarization <- function(values, operation,
                                    configuration = list()) {
  lengths <- vapply(values, length, integer(1))
  n <- max(lengths)
  incompatible <- names(values)[!lengths %in% c(1L, n)]
  if (length(incompatible)) {
    .stop_polarization(
      paste0(
        "Polarization inputs must be scalars or share one common length; ",
        paste(paste0("`", names(values), "`=", lengths), collapse = ", "),
        "."
      ),
      operation, class = "luxR_polarization_length_error",
      field = incompatible[[1L]], value = lengths,
      configuration = configuration
    )
  }
  lapply(values, function(x) if (length(x) == n) x else rep(x, n))
}

.polarization_norm <- function(Q, U, V) {
  scale <- pmax(abs(Q), abs(U), abs(V))
  out <- numeric(length(scale))
  nonzero <- scale > 0
  out[nonzero] <- scale[nonzero] * sqrt(
    (Q[nonzero] / scale[nonzero])^2 +
      (U[nonzero] / scale[nonzero])^2 +
      (V[nonzero] / scale[nonzero])^2
  )
  out
}

# Unit direction vector from zenith/azimuth in degrees (x = cos(az), y = sin(az)).
.dir_vec <- function(zenith, azimuth) {
  z <- zenith * pi / 180
  a <- azimuth * pi / 180
  c(sin(z) * cos(a), sin(z) * sin(a), cos(z))
}

#' Degree of polarization from Stokes parameters
#'
#' \deqn{DoP = \sqrt{Q^2 + U^2 + V^2} / I}. With \code{V = 0} (the default, and
#' the usual case for the underwater light field, which is essentially linearly
#' polarized) this is the degree of \emph{linear} polarization.
#'
#' @param I Total radiance (Stokes I). Must be > 0.
#' @param Q,U Linear polarization Stokes parameters.
#' @param V Circular polarization Stokes parameter. Default 0.
#' @return Degree of polarization in \code{[0, 1]}. Vectorised. Scalar inputs
#'   are broadcast; incompatible non-scalar lengths are rejected.
#' @details All inputs must be finite numeric vectors. A Stokes vector is
#'   physical only when \eqn{I > 0} and
#'   \eqn{\sqrt{Q^2 + U^2 + V^2} \le I}. Values exceeding this bound by more
#'   than 64 machine epsilons are rejected with a
#'   \code{luxR_polarization_physicality_error}. Values within that round-off
#'   tolerance are returned as exactly one.
#' @seealso \code{\link{angle_of_polarization}}, \code{\link{underwater_polarization}}
#' @examples
#' degree_of_polarization(I = 1, Q = 0.4, U = 0)   # 0.4
#' @export
degree_of_polarization <- function(I, Q, U, V = 0) {
  operation <- "degree_of_polarization"
  .validate_polarization_numeric(I, "I", operation, lower = 0,
                                 lower_open = TRUE)
  .validate_polarization_numeric(Q, "Q", operation)
  .validate_polarization_numeric(U, "U", operation)
  .validate_polarization_numeric(V, "V", operation)
  x <- .broadcast_polarization(list(I = I, Q = Q, U = U, V = V), operation)
  polarized <- .polarization_norm(x$Q, x$U, x$V)
  tolerance <- 64 * .Machine$double.eps * pmax(x$I, polarized)
  invalid <- which(!is.finite(polarized) | polarized > x$I + tolerance)
  if (length(invalid)) {
    i <- invalid[[1L]]
    .stop_polarization(
      paste0("Stokes parameters are physically invalid at index ", i,
             ": polarized intensity ", format(polarized[[i]]),
             " exceeds I = ", format(x$I[[i]]), "."),
      operation, class = "luxR_polarization_physicality_error",
      field = "I,Q,U,V",
      value = c(I = x$I[[i]], Q = x$Q[[i]], U = x$U[[i]], V = x$V[[i]]),
      index = i
    )
  }
  dop <- polarized / x$I
  dop[dop > 1] <- 1
  dop
}

#' Angle of polarization (e-vector orientation) from Stokes parameters
#'
#' \deqn{AoP = \tfrac{1}{2}\,\mathrm{atan2}(U, Q)}. Polarization orientation is
#' axial (period 180 degrees); the value is returned in degrees in the half-open
#' range \code{(-90, 90]}.
#'
#' @param Q,U Linear polarization Stokes parameters.
#' @return Angle of polarization in degrees, in \code{(-90, 90]}. The result is
#'   \code{NA} where both \code{Q} and \code{U} are zero because orientation is
#'   undefined. Scalar inputs are broadcast; incompatible lengths are rejected.
#' @seealso \code{\link{degree_of_polarization}}
#' @examples
#' angle_of_polarization(Q = 1, U = 0)   #  0
#' angle_of_polarization(Q = 0, U = 1)   # 45
#' @export
angle_of_polarization <- function(Q, U) {
  operation <- "angle_of_polarization"
  .validate_polarization_numeric(Q, "Q", operation)
  .validate_polarization_numeric(U, "U", operation)
  x <- .broadcast_polarization(list(Q = Q, U = U), operation)
  undefined <- x$Q == 0 & x$U == 0
  aop <- 0.5 * atan2(x$U, x$Q) * 180 / pi
  # map onto (-90, 90]
  aop <- ((aop + 90) %% 180) - 90
  aop <- ifelse(aop == -90, 90, aop)
  aop[undefined] <- NA_real_
  aop
}

#' Refracted zenith angle of the sun beneath the surface
#'
#' Snell's-law refraction of the solar beam entering water:
#' \eqn{\theta_w = \arcsin(\sin\theta_{air} / n)}. As the in-air zenith
#' approaches 90 degrees the refracted angle approaches the edge of Snell's
#' window (about 48.6 degrees for \code{n = 1.333}); see
#' \code{\link{snells_window}}.
#'
#' @param sun_zenith In-air solar zenith angle in degrees, \code{[0, 90]}.
#' @param n Refractive index of water. Default 1.333.
#' @return Refracted (in-water) solar zenith angle in degrees. Vectorised.
#' @seealso \code{\link{snells_window}}, \code{\link{underwater_polarization}}
#' @examples
#' refracted_solar_angle(0)    # 0
#' refracted_solar_angle(90)   # ~48.6 (edge of Snell's window)
#' @export
refracted_solar_angle <- function(sun_zenith, n = 1.333) {
  operation <- "refracted_solar_angle"
  .validate_polarization_numeric(sun_zenith, "sun_zenith", operation,
                                 lower = 0, upper = 90)
  .validate_polarization_numeric(n, "n", operation, scalar = TRUE,
                                 lower = 1, lower_open = TRUE)
  asin(sin(sun_zenith * pi / 180) / n) * 180 / pi
}

#' Angle between a line of sight and the solar beam
#'
#' The angle \eqn{\Theta} between two directions given as (zenith, azimuth):
#' \deqn{\cos\Theta = \cos\theta_1\cos\theta_2 +
#'        \sin\theta_1\sin\theta_2\cos(\phi_1 - \phi_2).}
#' For the single-scattering polarization model this is the relevant scattering
#' angle (the degree of polarization peaks near \eqn{\Theta = 90^\circ}).
#'
#' @param view_zenith,view_azimuth Viewing direction in degrees.
#' @param sun_zenith,sun_azimuth Solar-beam direction in degrees (use
#'   \code{\link{refracted_solar_angle}} for the in-water zenith).
#' @return Angle in degrees, \code{[0, 180]}. Vectorised over its arguments.
#' @seealso \code{\link{underwater_polarization}}
#' @examples
#' scattering_angle(view_zenith = 90, view_azimuth = 0,
#'                  sun_zenith = 0,  sun_azimuth = 0)   # 90
#' @export
scattering_angle <- function(view_zenith, view_azimuth,
                             sun_zenith, sun_azimuth) {
  operation <- "scattering_angle"
  .validate_polarization_numeric(view_zenith, "view_zenith", operation,
                                 lower = 0, upper = 180)
  .validate_polarization_numeric(view_azimuth, "view_azimuth", operation)
  .validate_polarization_numeric(sun_zenith, "sun_zenith", operation,
                                 lower = 0, upper = 180)
  .validate_polarization_numeric(sun_azimuth, "sun_azimuth", operation)
  x <- .broadcast_polarization(
    list(view_zenith = view_zenith, view_azimuth = view_azimuth,
         sun_zenith = sun_zenith, sun_azimuth = sun_azimuth),
    operation
  )
  tv <- x$view_zenith * pi / 180; av <- x$view_azimuth * pi / 180
  ts <- x$sun_zenith  * pi / 180; as <- x$sun_azimuth  * pi / 180
  cos_t <- cos(tv) * cos(ts) + sin(tv) * sin(ts) * cos(av - as)
  tolerance <- 64 * .Machine$double.eps
  invalid <- which(!is.finite(cos_t) |
                   cos_t < -1 - tolerance | cos_t > 1 + tolerance)
  if (length(invalid)) {
    i <- invalid[[1L]]
    .stop_polarization(
      paste0("Scattering-angle cosine violated [-1, 1] at index ", i,
             "; got ", format(cos_t[[i]]), "."),
      operation, class = "luxR_polarization_invariant_error",
      field = "cos_scattering_angle", value = cos_t[[i]], index = i
    )
  }
  acos(pmin(pmax(cos_t, -1), 1)) * 180 / pi
}

# AoP of the singly-scattered field for one geometry: the e-vector is
# perpendicular to the scattering plane (spanned by the view and sun
# directions). Returned as the orientation in the plane transverse to the line
# of sight, measured from the projected local vertical, in degrees (-90, 90].
.field_aop <- function(v, s) {
  e <- c(v[2] * s[3] - v[3] * s[2],     # v x s  (perpendicular to scatter plane)
         v[3] * s[1] - v[1] * s[3],
         v[1] * s[2] - v[2] * s[1])
  if (sqrt(sum(e^2)) < 1e-9) return(NA_real_)   # looking along the sun: undefined
  zref <- c(0, 0, 1)
  uref <- zref - sum(zref * v) * v              # local vertical, projected onto image plane
  if (sqrt(sum(uref^2)) < 1e-9)                 # looking straight up/down: use x-axis
    uref <- c(1, 0, 0) - v[1] * v
  e    <- e    / sqrt(sum(e^2))
  uref <- uref / sqrt(sum(uref^2))
  cross <- c(uref[2] * e[3] - uref[3] * e[2],
             uref[3] * e[1] - uref[1] * e[3],
             uref[1] * e[2] - uref[2] * e[1])
  ang <- atan2(sum(cross * v), sum(uref * e)) * 180 / pi
  ang <- ((ang + 90) %% 180) - 90
  if (ang == -90) 90 else ang
}

#' Tunable Rayleigh-like approximation to underwater polarization
#'
#' A lightweight, analytic single-scattering model of linear polarization in the
#' water column. The degree of polarization follows the Rayleigh-like form
#' \deqn{DoP(\Theta) = DoP_{max}\,\frac{\sin^2\Theta}{1 + \cos^2\Theta},}
#' where \eqn{\Theta} is the scattering angle between the line of sight and the
#' refracted solar beam (\code{\link{scattering_angle}}); polarization is maximal
#' at \eqn{\Theta = 90^\circ} and vanishes toward the sun and anti-sun. With
#' depth, multiple scattering randomizes the field, so the model relaxes toward an
#' asymptotic floor:
#' \deqn{DoP(z) = DoP_{asym} + (DoP(\Theta) - DoP_{asym})\,e^{-z/z_p}.}
#' The e-vector (angle of polarization) is perpendicular to the scattering plane.
#'
#' This is an explicitly uncalibrated, first-order approximation for teaching,
#' geometry exploration, and field intuition. It is not a vector
#' radiative-transfer solution and must not be interpreted as a quantitative
#' prediction without calibration to measurements from the relevant site,
#' wavelength, water type, surface state, and viewing geometry. It omits the
#' wavelength dependence of scattering and refraction, particulate and
#' dissolved constituents, surface waves and polarized skylight, bottom
#' reflection, and a physical multiple-scattering calculation.
#'
#' @param view_zenith,view_azimuth Viewing direction in degrees (zenith: 0 = up,
#'   90 = horizontal, 180 = down). Vectorised. Scalars are broadcast; implicit
#'   partial recycling is rejected.
#' @param sun_zenith In-air solar zenith angle in degrees. Refracted internally
#'   via \code{\link{refracted_solar_angle}}.
#' @param sun_azimuth Solar azimuth in degrees. Default 0.
#' @param depth Depth in metres (\eqn{\geq 0}). Default 0.
#' @param dop_max Maximum (surface, 90-degree-scattering) degree of polarization.
#'   Default 0.4 is an illustrative value at the upper end of the approximately
#'   0.25--0.40 maxima reported at 15 m in clear tropical marine water by Cronin
#'   and Shashar (2001). Because this model defines \code{dop_max} at depth zero,
#'   that observation does not constitute a calibration of the default. The
#'   value is not transferable to other water types.
#' @param dop_asym Asymptotic deep-field degree of polarization. Default 0.03
#'   is a heuristic illustrative floor, not an empirically calibrated constant.
#' @param z_p Depth scale (m) over which DoP relaxes toward \code{dop_asym}.
#'   Default 20 is a heuristic illustrative scale, not an empirical attenuation
#'   length. Site-specific use requires calibration.
#' @param n Refractive index of water. Default 1.333 is a conventional visible-
#'   light approximation. Refractive index varies with wavelength, temperature,
#'   and salinity.
#' @return A data frame with one row per viewing direction and columns
#'   \code{scattering_angle} (deg), \code{dop} (0–1), and \code{aop} (deg,
#'   \code{(-90, 90]}; \code{NA} when looking along the solar beam). The data
#'   frame has a \code{"luxR.polarization"} attribute recording model status,
#'   model version, parameters, and the validity statement.
#' @references
#'   Cronin TW, Shashar N (2001) The linearly polarized light field in clear,
#'   tropical marine waters. Journal of Experimental Biology 204:2461-2467.
#'
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 8.
#' @seealso \code{\link{degree_of_polarization}}, \code{\link{scattering_angle}},
#'   \code{\link{refracted_solar_angle}}, \code{\link{snells_window}}
#' @examples
#' # DoP across viewing zenith with the sun overhead, near the surface:
#' underwater_polarization(view_zenith = seq(0, 90, 15), view_azimuth = 0,
#'                         sun_zenith = 0, depth = 1)
#' @export
underwater_polarization <- function(view_zenith, view_azimuth = 0,
                                    sun_zenith, sun_azimuth = 0,
                                    depth = 0,
                                    dop_max = 0.4, dop_asym = 0.03,
                                    z_p = 20, n = 1.333) {
  operation <- "underwater_polarization"
  configuration <- list(dop_max = dop_max, dop_asym = dop_asym,
                        z_p = z_p, n = n)
  .validate_polarization_numeric(view_zenith, "view_zenith", operation,
                                 lower = 0, upper = 180,
                                 configuration = configuration)
  .validate_polarization_numeric(view_azimuth, "view_azimuth", operation,
                                 configuration = configuration)
  .validate_polarization_numeric(sun_zenith, "sun_zenith", operation,
                                 lower = 0, upper = 90,
                                 configuration = configuration)
  .validate_polarization_numeric(sun_azimuth, "sun_azimuth", operation,
                                 configuration = configuration)
  .validate_polarization_numeric(depth, "depth", operation, lower = 0,
                                 configuration = configuration)
  .validate_polarization_numeric(dop_max, "dop_max", operation, scalar = TRUE,
                                 lower = 0, upper = 1,
                                 configuration = configuration)
  .validate_polarization_numeric(dop_asym, "dop_asym", operation,
                                 scalar = TRUE, lower = 0, upper = 1,
                                 configuration = configuration)
  .validate_polarization_numeric(z_p, "z_p", operation, scalar = TRUE,
                                 lower = 0, lower_open = TRUE,
                                 configuration = configuration)
  .validate_polarization_numeric(n, "n", operation, scalar = TRUE,
                                 lower = 1, lower_open = TRUE,
                                 configuration = configuration)
  if (dop_asym > dop_max) {
    .stop_polarization(
      paste0("`dop_asym` must not exceed `dop_max`; got ", dop_asym,
             " > ", dop_max, "."),
      operation, field = "dop_asym", value = dop_asym,
      configuration = configuration
    )
  }
  m <- .broadcast_polarization(
    list(view_zenith = view_zenith, view_azimuth = view_azimuth,
         sun_zenith = sun_zenith, sun_azimuth = sun_azimuth, depth = depth),
    operation, configuration
  )
  sun_w <- refracted_solar_angle(m$sun_zenith, n)

  theta <- scattering_angle(m$view_zenith, m$view_azimuth,
                            sun_w, m$sun_azimuth)
  ct  <- cos(theta * pi / 180)
  dop_single <- dop_max * (1 - ct^2) / (1 + ct^2)
  dop <- dop_asym + (dop_single - dop_asym) * exp(-m$depth / z_p)
  tolerance <- 64 * .Machine$double.eps
  invalid <- which(!is.finite(dop) | dop < -tolerance | dop > 1 + tolerance)
  if (length(invalid)) {
    i <- invalid[[1L]]
    .stop_polarization(
      paste0("Rayleigh-like DoP violated [0, 1] at index ", i,
             "; got ", format(dop[[i]]), "."),
      operation, class = "luxR_polarization_invariant_error",
      field = "dop", value = dop[[i]], index = i,
      configuration = configuration
    )
  }

  aop <- vapply(seq_along(m$view_zenith), function(i) {
    .field_aop(.dir_vec(m$view_zenith[i], m$view_azimuth[i]),
               .dir_vec(sun_w[i],          m$sun_azimuth[i]))
  }, numeric(1))

  result <- data.frame(scattering_angle = theta, dop = dop, aop = aop)
  attr(result, "luxR.polarization") <- list(
    model = "tunable Rayleigh-like single-scattering approximation",
    model_version = .POLARIZATION_MODEL_VERSION,
    status = "uncalibrated_approximation",
    quantitative_prediction = FALSE,
    parameters = configuration,
    evidence = list(
      reference = paste(
        "Cronin TW, Shashar N (2001), Journal of Experimental Biology",
        "204:2461-2467"
      ),
      doi = "10.1242/jeb.204.14.2461",
      observation_domain = paste(
        "Clear tropical reef water, 15 m depth, 350-600 nm; strongest",
        "polarization reported 60-90 degrees from the sun."
      ),
      benchmark = "qualitative angular consistency only; not calibration"
    ),
    valid_domain = paste(
      "Illustrative geometry exploration only; site-specific quantitative use",
      "requires calibration by wavelength, water type, surface state, depth,",
      "and viewing geometry."
    )
  )
  result
}

#' Polarization contrast between a target and its background
#'
#' How distinct a target's polarization is from its background, for a
#' polarization-sensitive viewer. Each polarization state is mapped to its
#' normalised linear-polarization (Stokes) coordinates
#' \deqn{q = DoP\cos 2\psi, \qquad u = DoP\sin 2\psi,}
#' where \eqn{\psi} is the angle of polarization; the \strong{polarization
#' distance} is the Euclidean separation in this plane,
#' \deqn{\Delta P = \sqrt{(q_t - q_b)^2 + (u_t - u_b)^2}.}
#' The factor of two in the angle correctly handles the 180-degree periodicity
#' of polarization orientation, so orthogonal e-vectors (90 degrees apart) at
#' equal degree of polarization give the maximal angular contrast. This is the
#' geometric core of How & Marshall's (2014) polarization-distance model.
#'
#' @param target_dop,target_aop Degree of polarization (0-1) and angle of
#'   polarization (degrees) of the target. Vectorised.
#' @param background_dop,background_aop Degree and angle of polarization of the
#'   background. Vectorised. Scalars are broadcast; implicit partial recycling
#'   is rejected.
#' @return A data frame with columns \code{delta_dop} (absolute difference in
#'   degree of polarization), \code{delta_aop} (axial angular difference in
#'   degrees, \code{[0, 90]}), and \code{distance} (the polarization distance
#'   \eqn{\Delta P}).
#' @references
#'   How MJ, Marshall NJ (2014) Polarization distance: a framework for modelling
#'   object detection by polarization vision systems. Proceedings of the Royal
#'   Society B 281:20131632.
#' @seealso \code{\link{underwater_polarization}},
#'   \code{\link{degree_of_polarization}}, \code{\link{weber_contrast}}
#' @examples
#' # A horizontally polarized target against a weakly polarized background:
#' polarization_contrast(target_dop = 0.5, target_aop = 0,
#'                       background_dop = 0.1, background_aop = 45)
#' @export
polarization_contrast <- function(target_dop, target_aop,
                                  background_dop, background_aop) {
  operation <- "polarization_contrast"
  .validate_polarization_numeric(target_dop, "target_dop", operation,
                                 lower = 0, upper = 1)
  .validate_polarization_numeric(target_aop, "target_aop", operation)
  .validate_polarization_numeric(background_dop, "background_dop", operation,
                                 lower = 0, upper = 1)
  .validate_polarization_numeric(background_aop, "background_aop", operation)
  x <- .broadcast_polarization(
    list(target_dop = target_dop, target_aop = target_aop,
         background_dop = background_dop, background_aop = background_aop),
    operation
  )
  qt <- x$target_dop     * cos(2 * x$target_aop     * pi / 180)
  ut <- x$target_dop     * sin(2 * x$target_aop     * pi / 180)
  qb <- x$background_dop * cos(2 * x$background_aop * pi / 180)
  ub <- x$background_dop * sin(2 * x$background_aop * pi / 180)

  d_aop <- abs(x$target_aop - x$background_aop) %% 180
  d_aop <- pmin(d_aop, 180 - d_aop)          # axial: orientation has period 180

  data.frame(
    delta_dop = abs(x$target_dop - x$background_dop),
    delta_aop = d_aop,
    distance  = sqrt((qt - qb)^2 + (ut - ub)^2)
  )
}
