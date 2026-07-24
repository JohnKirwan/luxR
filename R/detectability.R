# detectability.R — object-vs-background detection (achromatic + chromatic)
#
# As a viewer moves away from an object in water, the object's own light is
# scattered out of the path and replaced by veiling light, so its apparent
# contrast decays as C(r) = C0 * exp(-c * r), where c is the beam attenuation
# coefficient (Johnsen 2012, ch. 5). The scalar heuristic treats the object as
# detectable while contrast stays above threshold, giving a scenario distance
# r = ln(C0 / threshold) / c. The spectral-path scenario instead propagates
# radiances wavelength by wavelength and recomputes receptor catches. Neither is
# an empirically validated organismal detection-range prediction.

.stop_detection <- function(message, class = "lux_detection_input_error", ...) {
  random_seed <- if (exists(".Random.seed", envir = .GlobalEnv,
                            inherits = FALSE)) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NA_integer_
  }
  condition <- structure(
    c(
      list(
        message = message,
        call = NULL,
        model_version = .luxr_package_version(),
        code_commit = .luxr_code_commit(),
        random_seed = random_seed
      ),
      list(...)
    ),
    class = c(class, "lux_detection_error", "luxR_error", "error", "condition")
  )
  stop(condition)
}

.validate_detection_numeric <- function(x, field, operation,
                                        scalar = FALSE, positive = FALSE,
                                        nonnegative = FALSE) {
  if (!is.numeric(x) || is.complex(x) || is.object(x) ||
      !is.null(dim(x)) || length(x) == 0L) {
    .stop_detection(
      paste0("`", field, "` must be a non-empty numeric vector."),
      field = field, value = x, operation = operation
    )
  }
  if (scalar && length(x) != 1L) {
    .stop_detection(
      paste0("`", field, "` must be one numeric value; got length ",
             length(x), "."),
      field = field, value = x, operation = operation
    )
  }
  invalid <- which(!is.finite(x))
  if (length(invalid)) {
    i <- invalid[1L]
    .stop_detection(
      paste0("`", field, "` must contain only finite values; index ", i,
             " is ", format(x[i]), "."),
      field = field, value = x[i], index = i, operation = operation
    )
  }
  if (positive && any(x <= 0)) {
    i <- which(x <= 0)[1L]
    .stop_detection(
      paste0("`", field, "` must be strictly positive; index ", i,
             " is ", format(x[i]), "."),
      field = field, value = x[i], index = i, operation = operation
    )
  }
  if (nonnegative && any(x < 0)) {
    i <- which(x < 0)[1L]
    .stop_detection(
      paste0("`", field, "` must be non-negative; index ", i,
             " is ", format(x[i]), "."),
      field = field, value = x[i], index = i, operation = operation
    )
  }
  invisible(x)
}

.validate_detection_grid <- function(lambda, operation) {
  .validate_detection_numeric(lambda, "lambda", operation, positive = TRUE)
  if (length(lambda) < 2L || any(diff(lambda) <= 0)) {
    .stop_detection(
      "`lambda` must contain at least two strictly increasing wavelengths.",
      field = "lambda", value = lambda, operation = operation
    )
  }
  invisible(lambda)
}

.validate_detection_threshold <- function(x, field, upper = Inf,
                                          operation = "detection_range") {
  .validate_detection_numeric(x, field, operation, scalar = TRUE,
                              positive = TRUE)
  if (x >= upper) {
    .stop_detection(
      paste0("`", field, "` must be less than ", format(upper), "; got ",
             format(x), "."),
      field = field, value = x, operation = operation
    )
  }
  invisible(x)
}

# Numeric values of a reflectance / illuminant on the `lambda` grid.
.spec_vals <- function(x, lambda, what) {
  if (inherits(x, "lux_spectrum")) {
    expected <- switch(
      what,
      object = c(quantity = "reflectance", unit = "dimensionless"),
      background = c(quantity = "reflectance", unit = "dimensionless"),
      illuminant = c(quantity = "irradiance", unit = "W/m2/nm"),
      veiling = c(quantity = "radiance", unit = "W/m2/sr/nm"),
      NULL
    )
    if (!is.null(expected) &&
        (!identical(x$quantity, unname(expected[["quantity"]])) ||
         !identical(x$unit, unname(expected[["unit"]]))))
      .stop_detection(
        paste0(
          "`", what, "` must be a ", expected[["quantity"]],
          " lux_spectrum in ", expected[["unit"]], "; got quantity '",
          x$quantity, "' in ", x$unit, "."
        ),
        field = what, value = x, operation = "spectral input",
        expected_quantity = expected[["quantity"]],
        expected_unit = expected[["unit"]]
      )
    if (min(lambda) < min(x$lambda) || max(lambda) > max(x$lambda))
      .stop_detection(
        paste0("`", what, "` does not cover the requested wavelength grid; ",
               "extrapolation is not allowed."),
        field = what, value = range(x$lambda), operation = "spectral input"
      )
    values <- if (length(x$lambda) == length(lambda) &&
                  isTRUE(all.equal(x$lambda, lambda))) {
      x$E
    } else {
      stats::approx(x$lambda, x$E, xout = lambda, rule = 1)$y
    }
  } else if (is.numeric(x)) {
    if (length(x) != length(lambda))
      .stop_detection(
        paste0("`", what, "` must be the same length as `lambda` ",
               "(or a lux_spectrum)."),
        field = what, value = x, operation = "spectral input"
      )
    values <- x
  } else {
    .stop_detection(
      paste0("`", what, "` must be a numeric vector or a lux_spectrum."),
      field = what, value = x, operation = "spectral input"
    )
  }
  .validate_detection_numeric(values, what, "spectral input", nonnegative = TRUE)
  values
}

# Effective contrast-attenuation coefficient for a viewing direction. Horizontal
# uses the beam attenuation c; looking up uses c - Kd (longer range), looking
# down uses c + Kd (shorter range) (Johnsen 2012, ch. 5).
.effective_c <- function(Kd, kd_to_c, direction, beam_c = NULL) {
  Kd_value <- as.numeric(Kd)
  c_beam <- if (is.null(beam_c)) {
    Kd_value * kd_to_c
  } else {
    as.numeric(beam_c)
  }
  ceff <- switch(direction,
    horizontal = c_beam,
    up         = c_beam - Kd_value,
    down       = c_beam + Kd_value)
  if (any(!is.finite(ceff)) || any(ceff <= 0))
    .stop_detection(
      paste0(
        "Effective attenuation must be finite and strictly positive; check ",
        "`Kd`, `kd_to_c`, `beam_c`, and `direction`."
      ),
      field = "effective_attenuation", value = ceff,
      operation = "effective attenuation", Kd = Kd, kd_to_c = kd_to_c,
      beam_c = beam_c, direction = direction
    )
  ceff
}

# Viewer "brightness" (achromatic channel) of a radiance spectrum: weighted
# catch of a validated achromatic channel, or total photon radiance when no
# species model is requested.
.viewer_brightness <- function(L, lambda, species, receptor, binwidth) {
  if (is.null(species))
    return(sum(W2photon(L, lambda) * binwidth))
  rows <- .default_channel_receptors(
    species = species,
    channel_role = "achromatic",
    receptor = receptor
  )
  weights <- attr(rows, "channel_weights")
  lam_s <- seq(300, 750, by = 1)
  catches <- vapply(seq_len(nrow(rows)), function(i) {
    S <- govardovskii_template(lam_s, rows$lambda_max[i], rows$chromophore[i])
    quantum_catch(L, lambda, S, input_unit = "W/m2/nm", total = TRUE,
                  binwidth = binwidth)
  }, numeric(1))
  sum(catches * weights)
}


#' Inherent (zero-distance) contrast of an object against its background.
#'
#' Computes the contrast a viewer perceives between an object and its background
#' at zero viewing distance, from their reflectance spectra and the in-water
#' illuminant. Two channels are available: an \strong{achromatic} (brightness)
#' Weber contrast and a \strong{chromatic} distance (\eqn{\Delta S}, in JNDs)
#' from the Vorobyev-Osorio model. Object and background radiances are formed as
#' reflectance times illuminant.
#'
#' @param object,background Reflectance spectra (numeric vectors on the
#'   \code{lambda} grid, or dimensionless reflectance \code{lux_spectrum}
#'   objects). Values must be finite and in [0, 1].
#' @param illuminant The in-water light field illuminating both (numeric vector
#'   or irradiance \code{lux_spectrum} in W/m2/nm); e.g. a depth-propagated
#'   solar spectrum. Values must be finite and non-negative.
#' @param lambda  Finite, positive, strictly increasing, regularly spaced
#'   wavelength grid in nm.
#' @param species Species name in \code{species_sensitivities}. Required for the
#'   chromatic channel. For the achromatic channel, a species must have a cited
#'   default in \code{\link{species_channels}}. If \code{NULL}, achromatic
#'   brightness is explicitly treated as total photon radiance without a species
#'   visual model.
#' @param receptor Receptor class(es) to include. Default \code{NULL} uses the
#'   complete validated default for each requested species channel. An explicit
#'   selection must be valid for every requested channel.
#' @param noise    Receptor Weber fraction(s) for the chromatic channel; passed
#'   to \code{\link{colour_jnd}}. Default 0.05.
#' @param channel  \code{"both"} (default), \code{"achromatic"}, or
#'   \code{"chromatic"}.
#' @param binwidth Bin width in nm; inferred from \code{lambda} if \code{NULL}.
#' @return A list with elements \code{achromatic} (Weber contrast) and
#'   \code{chromatic} (\eqn{\Delta S} in JNDs); unrequested channels are
#'   \code{NA}.
#' @references
#'   Johnsen S (2012) The Optics of Life: A Biologist's Guide to Light in
#'   Nature. Princeton University Press. (Ch. 5: contrast and sighting distance.)
#' @seealso \code{\link{contrast_at_distance}}, \code{\link{detection_range}},
#'   \code{\link{colour_jnd}}, \code{\link{weber_contrast}}
#' @examples
#' sp  <- solar_irradiance("clear_noon")
#' lam <- sp$wavelength
#' grey <- rep(0.3, length(lam))
#' red  <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
#' inherent_contrast(red, grey, sp$irradiance, lam, species = "Danio rerio")
#' @export
inherent_contrast <- function(object, background, illuminant, lambda,
                              species = NULL, receptor = NULL, noise = 0.05,
                              channel = c("both", "achromatic", "chromatic"),
                              binwidth = NULL) {
  channel <- match.arg(channel)
  .validate_detection_grid(lambda, "inherent_contrast")
  widths <- diff(lambda)
  if (max(abs(widths - widths[1L])) > .grid_tolerance(widths))
    .stop_detection(
      "Detection calculations require a regularly spaced `lambda` grid.",
      field = "lambda", value = lambda, operation = "inherent_contrast"
    )
  if (is.null(binwidth)) {
    binwidth <- widths[1L]
  }
  .validate_detection_numeric(binwidth, "binwidth", "inherent_contrast",
                              scalar = TRUE, positive = TRUE)

  Ro <- .spec_vals(object,     lambda, "object")
  Rb <- .spec_vals(background, lambda, "background")
  E  <- .spec_vals(illuminant, lambda, "illuminant")
  if (any(Ro > 1) || any(Rb > 1))
    .stop_detection(
      "`object` and `background` reflectance must lie in [0, 1].",
      field = c("object", "background"),
      value = c(object = max(Ro), background = max(Rb)),
      operation = "inherent_contrast"
    )
  if (!any(E > 0))
    .stop_detection(
      "`illuminant` must contain at least one strictly positive value.",
      field = "illuminant", value = E, operation = "inherent_contrast"
    )
  Lo <- Ro * E                                   # object radiance
  Lb <- Rb * E                                   # background radiance

  out <- list(achromatic = NA_real_, chromatic = NA_real_)
  if (channel %in% c("both", "achromatic")) {
    Bo <- .viewer_brightness(Lo, lambda, species, receptor, binwidth)
    Bb <- .viewer_brightness(Lb, lambda, species, receptor, binwidth)
    if (!is.finite(Bo) || !is.finite(Bb) || Bo < 0 || Bb <= 0)
      .stop_detection(
        paste0(
          "Achromatic modelling requires a finite non-negative object catch ",
          "and a finite strictly positive background catch."
        ),
        "lux_detection_signal_error", operation = "inherent_contrast",
        object_catch = Bo, background_catch = Bb, species = species,
        receptor = receptor
      )
    out$achromatic <- weber_contrast(Bo, Bb)
  }
  if (channel %in% c("both", "chromatic")) {
    if (is.null(species))
      .stop_detection(
        "Chromatic contrast requires a `species` (with >= 2 receptors).",
        field = "species", value = species, operation = "inherent_contrast"
      )
    out$chromatic <- colour_jnd(Lo, Lb, lambda = lambda, species = species,
                                receptor = receptor, noise = noise,
                                binwidth = binwidth)
  }
  out
}


#' Heuristic scalar contrast remaining after a sighting path through water.
#'
#' Attenuates an inherent contrast over a horizontal (or vertical) viewing path
#' as a teaching/scenario heuristic:
#' \eqn{C(r) = C_0 \, e^{-c_{\mathrm{eff}} r}} (Johnsen 2012, ch. 5). The beam
#' attenuation \eqn{c} is approximated as \code{Kd * kd_to_c}; looking up uses
#' \eqn{c - K_d} and looking down \eqn{c + K_d}.
#'
#' @param C0       Inherent (zero-distance) contrast (achromatic Weber contrast
#'   or chromatic \eqn{\Delta S}). Scalar or vector.
#' @param distance Finite, non-negative viewing distance(s) in metres. Scalar
#'   or vector.
#' @param Kd       Diffuse attenuation coefficient at the sighting wavelength
#'   (1/m).
#' @param kd_to_c  Ratio \eqn{c / K_d}. Default 1.5. See \code{\link{visual_range}}.
#'   Ignored when \code{beam_c} is supplied.
#' @param direction Viewing direction: \code{"horizontal"} (default),
#'   \code{"up"}, or \code{"down"}.
#' @param beam_c   Optional measured beam attenuation \eqn{c} (1/m), e.g. from
#'   \code{beam_attenuation()}, used instead of \code{Kd * kd_to_c}. \code{Kd}
#'   is still used for the \code{"up"}/\code{"down"} corrections.
#' @details
#' This scalar calculation does not propagate spectra or recompute receptor
#' catches. In particular, applying it to a chromatic JND is not a validated
#' chromatic-vision model; use \code{detection_range(model = "spectral_path")}
#' for wavelength-resolved propagation.
#'
#' @return Heuristic contrast remaining at each distance.
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.
#' @seealso \code{\link{inherent_contrast}}, \code{\link{detection_range}}
#' @examples
#' contrast_at_distance(C0 = 1, distance = c(0, 5, 10), Kd = 0.06)
#' @export
contrast_at_distance <- function(C0, distance, Kd, kd_to_c = 1.5,
                                 direction = c("horizontal", "up", "down"),
                                 beam_c = NULL) {
  direction <- match.arg(direction)
  .validate_detection_numeric(C0, "C0", "contrast_at_distance")
  .validate_detection_numeric(distance, "distance", "contrast_at_distance",
                              nonnegative = TRUE)
  .validate_detection_numeric(Kd, "Kd", "contrast_at_distance",
                              positive = TRUE)
  .validate_detection_numeric(kd_to_c, "kd_to_c", "contrast_at_distance",
                              scalar = TRUE, positive = TRUE)
  if (!is.null(beam_c))
    .validate_detection_numeric(beam_c, "beam_c", "contrast_at_distance",
                                positive = TRUE)
  ceff <- .effective_c(Kd, kd_to_c, direction, beam_c)
  as.numeric(C0 * exp(-ceff * distance))
}

.scalar_detection_limit <- function(signal0, threshold, ceff, max_distance) {
  if (!is.numeric(signal0) || length(signal0) != 1L || !is.finite(signal0))
    .stop_detection(
      "The zero-distance signal must be one finite numeric value.",
      "lux_detection_signal_error", field = "signal0", value = signal0,
      operation = "detection_range"
    )
  if (abs(signal0) <= threshold)
    return(list(range = 0, status = "below_at_origin"))
  value <- log(abs(signal0) / threshold) / ceff
  if (!is.finite(value) || value < 0)
    .stop_detection(
      "The scalar threshold calculation produced an invalid range.",
      "lux_detection_calculation_error", operation = "detection_range",
      signal0 = signal0, threshold = threshold, effective_attenuation = ceff,
      calculated_range = value
    )
  if (value > max_distance)
    return(list(range = NA_real_, status = "not_crossed_within_limit"))
  list(range = value, status = "crossed")
}

.spectral_signals <- function(distance, object_radiance, background_radiance,
                              veiling_radiance, lambda, effective_c, species,
                              receptor, noise, channel, binwidth) {
  transmission <- exp(-effective_c * distance)
  object_seen <- veiling_radiance +
    (object_radiance - veiling_radiance) * transmission
  background_seen <- veiling_radiance +
    (background_radiance - veiling_radiance) * transmission

  out <- list(achromatic = NA_real_, chromatic = NA_real_)
  if (channel %in% c("both", "achromatic")) {
    object_catch <- .viewer_brightness(
      object_seen, lambda, species, receptor, binwidth
    )
    background_catch <- .viewer_brightness(
      background_seen, lambda, species, receptor, binwidth
    )
    if (!is.finite(object_catch) || !is.finite(background_catch) ||
        object_catch < 0 || background_catch <= 0)
      .stop_detection(
        "Spectral propagation produced invalid achromatic catches.",
        "lux_detection_signal_error", operation = "spectral_path",
        distance = distance, object_catch = object_catch,
        background_catch = background_catch, species = species,
        receptor = receptor
      )
    out$achromatic <- weber_contrast(object_catch, background_catch)
  }
  if (channel %in% c("both", "chromatic")) {
    if (is.null(species))
      .stop_detection(
        "Chromatic spectral-path modelling requires a `species`.",
        field = "species", value = species, operation = "spectral_path"
      )
    out$chromatic <- colour_jnd(
      object_seen, background_seen, lambda = lambda, species = species,
      receptor = receptor, noise = noise, binwidth = binwidth
    )
  }
  out
}

.spectral_detection_limit <- function(signal, threshold, max_distance,
                                      search_points, channel) {
  grid <- seq(0, max_distance, length.out = search_points)
  values <- vapply(grid, signal, numeric(1))
  if (any(!is.finite(values)))
    .stop_detection(
      "Spectral propagation produced a non-finite detection signal.",
      "lux_detection_calculation_error", operation = "spectral_path",
      channel = channel, distance = grid[which(!is.finite(values))[1L]],
      signal = values[which(!is.finite(values))[1L]]
    )
  strength <- if (identical(channel, "achromatic")) abs(values) else values
  detectable <- strength > threshold
  if (!any(detectable))
    return(list(range = 0, status = "below_at_origin"))
  if (detectable[length(detectable)])
    return(list(range = NA_real_, status = "not_crossed_within_limit"))

  transitions <- which(detectable[-length(detectable)] & !detectable[-1L])
  if (!length(transitions))
    .stop_detection(
      "No downward threshold crossing could be bracketed.",
      "lux_detection_calculation_error", operation = "spectral_path",
      channel = channel, threshold = threshold, max_distance = max_distance,
      search_points = search_points
    )
  i <- transitions[length(transitions)]
  objective <- function(distance) {
    value <- signal(distance)
    if (identical(channel, "achromatic")) value <- abs(value)
    value - threshold
  }
  root <- stats::uniroot(objective, interval = grid[c(i, i + 1L)],
                         tol = max(.Machine$double.eps^0.25,
                                   max_distance / search_points / 1000))$root
  list(range = root, status = "crossed")
}


#' Scenario estimate of object-background threshold-crossing distance.
#'
#' Generalises \code{\link{visual_range}} by using the estimated inherent
#' contrast of an object against its background (from
#' \code{\link{inherent_contrast}}) rather than assuming a contrast of 1. The
#' default scalar heuristic uses
#' \eqn{r = \ln(|C_0| / \text{threshold}) / c_{\mathrm{eff}}}. The spectral-path
#' model instead propagates object, background, and veiling radiances at every
#' wavelength and recomputes receptor catches at each evaluated distance.
#'
#' Neither model is an empirically validated prediction of actual organismal
#' detection distance. They omit target angular size, acuity, photon limitation,
#' adaptation changes, behaviour, and observation probability.
#'
#' The spectral-path scenario treats object and background as coplanar stimuli
#' sharing one water path and one asymptotic veiling radiance. For each stimulus
#' it evaluates
#' \deqn{L(r, \lambda) = L_v(\lambda) +
#' [L_0(\lambda) - L_v(\lambda)] e^{-c_{\mathrm{eff}}(\lambda) r}.}
#' Both stimuli therefore converge toward the supplied veiling spectrum. This is
#' a lightweight single-path model, not a multiple-scattering radiative-transfer
#' solution. Because wavelength-dependent signals can be non-monotonic, the
#' reported spectral distance is the furthest downward threshold crossing
#' bracketed by \code{search_points}; callers should check resolution sensitivity.
#'
#' @inheritParams inherent_contrast
#' @param Kd       Positive diffuse attenuation coefficient (1/m). The scalar
#'   heuristic requires one value at the sighting wavelength, e.g.
#'   \code{jerlov_Kd("IA", lambda = 490)}. The spectral-path model accepts one
#'   value or one value per wavelength.
#' @param kd_to_c  Ratio \eqn{c / K_d}. Default 1.5. Ignored when \code{beam_c}
#'   is supplied.
#' @param channel  \code{"both"} (default), \code{"achromatic"}, or
#'   \code{"chromatic"}.
#' @param contrast_threshold Achromatic Weber-contrast threshold. Default 0.02.
#' @param jnd_threshold Chromatic threshold in JNDs. Default 1.
#' @param direction Viewing direction: \code{"horizontal"} (default),
#'   \code{"up"}, or \code{"down"}.
#' @param beam_c   Optional measured beam attenuation \eqn{c} (1/m), e.g. from
#'   \code{beam_attenuation()}, used instead of \code{Kd * kd_to_c}. For the
#'   spectral-path model this is required and must have one value per wavelength.
#' @param model \code{"scalar_heuristic"} (default) or \code{"spectral_path"}.
#'   The former exponentially attenuates a scalar contrast/JND. The latter
#'   propagates wavelength-resolved radiances and recomputes receptor catches.
#' @param veiling Veiling/path radiance spectrum on the \code{lambda} grid.
#'   Required for the spectral-path model, in the radiance scale produced from
#'   \code{illuminant} by \code{geometry} (normally W m-2 sr-1 nm-1).
#' @param max_distance Finite positive maximum search distance in metres.
#'   A criterion still detectable there is reported as censored, not infinite.
#' @param search_points Integer number of distances used to bracket the furthest
#'   downward threshold crossing in the spectral-path model. Default 1001.
#' @param geometry Irradiance-to-radiance geometry used by the spectral-path
#'   model: \code{"lambertian"} (default), \code{"scalar"},
#'   \code{"collimated"}, or \code{"custom"}. See
#'   \code{\link{irradiance2radiance}}.
#' @param solid_angle Solid angle in steradians when
#'   \code{geometry = "custom"}.
#' @return A list with elements \code{achromatic} and \code{chromatic} giving
#'   scenario estimates in metres. A value is 0 when no evaluated distance is
#'   detectable, \code{NA} when the channel was not requested or remained
#'   detectable through \code{max_distance}. Attributes record per-channel
#'   status, model, validation state, and maximum distance.
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.
#' @seealso \code{\link{inherent_contrast}}, \code{\link{contrast_at_distance}},
#'   \code{\link{visual_range}}
#' @examples
#' sp   <- solar_irradiance("clear_noon")
#' lam  <- sp$wavelength
#' grey <- rep(0.3, length(lam))
#' red  <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
#' Kd   <- jerlov_Kd("IA", lambda = 490)
#' detection_range(red, grey, sp$irradiance, lam, Kd = Kd, species = "Danio rerio")
#' @export
detection_range <- function(object, background, illuminant, lambda, Kd,
                            kd_to_c = 1.5, species = NULL, receptor = NULL,
                            channel = c("both", "achromatic", "chromatic"),
                            contrast_threshold = 0.02, jnd_threshold = 1,
                            direction = c("horizontal", "up", "down"),
                            noise = 0.05, binwidth = NULL, beam_c = NULL,
                            model = c("scalar_heuristic", "spectral_path"),
                            veiling = NULL, max_distance = 1000,
                            search_points = 1001L,
                            geometry = c("lambertian", "scalar", "collimated",
                                         "custom"),
                            solid_angle = NULL) {
  channel   <- match.arg(channel)
  direction <- match.arg(direction)
  model <- match.arg(model)
  geometry <- match.arg(geometry)
  .validate_detection_grid(lambda, "detection_range")
  .validate_detection_threshold(
    contrast_threshold, "contrast_threshold", upper = 1,
    operation = "detection_range"
  )
  .validate_detection_threshold(
    jnd_threshold, "jnd_threshold", operation = "detection_range"
  )
  .validate_detection_numeric(kd_to_c, "kd_to_c", "detection_range",
                              scalar = TRUE, positive = TRUE)
  .validate_detection_numeric(max_distance, "max_distance", "detection_range",
                              scalar = TRUE, positive = TRUE)
  .validate_detection_numeric(search_points, "search_points", "detection_range",
                              scalar = TRUE, positive = TRUE)
  if (search_points != as.integer(search_points) || search_points < 3L)
    .stop_detection(
      "`search_points` must be an integer of at least 3.",
      field = "search_points", value = search_points,
      operation = "detection_range"
    )

  if (identical(model, "scalar_heuristic")) {
    if (!is.numeric(Kd) || length(Kd) != 1L || !is.finite(Kd) || Kd <= 0)
      .stop_detection(
        "`Kd` must be a single positive finite number for the scalar heuristic.",
        field = "Kd", value = Kd, operation = "detection_range"
      )
    .validate_detection_numeric(Kd, "Kd", "detection_range",
                                scalar = TRUE, positive = TRUE)
    if (!is.null(beam_c))
      .validate_detection_numeric(beam_c, "beam_c", "detection_range",
                                  scalar = TRUE, positive = TRUE)
  } else {
    if (is.null(beam_c))
      .stop_detection(
        paste0(
          "`beam_c` is required for `model = \"spectral_path\"` and must ",
          "contain one value per wavelength."
        ),
        field = "beam_c", value = beam_c, operation = "detection_range"
      )
    .validate_detection_numeric(Kd, "Kd", "detection_range", positive = TRUE)
    .validate_detection_numeric(beam_c, "beam_c", "detection_range",
                                positive = TRUE)
    if (!(length(Kd) %in% c(1L, length(lambda))))
      .stop_detection(
        "Spectral-path `Kd` must be scalar or the same length as `lambda`.",
        field = "Kd", value = Kd, operation = "detection_range"
      )
    if (length(beam_c) != length(lambda))
      .stop_detection(
        "Spectral-path `beam_c` must be the same length as `lambda`.",
        field = "beam_c", value = beam_c, operation = "detection_range"
      )
    if (is.null(veiling))
      .stop_detection(
        "`veiling` spectral radiance is required for the spectral-path model.",
        field = "veiling", value = veiling, operation = "detection_range"
      )
  }
  ceff <- .effective_c(Kd, kd_to_c, direction, beam_c)

  C0 <- inherent_contrast(object, background, illuminant, lambda,
                          species = species, receptor = receptor, noise = noise,
                          channel = channel, binwidth = binwidth)

  if (identical(model, "scalar_heuristic")) {
    ach <- if (channel %in% c("both", "achromatic"))
      .scalar_detection_limit(C0$achromatic, contrast_threshold, ceff,
                              max_distance) else
        list(range = NA_real_, status = "not_requested")
    chr <- if (channel %in% c("both", "chromatic"))
      .scalar_detection_limit(C0$chromatic, jnd_threshold, ceff,
                              max_distance) else
        list(range = NA_real_, status = "not_requested")
  } else {
    Ro <- .spec_vals(object, lambda, "object")
    Rb <- .spec_vals(background, lambda, "background")
    E <- .spec_vals(illuminant, lambda, "illuminant")
    Lv <- .spec_vals(veiling, lambda, "veiling")
    if (!any(Lv > 0))
      .stop_detection(
        "`veiling` must contain at least one strictly positive value.",
        field = "veiling", value = Lv, operation = "detection_range"
      )
    if (is.null(binwidth)) binwidth <- diff(lambda)[1L]
    illuminant_radiance <- irradiance2radiance(
      E, geometry = geometry, solid_angle = solid_angle
    )
    signal_at <- function(distance) {
      .spectral_signals(
        distance, Ro * illuminant_radiance, Rb * illuminant_radiance,
        Lv, lambda, ceff, species, receptor,
        noise, channel, binwidth
      )
    }
    ach <- if (channel %in% c("both", "achromatic"))
      .spectral_detection_limit(
        function(distance) signal_at(distance)$achromatic,
        contrast_threshold, max_distance, as.integer(search_points),
        "achromatic"
      ) else list(range = NA_real_, status = "not_requested")
    chr <- if (channel %in% c("both", "chromatic"))
      .spectral_detection_limit(
        function(distance) signal_at(distance)$chromatic,
        jnd_threshold, max_distance, as.integer(search_points), "chromatic"
      ) else list(range = NA_real_, status = "not_requested")
  }
  out <- list(achromatic = ach$range, chromatic = chr$range)
  attr(out, "status") <- c(achromatic = ach$status, chromatic = chr$status)
  attr(out, "model") <- model
  attr(out, "validation") <- "scenario estimate; not empirically validated"
  attr(out, "max_distance") <- max_distance
  out
}


#' Object-vs-background detection summary.
#'
#' One-stop wrapper that bundles \code{\link{inherent_contrast}},
#' \code{\link{detection_range}}, and a contrast-vs-distance curve into a single
#' \code{lux_detection} object with \code{print} and \code{plot} methods.
#'
#' @inheritParams detection_range
#' @param distances Optional distance grid (m) for the contrast-vs-distance
#'   curve. Default spans 0 to 1.2x the largest detection range.
#' @return An object of class \code{lux_detection}: a list with \code{inherent}
#'   (zero-distance contrast), \code{range} (scenario estimate per channel),
#'   \code{curve} (data frame of contrast vs distance), status metadata, and
#'   the call settings.
#' @references
#'   Johnsen S (2012) The Optics of Life. Princeton University Press, ch. 5.
#' @seealso \code{\link{inherent_contrast}}, \code{\link{detection_range}},
#'   \code{\link{contrast_at_distance}}
#' @examples
#' sp   <- solar_irradiance("clear_noon")
#' lam  <- sp$wavelength
#' grey <- rep(0.3, length(lam))
#' red  <- 0.2 + 0.25 * exp(-((lam - 625) / 35)^2)
#' d <- detectability(red, grey, sp$irradiance, lam,
#'                    Kd = jerlov_Kd("IA", lambda = 490), species = "Danio rerio")
#' d
#' \dontrun{plot(d)}
#' @export
detectability <- function(object, background, illuminant, lambda, Kd,
                          kd_to_c = 1.5, species = NULL, receptor = NULL,
                          channel = c("both", "achromatic", "chromatic"),
                          contrast_threshold = 0.02, jnd_threshold = 1,
                          direction = c("horizontal", "up", "down"),
                          noise = 0.05, distances = NULL, binwidth = NULL,
                          beam_c = NULL,
                          model = c("scalar_heuristic", "spectral_path"),
                          veiling = NULL, max_distance = 1000,
                          search_points = 1001L,
                          geometry = c("lambertian", "scalar", "collimated",
                                       "custom"),
                          solid_angle = NULL) {
  channel   <- match.arg(channel)
  direction <- match.arg(direction)
  model <- match.arg(model)
  geometry <- match.arg(geometry)

  ic <- inherent_contrast(object, background, illuminant, lambda,
                          species = species, receptor = receptor, noise = noise,
                          channel = channel, binwidth = binwidth)
  dr <- detection_range(object, background, illuminant, lambda, Kd = Kd,
                        kd_to_c = kd_to_c, species = species, receptor = receptor,
                        channel = channel, contrast_threshold = contrast_threshold,
                        jnd_threshold = jnd_threshold, direction = direction,
                        noise = noise, binwidth = binwidth, beam_c = beam_c,
                        model = model, veiling = veiling,
                        max_distance = max_distance,
                        search_points = search_points, geometry = geometry,
                        solid_angle = solid_angle)

  if (is.null(distances)) {
    rmax <- suppressWarnings(max(c(dr$achromatic, dr$chromatic), na.rm = TRUE))
    if (!is.finite(rmax) || rmax <= 0) rmax <- min(max_distance, 10)
    distances <- seq(0, rmax * 1.2, length.out = 100)
  }
  .validate_detection_numeric(distances, "distances", "detectability",
                              nonnegative = TRUE)
  curve <- data.frame(distance = distances)
  if (identical(model, "scalar_heuristic")) {
    if (channel %in% c("both", "achromatic"))
      curve$achromatic <- contrast_at_distance(ic$achromatic, distances, Kd,
                                               kd_to_c, direction, beam_c)
    if (channel %in% c("both", "chromatic"))
      curve$chromatic <- contrast_at_distance(ic$chromatic, distances, Kd,
                                              kd_to_c, direction, beam_c)
  } else {
    Ro <- .spec_vals(object, lambda, "object")
    Rb <- .spec_vals(background, lambda, "background")
    E <- .spec_vals(illuminant, lambda, "illuminant")
    Lv <- .spec_vals(veiling, lambda, "veiling")
    ceff <- .effective_c(Kd, kd_to_c, direction, beam_c)
    if (is.null(binwidth)) binwidth <- diff(lambda)[1L]
    illuminant_radiance <- irradiance2radiance(
      E, geometry = geometry, solid_angle = solid_angle
    )
    signals <- lapply(distances, function(distance) {
      .spectral_signals(
        distance, Ro * illuminant_radiance, Rb * illuminant_radiance,
        Lv, lambda, ceff, species, receptor,
        noise, channel, binwidth
      )
    })
    if (channel %in% c("both", "achromatic"))
      curve$achromatic <- vapply(signals, `[[`, numeric(1), "achromatic")
    if (channel %in% c("both", "chromatic"))
      curve$chromatic <- vapply(signals, `[[`, numeric(1), "chromatic")
  }

  structure(
    list(inherent = ic, range = dr, curve = curve,
         channel = channel, direction = direction,
         contrast_threshold = contrast_threshold, jnd_threshold = jnd_threshold,
         Kd = Kd, kd_to_c = kd_to_c, species = species, model = model,
         status = attr(dr, "status"),
         validation = attr(dr, "validation"), max_distance = max_distance,
         geometry = geometry, solid_angle = solid_angle),
    class = "lux_detection")
}


#' @export
print.lux_detection <- function(x, ...) {
  cat("<lux_detection>", x$direction, "viewing,",
      if (is.null(x$species)) "no species" else x$species, "\n")
  cat("  model:", if (identical(x$model, "spectral_path"))
    "spectral-path scenario estimate" else
    "scalar contrast/JND heuristic scenario estimate", "\n")
  cat("  validation: not empirically validated as an actual detection range\n")
  if (x$channel %in% c("both", "achromatic"))
    cat(sprintf("  achromatic: C0 = %+.3f (Weber)   -> %s  (thr %.3f; %s)\n",
                x$inherent$achromatic,
                if (is.finite(x$range$achromatic))
                  sprintf("estimate %.2f m", x$range$achromatic) else
                  paste0("not crossed by ", format(x$max_distance), " m"),
                x$contrast_threshold, x$status[["achromatic"]]))
  if (x$channel %in% c("both", "chromatic"))
    cat(sprintf("  chromatic : dS = %.3f JND        -> %s  (thr %.2f JND; %s)\n",
                x$inherent$chromatic,
                if (is.finite(x$range$chromatic))
                  sprintf("estimate %.2f m", x$range$chromatic) else
                  paste0("not crossed by ", format(x$max_distance), " m"),
                x$jnd_threshold, x$status[["chromatic"]]))
  invisible(x)
}


#' @export
plot.lux_detection <- function(x, ...) {
  d <- x$curve$distance
  # plot each channel as |contrast| / threshold; detection where this >= 1
  series <- list()
  if (!is.null(x$curve$achromatic))
    series$Achromatic <- list(y = abs(x$curve$achromatic) / x$contrast_threshold,
                              r = x$range$achromatic, col = "steelblue4")
  if (!is.null(x$curve$chromatic))
    series$Chromatic  <- list(y = abs(x$curve$chromatic) / x$jnd_threshold,
                              r = x$range$chromatic, col = "firebrick")

  ymax <- max(1.05, unlist(lapply(series, function(s) max(s$y, na.rm = TRUE))))
  plot(NA, xlim = range(d), ylim = c(0, ymax),
       xlab = "Viewing distance (m)",
       ylab = "Contrast / threshold",
       main = paste0("Heuristic detection scenario (", x$direction,
                     " viewing)"))
  abline(h = 1, lty = 2, col = "grey50")             # detection limit
  for (nm in names(series)) {
    s <- series[[nm]]
    lines(d, s$y, col = s$col, lwd = 2)
    if (is.finite(s$r) && s$r > 0)
      abline(v = s$r, col = s$col, lty = 3)
  }
  legend("topright", legend = names(series),
         col = vapply(series, `[[`, character(1), "col"),
         lwd = 2, bty = "n")
  invisible(x)
}
