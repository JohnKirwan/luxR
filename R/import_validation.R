# Strict spectral-import validation and diagnostic context.

.SPECTRUM_IMPORT_MODEL_VERSION <- "1.0.0"

.spectrum_import_context <- function(path, format, operation,
                                     configuration = list()) {
  path_text <- if (is.character(path) && length(path) == 1L &&
                   !is.na(path)) path else NA_character_
  existing <- !is.na(path_text) && file.exists(path_text)
  normalized <- if (existing) {
    normalizePath(path_text, winslash = "/", mustWork = TRUE)
  } else {
    path_text
  }
  checksum <- if (existing) {
    unname(tools::md5sum(normalized))
  } else {
    NA_character_
  }
  list(
    operation = operation,
    format = format,
    source_path = normalized,
    source_checksum_md5 = checksum,
    reader_model_version = .SPECTRUM_IMPORT_MODEL_VERSION,
    package_version = .luxr_package_version(),
    code_commit = .luxr_code_commit(),
    configuration = configuration
  )
}

.stop_spectrum_import <- function(message, context, kind,
                                  field = NULL, value = NULL,
                                  row = NULL, line = NULL,
                                  spectrum = NULL) {
  do.call(.luxr_abort, c(
    list(message, kind, import = TRUE),
    list(field = field, value = value, row = row, line = line,
         spectrum = spectrum),
    context
  ))
}

.validate_import_path <- function(path, format, operation,
                                  configuration = list()) {
  context <- .spectrum_import_context(path, format, operation, configuration)
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !nzchar(path)) {
    .stop_spectrum_import(
      "`path` must be one non-empty, non-missing string.", context,
      kind = if (is.character(path)) "value" else "type", field = "path", value = path
    )
  }
  if (!file.exists(path)) {
    .stop_spectrum_import(
      paste0("File does not exist: ", path), context,
      kind = "value", field = "path", value = path
    )
  }
  info <- file.info(path)
  if (is.na(info$isdir) || info$isdir) {
    .stop_spectrum_import(
      paste0("`path` must identify a readable file: ", path), context,
      kind = "value", field = "path", value = path
    )
  }
  context
}

.validate_import_string <- function(x, field, context) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    .stop_spectrum_import(
      paste0("`", field, "` must be one non-empty, non-missing string."),
      context, kind = if (is.character(x)) "value" else "type",
      field = field, value = x
    )
  }
  trimws(x)
}

.parse_import_number <- function(token, field, context, row = NULL,
                                 line = NULL, spectrum = NULL) {
  token <- trimws(token)
  if (!nzchar(token)) {
    .stop_spectrum_import(
      paste0("Empty numeric field `", field, "` at source line ", line, "."),
      context, kind = "format", field = field,
      value = token, row = row, line = line, spectrum = spectrum
    )
  }
  value <- tryCatch(
    as.numeric(token),
    warning = function(w) NA_real_,
    error = function(e) NA_real_
  )
  if (length(value) != 1L || is.na(value) || !is.finite(value)) {
    .stop_spectrum_import(
      paste0("Invalid numeric value for `", field, "` at source line ",
             line, ": '", token, "'."),
      context, kind = "value", field = field,
      value = token, row = row, line = line, spectrum = spectrum
    )
  }
  value
}

.validate_import_grid <- function(lambda, context, line_numbers = NULL,
                                  spectrum = NULL) {
  bad <- which(diff(lambda) <= 0)
  if (length(bad)) {
    i <- bad[[1L]] + 1L
    source_line <- if (is.null(line_numbers)) NULL else line_numbers[[i]]
    .stop_spectrum_import(
      paste0("Wavelengths must be strictly increasing and unique; row ", i,
             " is ", format(lambda[[i]]), " nm after ",
             format(lambda[[i - 1L]]), " nm."),
      context, kind = "grid", field = "wavelength",
      value = lambda[[i]], row = i, line = source_line, spectrum = spectrum
    )
  }
  invisible(lambda)
}

.construct_imported_lux_spectrum <- function(E, lambda, quantity, unit, meta,
                                             context) {
  tryCatch(
    lux_spectrum(E = E, lambda = lambda, quantity = quantity, unit = unit,
                 meta = meta),
    luxR_error = function(e) {
      if (inherits(e, "luxR_internal_error")) stop(e)
      .stop_spectrum_import(
        paste0("Imported spectrum violates the declared physical contract: ",
               conditionMessage(e)),
        context, kind = .luxr_error_kind(e), field = e$field,
        value = e$value, row = e$index
      )
    }
  )
}
