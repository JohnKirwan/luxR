# Strict instrument-spectrum records parsed by lightr.

.lightr_measurements <- c(
  "reflectance", "irradiance", "radiance", "transmittance", "absorbance",
  "raw"
)

.lightr_value_scales <- c("fraction", "percent", "absolute", "raw")

.lightr_extension_measurements <- list(
  rfl8 = "reflectance", ref = "reflectance", roh = "reflectance",
  irr8 = "irradiance", irr = "irradiance", jazirrad = "irradiance",
  trm = "transmittance", trt = "transmittance",
  abs = "absorbance", raw8 = "raw"
)

.validate_lightr_choice <- function(x, field, choices, context) {
  value <- .validate_import_string(x, field, context,
                                   class = "luxR_spectrum_schema_error")
  if (!value %in% choices) {
    .stop_spectrum_import(
      paste0("`", field, "` must be one of: ", paste(choices, collapse = ", "),
             "; got '", value, "'."),
      context, class = "luxR_spectrum_schema_error", field = field,
      value = value
    )
  }
  value
}

.validate_lightr_parser_args <- function(parser_args, context) {
  if (!is.list(parser_args) || is.object(parser_args)) {
    .stop_spectrum_import(
      "`parser_args` must be a plain named list.", context,
      class = "luxR_spectrum_schema_error", field = "parser_args",
      value = parser_args
    )
  }
  if (!length(parser_args)) return(parser_args)
  if (is.null(names(parser_args)) || anyNA(names(parser_args)) ||
        any(!nzchar(names(parser_args))) || anyDuplicated(names(parser_args))) {
    .stop_spectrum_import(
      "`parser_args` must have unique, non-empty names.", context,
      class = "luxR_spectrum_schema_error", field = "parser_args",
      value = parser_args
    )
  }
  controlled <- c("where", "ext", "lim", "subdir", "subdir.names",
                  "ignore.case", "interpolate")
  conflict <- intersect(names(parser_args), controlled)
  if (length(conflict)) {
    .stop_spectrum_import(
      paste0("`parser_args` cannot override luxR-controlled argument(s): ",
             paste(conflict, collapse = ", "), "."),
      context, class = "luxR_spectrum_schema_error", field = "parser_args",
      value = conflict
    )
  }
  simple <- vapply(parser_args, function(value) {
    (is.atomic(value) || is.null(value)) && !is.object(value) &&
      is.null(dim(value)) && length(value) <= 1L && !anyNA(value)
  }, logical(1L))
  if (!all(simple)) {
    .stop_spectrum_import(
      paste0("Every `parser_args` value must be NULL or one non-missing plain ",
             "atomic scalar; invalid: ",
             paste(names(parser_args)[!simple], collapse = ", "), "."),
      context, class = "luxR_spectrum_schema_error", field = "parser_args",
      value = parser_args[!simple]
    )
  }
  parser_args
}

.validate_lightr_range <- function(range, context) {
  valid <- is.numeric(range) && !is.complex(range) && !is.object(range) &&
    is.null(dim(range)) && length(range) == 2L && all(is.finite(range)) &&
    range[[1L]] < range[[2L]]
  if (!valid) {
    .stop_spectrum_import(
      paste0("`range` must explicitly declare two finite increasing ",
             "wavelengths in nm."),
      context, class = "luxR_spectrum_schema_error", field = "range",
      value = range
    )
  }
  range
}

.capture_lightr_call <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(
    suppressMessages(expr),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = unique(warnings))
}

.stop_on_lightr_warnings <- function(warnings, warning_policy, context,
                                     stage) {
  if (length(warnings) && identical(warning_policy, "error")) {
    .stop_spectrum_import(
      paste0("lightr reported a ", stage, " warning: ",
             paste(warnings, collapse = " | ")),
      context, class = "luxR_spectrum_format_error", field = stage,
      value = warnings
    )
  }
}

#' Parse one instrument spectrum with lightr
#'
#' Uses \pkg{lightr} for file-format dispatch while retaining a strict,
#' single-spectrum record that can represent irregular wavelength grids and
#' signed processed values. This function does not claim that processed values
#' are a physically valid \code{\link{lux_spectrum}}; use
#' \code{\link{as_lux_spectrum}} or \code{\link{read_spectrum}} for that step.
#'
#' @param path Path to one spectral file.
#' @param measurement Declared measurement represented by the processed values:
#'   one of \code{"reflectance"}, \code{"irradiance"}, \code{"radiance"},
#'   \code{"transmittance"}, \code{"absorbance"}, or \code{"raw"}.
#' @param value_scale Declared scale of the processed values: \code{"fraction"},
#'   \code{"percent"}, \code{"absolute"}, or \code{"raw"}.
#' @param range Two finite increasing wavelength limits in nm.
#' @param interpolate Whether lightr should interpolate to integer nanometres.
#'   The default preserves native sampling in the instrument record.
#' @param parser_args Named list of simple scalar arguments passed to lightr's
#'   individual parser. Arguments controlling file discovery, wavelength range,
#'   or interpolation cannot be overridden.
#' @param warning_policy Whether parser and metadata warnings should cause an
#'   error (the default) or be explicitly retained in the import record.
#' @return A \code{lux_instrument_spectrum} containing wavelengths, processed
#'   values, declarations, instrument metadata, notices, and reproducibility
#'   context.
#' @seealso \code{\link{read_spectrum}}, \code{\link{as_lux_spectrum}}
#' @export
read_instrument_spectrum <- function(
    path, measurement = NULL, value_scale = NULL, range = NULL,
    interpolate = FALSE, parser_args = list(),
    warning_policy = "error") {
  context <- .validate_import_path(
    path, format = "lightr-dispatched", operation = "read_instrument_spectrum",
    configuration = list(
      measurement = measurement, value_scale = value_scale, range = range,
      interpolate = interpolate, parser_args = parser_args,
      warning_policy = warning_policy
    )
  )
  warning_policy <- .validate_lightr_choice(
    warning_policy, "warning_policy", c("error", "record"), context
  )
  if (!requireNamespace("lightr", quietly = TRUE)) {
    .stop_spectrum_import(
      paste0("read_instrument_spectrum() requires the 'lightr' package. ",
             "Install it with install.packages(\"lightr\")."),
      context, class = "luxR_spectrum_format_error", field = "dependency",
      value = "lightr"
    )
  }
  lightr_version <- as.character(utils::packageVersion("lightr"))
  if (utils::compareVersion(lightr_version, "2.0.0") < 0L) {
    .stop_spectrum_import(
      paste0("lightr >= 2.0.0 is required; installed version is ",
             lightr_version, "."),
      context, class = "luxR_spectrum_format_error", field = "dependency",
      value = lightr_version
    )
  }
  measurement <- .validate_lightr_choice(
    measurement, "measurement", .lightr_measurements, context
  )
  value_scale <- .validate_lightr_choice(
    value_scale, "value_scale", .lightr_value_scales, context
  )
  range <- .validate_lightr_range(range, context)
  if (!is.logical(interpolate) || length(interpolate) != 1L ||
        is.na(interpolate)) {
    .stop_spectrum_import(
      "`interpolate` must be one non-missing logical value.", context,
      class = "luxR_spectrum_schema_error", field = "interpolate",
      value = interpolate
    )
  }
  parser_args <- .validate_lightr_parser_args(parser_args, context)
  extension <- tolower(tools::file_ext(path))
  if (!nzchar(extension)) {
    .stop_spectrum_import(
      paste0("Cannot determine the file format: '", basename(path),
             "' has no extension."),
      context, class = "luxR_spectrum_format_error", field = "extension",
      value = extension
    )
  }
  expected <- .lightr_extension_measurements[[extension]]
  if (!is.null(expected) && !identical(measurement, expected)) {
    .stop_spectrum_import(
      paste0("Extension .", extension, " identifies a ", expected,
             " measurement, not ", measurement, "."),
      context, class = "luxR_spectrum_dimension_error", field = "measurement",
      value = measurement
    )
  }
  compatible_scale <- switch(
    measurement,
    reflectance = value_scale %in% c("fraction", "percent"),
    transmittance = value_scale %in% c("fraction", "percent"),
    absorbance = value_scale == "absolute",
    irradiance = value_scale == "absolute",
    radiance = value_scale == "absolute",
    raw = value_scale == "raw"
  )
  if (!compatible_scale) {
    .stop_spectrum_import(
      paste0("`value_scale = \"", value_scale, "\"` is incompatible with ",
             "`measurement = \"", measurement, "\"`."),
      context, class = "luxR_spectrum_dimension_error", field = "value_scale",
      value = value_scale
    )
  }

  context$configuration <- list(
    measurement = measurement, value_scale = value_scale, range = range,
    interpolate = interpolate, parser_args = parser_args,
    warning_policy = warning_policy, extension = extension,
    lightr_version = lightr_version,
    parser_interface = "lightr::lr_get_spec/lr_get_metadata"
  )
  staging <- tempfile("luxr_lightr_")
  if (!dir.create(staging)) {
    .stop_spectrum_import(
      "Could not create a temporary staging directory for lightr.", context,
      class = "luxR_spectrum_format_error", field = "staging",
      value = staging
    )
  }
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  staged_file <- file.path(staging, basename(path))
  if (!file.copy(path, staged_file)) {
    .stop_spectrum_import(
      paste0("Could not stage the file for import: ", path), context,
      class = "luxR_spectrum_format_error", field = "path", value = path
    )
  }

  spec_call <- c(
    list(where = staging, ext = extension, lim = range,
         interpolate = interpolate),
    parser_args
  )
  parsed <- tryCatch(
    .capture_lightr_call(do.call(lightr::lr_get_spec, spec_call)),
    error = function(e) {
      .stop_spectrum_import(
        paste0("lightr spectrum parsing failed: ", conditionMessage(e)),
        context, class = "luxR_spectrum_format_error", field = "parser",
        value = conditionMessage(e)
      )
    }
  )
  .stop_on_lightr_warnings(parsed$warnings, warning_policy, context, "parser")
  spectrum <- parsed$value
  if (is.null(spectrum) || !is.data.frame(spectrum) || ncol(spectrum) < 2L) {
    detail <- if (length(parsed$warnings)) {
      paste0(" Parser diagnostics: ", paste(parsed$warnings, collapse = " | "))
    } else {
      ""
    }
    .stop_spectrum_import(
      paste0("lightr could not read a spectrum from: ", path, ".", detail),
      context, class = "luxR_spectrum_format_error", field = "file",
      value = path
    )
  }
  if (ncol(spectrum) != 2L) {
    .stop_spectrum_import(
      paste0("Expected exactly one spectrum in '", basename(path),
             "'; lightr returned ", ncol(spectrum) - 1L, "."),
      context, class = "luxR_spectrum_schema_error", field = "spectra",
      value = names(spectrum)[-1L]
    )
  }
  if (!identical(names(spectrum)[[1L]], "wl")) {
    .stop_spectrum_import(
      "lightr result is missing its required `wl` wavelength column.", context,
      class = "luxR_spectrum_schema_error", field = "wl",
      value = names(spectrum)
    )
  }
  lambda <- spectrum[["wl"]]
  value <- spectrum[[2L]]
  if (!is.numeric(lambda) || !is.numeric(value) || is.complex(lambda) ||
        is.complex(value) || is.object(lambda) || is.object(value)) {
    .stop_spectrum_import(
      "lightr returned nonnumeric wavelength or spectral values.", context,
      class = "luxR_spectrum_schema_error", field = "spectrum",
      value = vapply(spectrum, class, character(1L))
    )
  }
  if (!length(lambda)) {
    .stop_spectrum_import(
      "lightr returned no values in the requested wavelength range.", context,
      class = "luxR_spectrum_schema_error", field = "range", value = range
    )
  }
  invalid <- which(!is.finite(lambda) | !is.finite(value))
  if (length(invalid)) {
    i <- invalid[[1L]]
    field <- if (!is.finite(lambda[[i]])) "wavelength" else "value"
    bad_value <- if (field == "wavelength") lambda[[i]] else value[[i]]
    .stop_spectrum_import(
      paste0("lightr returned a non-finite ", field, " at row ", i, "."),
      context, class = "luxR_spectrum_value_error", field = field,
      value = bad_value, row = i
    )
  }
  .validate_import_grid(lambda, context)

  metadata_call <- c(list(where = staging, ext = extension), parser_args)
  parsed_metadata <- tryCatch(
    .capture_lightr_call(
      do.call(lightr::lr_get_metadata, metadata_call)
    ),
    error = function(e) {
      .stop_spectrum_import(
        paste0("lightr metadata parsing failed: ", conditionMessage(e)),
        context, class = "luxR_spectrum_format_error", field = "metadata",
        value = conditionMessage(e)
      )
    }
  )
  .stop_on_lightr_warnings(
    parsed_metadata$warnings, warning_policy, context, "metadata"
  )
  instrument_metadata <- parsed_metadata$value
  if (is.null(instrument_metadata) || !is.data.frame(instrument_metadata) ||
        nrow(instrument_metadata) == 0L) {
    instrument_metadata <- list()
  } else {
    if (nrow(instrument_metadata) != 1L) {
      .stop_spectrum_import(
        paste0("Expected metadata for exactly one spectrum; lightr returned ",
               nrow(instrument_metadata), " rows."),
        context, class = "luxR_spectrum_schema_error", field = "metadata",
        value = nrow(instrument_metadata)
      )
    }
    instrument_metadata <- as.list(instrument_metadata[1L, , drop = FALSE])
  }

  structure(
    list(
      lambda = lambda,
      value = value,
      measurement = measurement,
      value_scale = value_scale,
      meta = list(
        source = basename(path),
        instrument = instrument_metadata,
        import = context,
        import_notices = unique(c(parsed$warnings,
                                  parsed_metadata$warnings)),
        preprocessing = list(
          interpolation = if (interpolate) {
            "lightr integer-nm interpolation"
          } else {
            "none"
          },
          requested_range_nm = range
        )
      )
    ),
    class = "lux_instrument_spectrum"
  )
}

#' @export
print.lux_instrument_spectrum <- function(x, ...) {
  cat(sprintf(
    "<lux_instrument_spectrum> %s [%s] | %.4g-%.4g nm (%d pts)\n",
    x$measurement, x$value_scale, min(x$lambda), max(x$lambda),
    length(x$lambda)
  ))
  invisible(x)
}

#' @export
as.data.frame.lux_instrument_spectrum <- function(x, ...) {
  data.frame(lambda = x$lambda, value = x$value)
}
