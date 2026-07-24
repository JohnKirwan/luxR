# depth_propagation — Beer-Lambert depth physics

.BEER_LAMBERT_MODEL_VERSION <- "beer-lambert-kd-v1"

.BEER_LAMBERT_MODEL_NAME <- "spectral Beer-Lambert diffuse attenuation"

.BEER_LAMBERT_ASSUMPTIONS <- paste(
  "wavelength bins propagate independently; Kd is constant over the modeled",
  "path; the source is spectral irradiance; no angular radiance field,",
  "multiple-scattering solution, or spectral redistribution is modeled"
)

.propagation_model_context <- function(operation, from, to,
                                       Kd_lambda = NULL) {
  jerlov <- attr(Kd_lambda, "luxR.jerlov", exact = TRUE)
  list(
    operation = operation,
    model = .BEER_LAMBERT_MODEL_NAME,
    model_version = .BEER_LAMBERT_MODEL_VERSION,
    package_version = as.character(utils::packageVersion("luxR")),
    code_commit = .luxr_code_commit(),
    equation = "E(to,lambda)=E(from,lambda)*exp[-Kd(lambda)*(to-from)]",
    assumptions = .BEER_LAMBERT_ASSUMPTIONS,
    from_depth_m = from,
    target_depth_m = to,
    attenuation_coefficient_1_per_m = if (is.null(Kd_lambda)) {
      NULL
    } else {
      as.numeric(Kd_lambda)
    },
    jerlov = if (is.list(jerlov)) jerlov else NULL
  )
}

.validate_propagation_spectrum <- function(x, field, operation,
                                            from, to, Kd_lambda) {
  if (!identical(x$quantity, "irradiance")) {
    .stop_lux_spectrum_validation(
      paste0(
        "`", field, "` must contain spectral irradiance for diffuse ",
        "Beer-Lambert propagation; got quantity '", x$quantity, "'."
      ),
      field = field, value = x$quantity,
      subclass = "lux_spectrum_quantity_error",
      context = .propagation_model_context(
        operation, from = from, to = to, Kd_lambda = Kd_lambda
      )
    )
  }
  invisible(x)
}

.validate_propagation_output <- function(x, operation, from, to,
                                         Kd_lambda) {
  invalid <- which(!is.finite(x))
  if (length(invalid) > 0L) {
    i <- invalid[[1L]]
    .stop_lux_spectrum_validation(
      paste0(
        "Beer-Lambert propagation produced a non-finite result at output ",
        "index ", i, ". Inverse propagation can overflow or amplify ",
        "measurement noise; reduce the path length or use a defensible ",
        "reference spectrum."
      ),
      field = "result", value = x[[i]], index = i,
      subclass = "lux_spectrum_numerical_error",
      context = .propagation_model_context(
        operation, from = from, to = to, Kd_lambda = Kd_lambda
      )
    )
  }
  invisible(x)
}

.validate_propagation_numeric <- function(x, field, operation,
                                           nonnegative = FALSE,
                                           scalar = FALSE) {
  context <- list(operation = operation)
  .validate_numeric_vector(x, field, context)

  if (scalar && length(x) != 1L) {
    .stop_lux_spectrum_validation(
      paste0("`", field, "` must be one numeric value; got length ",
             length(x), "."),
      field = field, value = x, subclass = "lux_spectrum_value_error",
      context = context
    )
  }

  invalid <- which(!is.finite(x))
  if (length(invalid) > 0L) {
    i <- invalid[1L]
    .stop_lux_spectrum_validation(
      paste0("`", field, "` must contain only finite values; index ", i,
             " is ", format(x[i]), "."),
      field = field, value = x[i], index = i,
      subclass = "lux_spectrum_value_error", context = context
    )
  }

  if (nonnegative) {
    invalid <- which(x < 0)
    if (length(invalid) > 0L) {
      i <- invalid[1L]
      .stop_lux_spectrum_validation(
        paste0("`", field, "` must contain only non-negative values; index ",
               i, " is ", format(x[i]), "."),
        field = field, value = x[i], index = i,
        subclass = "lux_spectrum_value_error", context = context
      )
    }
  }

  invisible(x)
}

.validate_propagation_flag <- function(x, field, operation) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    .stop_lux_spectrum_validation(
      paste0("`", field, "` must be TRUE or FALSE."),
      field = field, value = x, subclass = "lux_spectrum_type_error",
      context = list(operation = operation)
    )
  }
  invisible(x)
}

.validate_source_target_depths <- function(reference_depth_m,
                                           reference_medium,
                                           target_depth_m,
                                           source_condition,
                                           water_type,
                                           operation) {
  .validate_propagation_numeric(
    reference_depth_m, "reference_depth_m", operation,
    nonnegative = TRUE, scalar = TRUE
  )
  .validate_propagation_numeric(
    target_depth_m, "target_depth_m", operation, nonnegative = TRUE
  )
  .validate_scalar_character(
    reference_medium, "reference_medium", list(operation = operation)
  )
  .validate_scalar_character(
    source_condition, "source_condition", list(operation = operation)
  )
  .validate_scalar_character(
    water_type, "water_type", list(operation = operation)
  )

  if (!reference_medium %in% c("air", "water")) {
    .stop_lux_spectrum_validation(
      paste0("`reference_medium` must be 'air' or 'water'; got '",
             reference_medium, "'."),
      field = "reference_medium", value = reference_medium,
      subclass = "lux_spectrum_value_error",
      context = list(operation = operation, source_condition = source_condition,
                     water_type = water_type)
    )
  }

  shallower <- reference_medium == "water" &
    target_depth_m < reference_depth_m
  if (any(shallower)) {
    invalid_targets <- target_depth_m[shallower]
    .stop_lux_spectrum_validation(
      paste0(
        "Target depth(s) ", paste(format(invalid_targets), collapse = ", "),
        " m are shallower than source '", source_condition,
        "', which is referenced at ", format(reference_depth_m),
        " m in water. Inverse propagation is not supported for bundled or ",
        "uploaded source spectra."
      ),
      field = "target_depth_m", value = invalid_targets,
      subclass = "lux_spectrum_depth_error",
      context = list(
        operation = operation,
        source_condition = source_condition,
        reference_depth_m = reference_depth_m,
        reference_medium = reference_medium,
        water_type = water_type,
        target_depth_m = target_depth_m
      )
    )
  }

  invisible(reference_depth_m)
}

.source_irradiance_in_water <- function(irradiance, reference_medium,
                                        surface_source = c("direct", "diffuse"),
                                        surface_angle = 30,
                                        refractive_index = 1.333,
                                        operation = "source propagation") {
  surface_source <- match.arg(surface_source)
  .validate_propagation_numeric(
    irradiance, "irradiance", operation, nonnegative = TRUE
  )
  .validate_scalar_character(
    reference_medium, "reference_medium", list(operation = operation)
  )
  if (!reference_medium %in% c("air", "water")) {
    .stop_lux_spectrum_validation(
      paste0("reference_medium must be 'air' or 'water'; got '",
             reference_medium, "'."),
      field = "reference_medium", value = reference_medium,
      subclass = "lux_spectrum_value_error",
      context = list(operation = operation)
    )
  }
  .validate_propagation_numeric(
    refractive_index, "refractive_index", operation, scalar = TRUE
  )
  if (refractive_index <= 1) {
    .stop_lux_spectrum_validation(
      "refractive_index must be greater than 1.",
      field = "refractive_index", value = refractive_index,
      subclass = "lux_spectrum_value_error",
      context = list(operation = operation)
    )
  }
  if (surface_source == "direct") {
    .validate_propagation_numeric(
      surface_angle, "surface_angle", operation, scalar = TRUE
    )
    if (surface_angle < 0 || surface_angle > 90) {
      .stop_lux_spectrum_validation(
        "surface_angle must be between 0 and 90 degrees.",
        field = "surface_angle", value = surface_angle,
        subclass = "lux_spectrum_value_error",
        context = list(operation = operation)
      )
    }
  }

  if (reference_medium == "water") return(irradiance)

  tau <- surface_transmittance(
    angle = if (surface_source == "direct") surface_angle else NULL,
    n = refractive_index,
    source = surface_source
  )
  irradiance * tau
}

#' Beer-Lambert attenuation at a single wavelength.
#'
#' Computes E(z) = E0 * exp(-Kd * z). Vectorised over \code{depth}.
#'
#' @details This is the package's principal lightweight water-column model. It
#'   assumes that \eqn{K_d} is constant over the modeled path and propagates
#'   each wavelength independently. It does not solve the angular radiance
#'   field, multiple scattering, or wavelength redistribution. The scalar API
#'   has no inherent wavelength or depth range; the caller is responsible for
#'   supplying a \eqn{K_d} that is valid for the medium and path.
#'
#' @param E0    Surface irradiance. Any unit; result is in the same unit.
#' @param Kd    Diffuse attenuation coefficient in 1/m. Must be >= 0.
#' @param depth Depth(s) in metres. Must be >= 0. Scalar or vector.
#' @return Numeric vector the same length as \code{depth}.
#' @examples
#' attenuate_depth(100, Kd = 0.06, depth = c(0, 10, 25, 50))
#' @export
attenuate_depth <- function(E0, Kd, depth) {
  operation <- "attenuate_depth"
  .validate_propagation_numeric(E0, "E0", operation, nonnegative = TRUE)
  .validate_propagation_numeric(Kd, "Kd", operation, nonnegative = TRUE)
  .validate_propagation_numeric(
    depth, "depth", operation, nonnegative = TRUE
  )
  out <- E0 * exp(-Kd * depth)
  .validate_propagation_output(
    out, operation, from = 0, to = depth, Kd_lambda = Kd
  )
  out
}


#' Propagate a known irradiance to any other depth (bidirectional).
#'
#' Computes E(to) = E_known * exp(-Kd * (to - from)). Works forward
#' (to > from), inverse (to < from, recovering a shallower value), and
#' between any two depths.
#'
#' @param E_known Irradiance at depth \code{from}. Scalar or vector.
#' @param Kd      Diffuse attenuation coefficient in 1/m. Scalar.
#' @param from    Depth of the known measurement in metres. Default 0 (surface).
#' @param to      Target depth(s) in metres. Scalar or vector.
#' @param allow_above_surface Logical; permits negative absolute depths
#'   (above the surface). Default FALSE.
#' @return Irradiance at \code{to}, in the same units as \code{E_known}.
#' @note Un-attenuating with a negative depth delta assumes the water column
#'   is homogeneous above the measurement point. For stratified water bodies
#'   (thermocline, chlorophyll layer) the result will be approximate. Inverse
#'   propagation also amplifies measurement noise and can overflow for long or
#'   strongly attenuating paths. This model does not cross the air-water
#'   interface; use \code{\link{surface_transmittance}} explicitly or a
#'   high-level workflow such as \code{\link{light_at_depth}}.
#' @examples
#' propagate_depth(112400, Kd = 0.062, from = 0, to = 30)
#' propagate_depth(8260,   Kd = 0.062, from = 22, to = 0)
#' @export
propagate_depth <- function(E_known, Kd, from = 0, to,
                            allow_above_surface = FALSE) {
  operation <- "propagate_depth"
  .validate_propagation_numeric(
    E_known, "E_known", operation, nonnegative = TRUE
  )
  .validate_propagation_numeric(
    Kd, "Kd", operation, nonnegative = TRUE, scalar = TRUE
  )
  .validate_propagation_numeric(from, "from", operation, scalar = TRUE)
  .validate_propagation_numeric(to, "to", operation)
  .validate_propagation_flag(
    allow_above_surface, "allow_above_surface", operation
  )
  if (!allow_above_surface && (from < 0 || any(to < 0))) {
    .stop_lux_spectrum_validation(
      paste0("`from` and `to` must contain only non-negative absolute ",
             "depths unless `allow_above_surface = TRUE`."),
      field = c("from", "to"), value = c(from, to),
      subclass = "lux_spectrum_value_error",
      context = list(operation = operation)
    )
  }
  out <- E_known * exp(-Kd * (to - from))
  .validate_propagation_output(
    out, operation, from = from, to = to, Kd_lambda = Kd
  )
  out
}


#' Propagate a surface spectrum through the water column.
#'
#' Applies per-wavelength Kd across a depth grid using the Beer-Lambert law.
#' Returns a tidy data frame, a numeric matrix, or (for lux_spectrum input)
#' a named list of lux_spectrum objects.
#'
#' @details This is a wavelength-resolved Beer-Lambert calculation, not a
#'   radiative-transfer solution. It assumes a homogeneous \eqn{K_d(\lambda)}
#'   over the modeled path, treats wavelengths independently, and accepts only
#'   irradiance when a \code{lux_spectrum} is supplied. The generic numeric API
#'   cannot verify physical quantity or wavelength alignment; callers must
#'   supply aligned irradiance and \eqn{K_d} vectors. Bundled Jerlov
#'   coefficients are supported only from 350--700 nm; see
#'   \code{\link{jerlov_Kd}}.
#'
#' @param E0_lambda Surface spectral irradiance. Length-N numeric vector or
#'   a \code{lux_spectrum} object.
#' @param Kd_lambda Finite, non-negative diffuse attenuation coefficients
#'   (1/m) at the same wavelength bins as \code{E0_lambda}. Length-N numeric
#'   vector.
#' @param depths    Finite, non-negative depths to evaluate in metres. Length-M
#'   numeric vector.
#' @param format    \code{"long"} (default): tidy data frame with columns
#'   \code{depth}, \code{lambda}, \code{E}. \code{"matrix"}: N x M numeric
#'   matrix. Ignored for \code{lux_spectrum} input.
#' @param lambda    Optional wavelength values (nm) for the \code{lambda}
#'   column of the long-format output. Defaults to bin indices 1:N.
#' @return A data frame, matrix, or named list of \code{lux_spectrum}.
#' @references
#'   Kirk JTO (1994) Light and Photosynthesis in Aquatic Ecosystems,
#'   2nd edn. Cambridge University Press.
#' @seealso \code{\link{propagate_spectrum}}, \code{\link{band_irradiance}},
#'   \code{\link{jerlov_Kd}}
#' @examples
#' E0  <- c(10, 20, 30)
#' Kd  <- c(0.01, 0.05, 0.20)
#' lam <- c(450, 550, 650)
#' attenuate_spectrum(E0, Kd, depths = c(0, 10, 25), lambda = lam)
#' @param ... Ignored.
#' @export
attenuate_spectrum <- function(E0_lambda, ...) UseMethod("attenuate_spectrum")

#' @rdname attenuate_spectrum
#' @export
attenuate_spectrum.numeric <- function(E0_lambda, Kd_lambda, depths,
                                        format = c("long", "matrix"),
                                        lambda = NULL, ...) {
  operation <- "attenuate_spectrum.numeric"
  format <- match.arg(format)
  .validate_propagation_numeric(
    E0_lambda, "E0_lambda", operation, nonnegative = TRUE
  )
  .validate_propagation_numeric(
    Kd_lambda, "Kd_lambda", operation, nonnegative = TRUE
  )
  .validate_propagation_numeric(
    depths, "depths", operation, nonnegative = TRUE
  )
  if (length(E0_lambda) != length(Kd_lambda)) {
    .stop_lux_spectrum_validation(
      paste0("`E0_lambda` and `Kd_lambda` must have equal length; got ",
             length(E0_lambda), " and ", length(Kd_lambda), "."),
      field = c("E0_lambda", "Kd_lambda"),
      value = c(length(E0_lambda), length(Kd_lambda)),
      subclass = "lux_spectrum_value_error",
      context = list(operation = operation)
    )
  }
  if (!is.null(lambda)) {
    .validate_propagation_numeric(lambda, "lambda", operation)
    if (length(lambda) != length(E0_lambda)) {
      .stop_lux_spectrum_validation(
        paste0("`lambda` and `E0_lambda` must have equal length; got ",
               length(lambda), " and ", length(E0_lambda), "."),
        field = c("lambda", "E0_lambda"),
        value = c(length(lambda), length(E0_lambda)),
        subclass = "lux_spectrum_value_error",
        context = list(operation = operation)
      )
    }
  }

  M <- outer(Kd_lambda, depths, FUN = "*")
  E <- E0_lambda * exp(-M)
  .validate_propagation_output(
    E, operation, from = 0, to = depths, Kd_lambda = Kd_lambda
  )

  if (format == "matrix") return(E)
  if (is.null(lambda)) lambda <- seq_along(E0_lambda)

  data.frame(
    depth  = rep(depths, each  = length(E0_lambda)),
    lambda = rep(lambda, times = length(depths)),
    E      = as.vector(E)
  )
}

#' @rdname attenuate_spectrum
#' @export
attenuate_spectrum.lux_spectrum <- function(E0_lambda, Kd_lambda, depths, ...) {
  x   <- E0_lambda
  .validate_propagation_spectrum(
    x, "E0_lambda", "attenuate_spectrum.lux_spectrum",
    from = 0, to = depths, Kd_lambda = Kd_lambda
  )
  mat <- attenuate_spectrum.numeric(x$E, Kd_lambda, depths, format = "matrix")
  out <- vector("list", length(depths))
  names(out) <- as.character(depths)
  for (i in seq_along(depths)) {
    m       <- x$meta
    m$depth <- depths[i]
    m$propagation <- .propagation_model_context(
      "attenuate_spectrum.lux_spectrum", from = 0, to = depths[i],
      Kd_lambda = Kd_lambda
    )
    out[[i]] <- lux_spectrum(mat[, i], x$lambda,
                              x$quantity, x$unit, x$binwidth, m)
  }
  out
}


#' Propagate a known spectrum to any other depth(s) (bidirectional).
#'
#' Applies Beer-Lambert attenuation at each wavelength independently,
#' propagating a known spectral irradiance from depth \code{from} to one or
#' more target depths \code{to}. Works in both directions: set \code{to <
#' from} to recover a shallower (or surface) spectrum from a deeper
#' measurement, assuming a homogeneous water column.
#'
#' @details This is the package's principal lightweight propagation tier. It
#'   applies \eqn{E(z,\lambda) = E(z_0,\lambda)
#'   \exp[-K_d(\lambda)(z-z_0)]}, assuming \eqn{K_d} is constant along the
#'   path and wavelengths propagate independently. It does not model an
#'   angular radiance field, multiple scattering, or spectral redistribution.
#'   There is no universal supported depth range: validity depends on whether
#'   the supplied \eqn{K_d} represents the entire path. Bundled Jerlov data are
#'   limited to 350--700 nm. Inverse propagation is an assumption-heavy
#'   reconstruction that amplifies noise.
#'
#' @param E_lambda  Spectral irradiance at depth \code{from}. Length-N vector
#'   or a \code{lux_spectrum} object.
#' @param Kd_lambda Finite, non-negative diffuse attenuation coefficients
#'   (1/m). Length-N vector.
#' @param from    Finite scalar depth of the known spectrum in metres. Default
#'   0.
#' @param to      Finite target depth(s) in metres. Scalar or vector.
#' @param format  \code{"long"} (default) or \code{"matrix"}. Ignored for
#'   \code{lux_spectrum} input.
#' @param lambda  Optional wavelength values (nm) for long-format output.
#' @param allow_above_surface Logical; permits negative absolute depths.
#'   Default FALSE.
#' @return A data frame, matrix, or named list of \code{lux_spectrum}.
#' @references
#'   Kirk JTO (1994) Light and Photosynthesis in Aquatic Ecosystems,
#'   2nd edn. Cambridge University Press.
#' @examples
#' E_10m <- c(8, 15, 20)
#' Kd    <- c(0.02, 0.06, 0.25)
#' propagate_spectrum(E_10m, Kd, from = 10, to = c(0, 25, 50))
#' @param ... Ignored.
#' @export
propagate_spectrum <- function(E_lambda, ...) UseMethod("propagate_spectrum")

#' @rdname propagate_spectrum
#' @export
propagate_spectrum.numeric <- function(E_lambda, Kd_lambda, from = 0, to,
                                        format = c("long", "matrix"),
                                        lambda = NULL,
                                        allow_above_surface = FALSE, ...) {
  operation <- "propagate_spectrum.numeric"
  format <- match.arg(format)
  .validate_propagation_numeric(
    E_lambda, "E_lambda", operation, nonnegative = TRUE
  )
  .validate_propagation_numeric(
    Kd_lambda, "Kd_lambda", operation, nonnegative = TRUE
  )
  .validate_propagation_numeric(from, "from", operation, scalar = TRUE)
  .validate_propagation_numeric(to, "to", operation)
  .validate_propagation_flag(
    allow_above_surface, "allow_above_surface", operation
  )
  if (length(E_lambda) != length(Kd_lambda)) {
    .stop_lux_spectrum_validation(
      paste0("`E_lambda` and `Kd_lambda` must have equal length; got ",
             length(E_lambda), " and ", length(Kd_lambda), "."),
      field = c("E_lambda", "Kd_lambda"),
      value = c(length(E_lambda), length(Kd_lambda)),
      subclass = "lux_spectrum_value_error",
      context = list(operation = operation)
    )
  }
  if (!allow_above_surface && (from < 0 || any(to < 0))) {
    .stop_lux_spectrum_validation(
      paste0("`from` and `to` must contain only non-negative absolute ",
             "depths unless `allow_above_surface = TRUE`."),
      field = c("from", "to"), value = c(from, to),
      subclass = "lux_spectrum_value_error",
      context = list(operation = operation)
    )
  }
  if (!is.null(lambda)) {
    .validate_propagation_numeric(lambda, "lambda", operation)
    if (length(lambda) != length(E_lambda)) {
      .stop_lux_spectrum_validation(
        paste0("`lambda` and `E_lambda` must have equal length; got ",
               length(lambda), " and ", length(E_lambda), "."),
        field = c("lambda", "E_lambda"),
        value = c(length(lambda), length(E_lambda)),
        subclass = "lux_spectrum_value_error",
        context = list(operation = operation)
      )
    }
  }

  delta <- to - from
  M     <- outer(Kd_lambda, delta, FUN = "*")
  E     <- E_lambda * exp(-M)
  .validate_propagation_output(
    E, operation, from = from, to = to, Kd_lambda = Kd_lambda
  )

  if (format == "matrix") return(E)
  if (is.null(lambda)) lambda <- seq_along(E_lambda)

  data.frame(
    depth  = rep(to,     each  = length(E_lambda)),
    lambda = rep(lambda, times = length(to)),
    E      = as.vector(E)
  )
}

#' @rdname propagate_spectrum
#' @export
propagate_spectrum.lux_spectrum <- function(E_lambda, Kd_lambda, from = 0, to,
                                             allow_above_surface = FALSE, ...) {
  x   <- E_lambda
  .validate_propagation_spectrum(
    x, "E_lambda", "propagate_spectrum.lux_spectrum",
    from = from, to = to, Kd_lambda = Kd_lambda
  )
  mat <- propagate_spectrum.numeric(x$E, Kd_lambda, from = from, to = to,
                                     format = "matrix",
                                     allow_above_surface = allow_above_surface)
  out <- vector("list", length(to))
  names(out) <- as.character(to)
  for (i in seq_along(to)) {
    m       <- x$meta
    m$depth <- to[i]
    m$propagation <- .propagation_model_context(
      "propagate_spectrum.lux_spectrum", from = from, to = to[i],
      Kd_lambda = Kd_lambda
    )
    out[[i]] <- lux_spectrum(mat[, i], x$lambda,
                              x$quantity, x$unit, x$binwidth, m)
  }
  out
}


#' Depth at which a given fraction of surface light remains.
#'
#' Solves exp(-Kd * z) = fraction for z, giving -log(fraction) / Kd.
#' The default 1% threshold is the classic euphotic depth.
#'
#' @param Kd       Diffuse attenuation coefficient(s) in 1/m.
#' @param fraction Fraction of surface irradiance. Must be in (0, 1).
#'   Default 0.01 (1\%).
#' @return Depth(s) in metres at which \code{fraction} of surface light remains.
#' @examples
#' photic_depth(0.06)
#' photic_depth(0.06, fraction = 0.1)
#' @export
photic_depth <- function(Kd, fraction = 0.01) {
  stopifnot(all(fraction > 0 & fraction < 1))
  -log(fraction) / Kd
}


#' Estimate the diffuse attenuation coefficient from two irradiance readings.
#'
#' Closed-form Beer-Lambert inversion: Kd = log(E1/E2) / (z2 - z1).
#' Works for scalar or spectral (vector) inputs, or \code{lux_spectrum} objects.
#'
#' @param E1 Irradiance at the shallower depth \code{z1}. Numeric vector or
#'   \code{lux_spectrum}. When \code{E1} is a \code{lux_spectrum}, S3 dispatch
#'   handles both arguments; passing a numeric \code{E1} with a
#'   \code{lux_spectrum} \code{E2} is not supported.
#' @param z1 Depth of E1 in metres. Must be < z2.
#' @param E2 Irradiance at the deeper depth \code{z2}. Numeric vector or
#'   \code{lux_spectrum} (only when \code{E1} is also a \code{lux_spectrum}).
#' @param z2 Depth of E2 in metres. Must be > z1.
#' @return Kd in 1/m. Same length as E1/E2.
#' @references
#'   Kirk JTO (1994) Light and Photosynthesis in Aquatic Ecosystems,
#'   2nd edn. Cambridge University Press.
#' @seealso \code{\link{propagate_spectrum}}, \code{\link{attenuate_spectrum}},
#'   \code{\link{jerlov_Kd}}
#' @examples
#' data(Naples)
#' fit_Kd(sum(Naples$depth_0m), 0, sum(Naples$depth_10m), 10)
#' @param ... Ignored.
#' @export
fit_Kd <- function(E1, ...) UseMethod("fit_Kd")

#' @rdname fit_Kd
#' @export
fit_Kd.numeric <- function(E1, z1, E2, z2, ...) {
  if (inherits(E2, "lux_spectrum"))
    stop("When E1 is numeric, E2 must also be numeric. ",
         "Pass a lux_spectrum as E1 to use the lux_spectrum method.")
  stopifnot(all(z2 > z1), all(E1 > 0), all(E2 > 0))
  log(E1 / E2) / (z2 - z1)
}

#' @rdname fit_Kd
#' @export
fit_Kd.lux_spectrum <- function(E1, z1, E2, z2, ...) {
  e1 <- if (inherits(E1, "lux_spectrum")) E1$E else E1
  e2 <- if (inherits(E2, "lux_spectrum")) E2$E else E2
  fit_Kd.numeric(e1, z1, e2, z2)
}


#' In-water downwelling spectral irradiance at a single depth.
#'
#' Convenience wrapper that takes one of the bundled reference solar spectra,
#' converts it to \eqn{W\,m^{-2}\,nm^{-1}}, and propagates it from its recorded reference depth
#' to a single absolute depth in a Jerlov water type via
#' \code{\link{jerlov_Kd}} and \code{\link{propagate_spectrum}}.
#' This is the "solar condition + water type + depth -> spectrum at depth"
#' operation the Shiny app's colour-discrimination and detection tabs share.
#'
#' @param condition  Solar condition passed to \code{\link{from_solar}}
#'   (e.g. \code{"clear_noon"}). Default \code{"clear_noon"}.
#' @param water_type Jerlov water type passed to \code{\link{jerlov_Kd}}
#'   (e.g. \code{"IA"}). Default \code{"IA"}.
#' @param depth      Absolute target depth in metres below the water surface.
#'   Must be length-1, non-negative, and not shallower than an in-water source's
#'   recorded reference depth. Default 0 (surface).
#' @param surface_source Surface illumination model used when \code{condition}
#'   is referenced in air: \code{"direct"} (default) or \code{"diffuse"}.
#' @param surface_angle Incidence angle in degrees from the surface normal for
#'   \code{surface_source = "direct"}. Default 30, matching the worked vignette.
#' @param refractive_index Refractive index of water relative to air used by the
#'   Fresnel surface model. Default 1.333.
#' @param wavelength_policy Policy for source wavelengths outside the bundled
#'   Jerlov domain (350--700 nm): \code{"error"} (default) fails,
#'   \code{"trim"} explicitly restricts the calculation to the supported
#'   intersection, and \code{"constant"} explicitly extends endpoint Kd values.
#' @return A data frame with columns \code{lambda} (nm) and \code{irradiance}
#'   (downwelling spectral irradiance at \code{depth}, in \eqn{W\,m^{-2}\,nm^{-1}}). The
#'   \code{"luxR.jerlov"} attribute records the wavelength policy and data
#'   provenance.
#' @details An above-surface source is multiplied by
#'   \code{\link{surface_transmittance}} before water-column attenuation. The
#'   default is a flat interface and direct illumination incident 30 degrees
#'   from vertical. An in-water source is unchanged when \code{depth} equals its
#'   reference depth. For deeper targets, only the additional water-column
#'   distance is applied. Shallower targets are rejected because reconstructing
#'   them would require an explicit inverse-propagation model.
#'   Water-column propagation is the lightweight spectral Beer-Lambert model:
#'   it assumes a depth-invariant Jerlov \eqn{K_d(\lambda)}, propagates
#'   wavelength bins independently, and is not a multiple-scattering or
#'   angular radiative-transfer calculation. No universal maximum depth is
#'   implied; the selected water type must remain representative of the whole
#'   path.
#' @seealso \code{\link{from_solar}}, \code{\link{jerlov_Kd}},
#'   \code{\link{propagate_spectrum}}
#' @examples
#' head(light_at_depth("clear_noon", "IA", depth = 5,
#'                     wavelength_policy = "trim"))
#' @export
light_at_depth <- function(condition = "clear_noon", water_type = "IA",
                           depth = 0,
                           surface_source = c("direct", "diffuse"),
                           surface_angle = 30,
                           refractive_index = 1.333,
                           wavelength_policy = c("error", "trim", "constant")) {
  surface_source <- match.arg(surface_source)
  wavelength_policy <- match.arg(wavelength_policy)
  .validate_propagation_numeric(
    depth, "depth", "light_at_depth", nonnegative = TRUE, scalar = TRUE
  )
  sp_w <- convert_unit(from_solar(condition), "W/m2/nm")
  reference_depth_m <- sp_w$meta$reference_depth_m
  reference_medium <- sp_w$meta$reference_medium
  .validate_source_target_depths(
    reference_depth_m = reference_depth_m,
    reference_medium = reference_medium,
    target_depth_m = depth,
    source_condition = condition,
    water_type = water_type,
    operation = "light_at_depth"
  )
  E_water <- .source_irradiance_in_water(
    sp_w$E,
    reference_medium = reference_medium,
    surface_source = surface_source,
    surface_angle = surface_angle,
    refractive_index = refractive_index,
    operation = "light_at_depth"
  )
  domain <- .prepare_jerlov_domain(
    sp_w$lambda, E_water, wavelength_policy = wavelength_policy,
    type = water_type, operation = "light_at_depth"
  )
  M <- propagate_spectrum(
    domain$values, domain$Kd, from = reference_depth_m, to = depth,
    lambda = domain$lambda, format = "matrix"
  )
  out <- data.frame(
    lambda = domain$lambda,
    irradiance = as.numeric(M[, 1])
  )
  attr(out, "luxR.jerlov") <- domain$metadata
  attr(out, "luxR.propagation") <- .propagation_model_context(
    "light_at_depth", from = reference_depth_m, to = depth,
    Kd_lambda = domain$Kd
  )
  out
}
