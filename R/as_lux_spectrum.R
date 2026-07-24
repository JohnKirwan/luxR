# as_lux_spectrum — coercer generic and methods

#' Coerce an object to lux_spectrum
#'
#' Converts a numeric vector or data frame to a \code{\link{lux_spectrum}}
#' object. The data-frame method auto-detects the wavelength column
#' (\code{lambda} > \code{wavelength} > \code{wv}) and the spectral-value
#' column (\code{E} > \code{irradiance} > \code{radiance} > \code{value}).
#' Passing an existing \code{lux_spectrum} returns it unchanged.
#'
#' @param x Object to coerce.
#' @param ... Additional arguments passed to methods.
#' @return A \code{lux_spectrum} object.
#' @seealso \code{\link{lux_spectrum}}, \code{\link{from_naples}},
#'   \code{\link{from_solar}}
#' @examples
#' # from a numeric vector
#' lam <- seq(400, 700, by = 10)
#' as_lux_spectrum(rep(1, length(lam)), lambda = lam)
#'
#' # from a data frame
#' df <- data.frame(lambda = lam, E = rep(1, length(lam)))
#' as_lux_spectrum(df)
#' @export
as_lux_spectrum <- function(x, ...) UseMethod("as_lux_spectrum")

#' @param lambda    Wavelength vector in nm (required for numeric method).
#' @param quantity  Physical quantity string. Default \code{"irradiance"}.
#' @param unit      Unit string from the controlled vocabulary. Default \code{"W/m2/nm"}.
#' @param binwidth  Bin width in nm; inferred if \code{NULL}.
#' @param meta      Named list of metadata.
#' @rdname as_lux_spectrum
#' @export
as_lux_spectrum.numeric <- function(x, lambda,
                                    quantity = "irradiance",
                                    unit     = "W/m2/nm",
                                    binwidth = NULL,
                                    meta     = list(), ...) {
  lux_spectrum(x, lambda, quantity, unit, binwidth, meta)
}

#' @param lambda_col Column name for wavelengths. Auto-detected from
#'   \code{lambda} > \code{wavelength} > \code{wv} if \code{NULL}.
#' @param E_col     Column name for spectral values. Auto-detected from
#'   \code{E} > \code{irradiance} > \code{radiance} > \code{value} if \code{NULL}.
#' @rdname as_lux_spectrum
#' @export
as_lux_spectrum.data.frame <- function(x,
                                       lambda_col = NULL,
                                       E_col      = NULL,
                                       quantity   = "irradiance",
                                       unit       = "W/m2/nm",
                                       binwidth   = NULL,
                                       meta       = list(), ...) {
  if (is.null(lambda_col)) {
    lambda_col <- intersect(c("lambda", "wavelength", "wv"), names(x))[1]
    if (is.na(lambda_col))
      stop("Cannot find lambda column. Specify lambda_col explicitly.")
  }
  if (is.null(E_col)) {
    E_col <- intersect(c("E", "irradiance", "radiance", "value"), names(x))[1]
    if (is.na(E_col))
      stop("Cannot find E column. Specify E_col explicitly.")
  }
  lux_spectrum(x[[E_col]], x[[lambda_col]], quantity, unit, binwidth, meta)
}

#' @rdname as_lux_spectrum
#' @export
as_lux_spectrum.lux_spectrum <- function(x, ...) x

#' @param calibration For an instrument spectrum, a non-empty calibration
#'   identifier or description.
#' @param negative_policy For an instrument spectrum, either error on negative
#'   processed values or explicitly replace them with zero and record the
#'   affected indices.
#' @rdname as_lux_spectrum
#' @export
as_lux_spectrum.lux_instrument_spectrum <- function(
    x, quantity = NULL, unit = NULL, calibration = NULL,
    negative_policy = "error", ...) {
  context <- x$meta$import
  if (!is.list(context)) {
    context <- .spectrum_import_context(
      x$meta$source, "lightr-dispatched", "as_lux_spectrum",
      configuration = list()
    )
  }
  context$conversion_operation <- "as_lux_spectrum"
  negative_policy <- .validate_lightr_choice(
    negative_policy, "negative_policy", c("error", "zero"), context
  )
  calibration <- .validate_import_string(calibration, "calibration", context)
  supported <- c("reflectance", "irradiance", "radiance")
  if (!x$measurement %in% supported) {
    .stop_spectrum_import(
      paste0("A ", x$measurement, " instrument record cannot be represented ",
             "as a lux_spectrum; supported measurements are: ",
             paste(supported, collapse = ", "), "."),
      context, class = "luxR_spectrum_dimension_error", field = "measurement",
      value = x$measurement
    )
  }
  quantity <- .validate_import_string(
    quantity, "quantity", context, class = "luxR_spectrum_schema_error"
  )
  unit <- .validate_import_string(
    unit, "unit", context, class = "luxR_spectrum_schema_error"
  )
  if (!identical(quantity, x$measurement)) {
    .stop_spectrum_import(
      paste0("The declared instrument measurement is ", x$measurement,
             ", not ", quantity, "."),
      context, class = "luxR_spectrum_dimension_error", field = "quantity",
      value = quantity
    )
  }

  scale_factor <- switch(
    x$value_scale,
    percent = 0.01,
    fraction = 1,
    absolute = 1,
    .stop_spectrum_import(
      paste0("Value scale '", x$value_scale,
             "' cannot be converted to a physical lux_spectrum."),
      context, class = "luxR_spectrum_dimension_error", field = "value_scale",
      value = x$value_scale
    )
  )
  values <- x$value * scale_factor
  negative <- which(values < 0)
  if (length(negative) && identical(negative_policy, "error")) {
    i <- negative[[1L]]
    .stop_spectrum_import(
      paste0("Processed ", x$measurement, " contains a negative value at row ",
             i, "; inspect the instrument record or explicitly set ",
             "`negative_policy = \"zero\"`."),
      context, class = "luxR_spectrum_value_error", field = "value",
      value = values[[i]], row = i
    )
  }
  if (length(negative)) values[negative] <- 0

  preprocessing <- x$meta$preprocessing
  preprocessing$value_scale <- list(
    input = x$value_scale, output = if (x$measurement == "reflectance") {
      "fraction"
    } else {
      "absolute"
    }, factor = scale_factor
  )
  preprocessing$negative_values <- list(
    policy = negative_policy, affected_count = length(negative),
    affected_indices = negative
  )
  context$configuration$quantity <- quantity
  context$configuration$unit <- unit
  context$configuration$calibration <- calibration
  context$configuration$negative_policy <- negative_policy

  .construct_imported_lux_spectrum(
    E = values, lambda = x$lambda, quantity = quantity, unit = unit,
    meta = list(
      source = x$meta$source,
      calibration_state = "declared calibrated",
      calibration = calibration,
      instrument = x$meta$instrument,
      import = context,
      import_notices = x$meta$import_notices,
      preprocessing = preprocessing
    ),
    context = context
  )
}

#' @param column For the \code{rspec} method (\pkg{pavo}), which spectrum column
#'   to convert: a column name or index. Default the first spectrum (column 2,
#'   after \code{wl}).
#' @rdname as_lux_spectrum
#' @export
as_lux_spectrum.rspec <- function(x, column = 2,
                                  quantity = "irradiance",
                                  unit     = "W/m2/nm",
                                  meta     = list(), ...) {
  if (is.null(x[["wl"]]))
    stop("Not a valid rspec: no 'wl' wavelength column.")
  vals <- x[[column]]
  if (is.null(vals))
    stop("Column not found in rspec: ", column)
  if (is.null(meta$source))
    meta$source <- if (is.character(column)) column else names(x)[column]
  lux_spectrum(E = vals, lambda = x[["wl"]],
               quantity = quantity, unit = unit, meta = meta)
}

# Shared strictness checks for importing any photobiology spectrum. Mirrors the
# lightr path: nothing ambiguous is guessed at, and every applied policy is
# recorded in the returned metadata.
.photobiology_import_context <- function(class_name, configuration) {
  context <- .spectrum_import_context(
    NA_character_, paste0("photobiology::", class_name), "as_lux_spectrum",
    configuration = configuration
  )
  context
}

.check_photobiology_single_wl <- function(x, class_name, context) {
  multiple <- photobiology::getMultipleWl(x)
  if (!identical(as.integer(multiple), 1L)) {
    .stop_spectrum_import(
      paste0("A ", class_name, " holding ", multiple, " spectra cannot become ",
             "a single lux_spectrum; subset it to one spectrum first."),
      context, class = "luxR_spectrum_schema_error", field = "multiple.wl",
      value = multiple
    )
  }
  invisible(NULL)
}

# Applies the negative-value and grid-regularity policies, then constructs.
# The irregular-grid branch resamples the raw lambda/E vectors onto an
# integer-nanometre grid with stats::approx() BEFORE any lux_spectrum() call,
# because the constructor rejects irregular grids outright: there is no
# regular-grid object to build and then resample.
.finish_photobiology_import <- function(E, lambda, quantity, unit, meta,
                                        negative_policy, interpolate,
                                        context) {
  negative <- which(E < 0)
  if (length(negative) && identical(negative_policy, "error")) {
    .stop_spectrum_import(
      paste0("The imported spectrum holds a negative value at wavelength ",
             lambda[negative[1]], " nm (", E[negative[1]], "). Retain it as a ",
             "photobiology object, or request the recorded floor with ",
             "`negative_policy = \"zero\"`."),
      context, class = "luxR_spectrum_value_error", field = "value",
      value = E[negative[1]]
    )
  }
  if (length(negative)) E[negative] <- 0
  steps <- diff(lambda)
  irregular <- length(steps) > 1 &&
    !isTRUE(all.equal(steps, rep(steps[1], length(steps))))
  if (irregular && !isTRUE(interpolate)) {
    .stop_spectrum_import(
      paste0("The imported wavelength grid is irregular (steps ",
             min(steps), "-", max(steps), " nm). luxR will not resample it ",
             "silently; pass `interpolate = TRUE` to resample onto integer ",
             "nanometres, and the choice will be recorded."),
      context, class = "luxR_spectrum_grid_error", field = "w.length",
      value = c(min(steps), max(steps))
    )
  }
  meta$import <- context
  if (irregular) {
    grid_lo <- ceiling(min(lambda))
    grid_hi <- floor(max(lambda))
    if (grid_hi - grid_lo < 1) {
      .stop_spectrum_import(
        paste0("The imported wavelength range ", min(lambda), "-", max(lambda),
               " nm spans less than one integer nanometre, so it cannot be ",
               "resampled onto an integer-nanometre grid of at least two ",
               "points. Retain it as a photobiology object instead."),
        context, class = "luxR_spectrum_grid_error", field = "w.length",
        value = c(min(lambda), max(lambda))
      )
    }
    grid <- seq(grid_lo, grid_hi, by = 1)
    E <- stats::approx(lambda, E, xout = grid, rule = 1)$y
    lambda <- grid
  }
  lux_spectrum(E, lambda, quantity, unit, meta = meta)
}

#' @param measurement For a photobiology \code{source_spct} carrying both an
#'   energy and a photon column, which to import: \code{"energy"} or
#'   \code{"photon"}. Required only when the choice is ambiguous.
#' @param interpolate For a photobiology spectrum, whether an irregular
#'   wavelength grid may be resampled onto integer nanometres. Defaults to
#'   \code{FALSE}, so irregular grids fail with guidance to opt in.
#' @rdname as_lux_spectrum
#' @export
as_lux_spectrum.source_spct <- function(x, measurement = NULL,
                                        negative_policy = "error",
                                        interpolate = FALSE, ...) {
  .need_photobiology()
  context <- .photobiology_import_context(
    "source_spct",
    list(measurement = measurement, negative_policy = negative_policy,
         interpolate = interpolate)
  )
  negative_policy <- .validate_lightr_choice(
    negative_policy, "negative_policy", c("error", "zero"), context
  )
  time_unit <- photobiology::getTimeUnit(x)
  if (!identical(time_unit, "second")) {
    .stop_spectrum_import(
      paste0("A source_spct with time.unit '", time_unit, "' is a dose, not a ",
             "spectral irradiance, and has no lux_spectrum representation. ",
             "Convert it to a per-second basis in photobiology first."),
      context, class = "luxR_spectrum_dimension_error", field = "time.unit",
      value = time_unit
    )
  }
  bswf <- photobiology::getBSWFUsed(x)
  if (!identical(bswf, "none")) {
    .stop_spectrum_import(
      paste0("A source_spct weighted by bswf.used '", bswf, "' is an ",
             "effective, not a physical, irradiance and cannot become a ",
             "lux_spectrum."),
      context, class = "luxR_spectrum_dimension_error", field = "bswf.used",
      value = bswf
    )
  }
  .check_photobiology_single_wl(x, "source_spct", context)
  has_e <- "s.e.irrad" %in% names(x)
  has_q <- "s.q.irrad" %in% names(x)
  if (!has_e && !has_q) {
    .stop_spectrum_import(
      "The source_spct holds neither an s.e.irrad nor an s.q.irrad column.",
      context, class = "luxR_spectrum_schema_error", field = "columns",
      value = paste(names(x), collapse = ", ")
    )
  }
  if (has_e && has_q && is.null(measurement)) {
    .stop_spectrum_import(
      paste0("The source_spct holds both s.e.irrad and s.q.irrad; luxR will ",
             "not choose a basis for you. Pass `measurement = \"energy\"` or ",
             "`measurement = \"photon\"`."),
      context, class = "luxR_spectrum_schema_error", field = "measurement",
      value = NA_character_
    )
  }
  if (is.null(measurement)) measurement <- if (has_e) "energy" else "photon"
  measurement <- .validate_lightr_choice(
    measurement, "measurement", c("energy", "photon"), context
  )
  if (identical(measurement, "energy") && !has_e) {
    .stop_spectrum_import(
      paste0("`measurement = \"energy\"` was requested but the source_spct ",
             "has no s.e.irrad column."),
      context, class = "luxR_spectrum_schema_error", field = "s.e.irrad",
      value = NA_character_
    )
  }
  if (identical(measurement, "photon") && !has_q) {
    .stop_spectrum_import(
      paste0("`measurement = \"photon\"` was requested but the source_spct ",
             "has no s.q.irrad column."),
      context, class = "luxR_spectrum_schema_error", field = "s.q.irrad",
      value = NA_character_
    )
  }
  unit <- if (identical(measurement, "energy")) "W/m2/nm" else "mol/m2/s/nm"
  values <- if (identical(measurement, "energy")) x$s.e.irrad else x$s.q.irrad
  context$configuration$measurement <- measurement
  context$configuration$negative_policy <- negative_policy
  meta <- list(
    source = "photobiology::source_spct",
    photobiology_version = as.character(utils::packageVersion("photobiology")),
    photobiology_comment = comment(x),
    what_measured = photobiology::getWhatMeasured(x)
  )
  meta <- meta[!vapply(meta, is.null, logical(1))]
  .finish_photobiology_import(
    as.numeric(values), as.numeric(x$w.length), "irradiance", unit, meta,
    negative_policy, interpolate, context
  )
}

#' @rdname as_lux_spectrum
#' @export
as_lux_spectrum.reflector_spct <- function(x, negative_policy = "error",
                                           interpolate = FALSE, ...) {
  .need_photobiology()
  context <- .photobiology_import_context(
    "reflector_spct",
    list(negative_policy = negative_policy, interpolate = interpolate)
  )
  negative_policy <- .validate_lightr_choice(
    negative_policy, "negative_policy", c("error", "zero"), context
  )
  .check_photobiology_single_wl(x, "reflector_spct", context)
  if ("Rfr" %in% names(x)) {
    values <- as.numeric(x$Rfr)
  } else if ("Rpc" %in% names(x)) {
    values <- as.numeric(x$Rpc) / 100
  } else {
    .stop_spectrum_import(
      "The reflector_spct holds neither an Rfr nor an Rpc column.",
      context, class = "luxR_spectrum_schema_error", field = "columns",
      value = paste(names(x), collapse = ", ")
    )
  }
  meta <- list(
    source = "photobiology::reflector_spct",
    photobiology_version = as.character(utils::packageVersion("photobiology")),
    Rfr_type = photobiology::getRfrType(x),
    photobiology_comment = comment(x)
  )
  meta <- meta[!vapply(meta, is.null, logical(1))]
  .finish_photobiology_import(
    values, as.numeric(x$w.length), "reflectance", "dimensionless", meta,
    negative_policy, interpolate, context
  )
}
