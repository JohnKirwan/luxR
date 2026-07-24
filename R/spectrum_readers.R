# spectrum_readers - format-specific lux_spectrum constructors

#' Load a Naples depth spectrum as a lux_spectrum
#'
#' @param depth One of \code{"0m"}, \code{"5m"}, \code{"10m"}.
#' @return A \code{lux_spectrum} with unit \code{"umol/m2/s/nm"}.
#' @seealso \code{\link{Naples}}, \code{\link{as_lux_spectrum}}
#' @examples
#' x <- from_naples("0m")
#' print(x)
#' @export
from_naples <- function(depth = c("0m", "5m", "10m")) {
  depth <- match.arg(depth)
  col <- paste0("depth_", depth)
  reference_depth_m <- switch(depth, "0m" = 0, "5m" = 5, "10m" = 10)
  provenance <- .bundled_dataset_provenance(Naples, "Naples")
  lux_spectrum(
    E = Naples[[col]], lambda = Naples$wv, quantity = "irradiance",
    unit = "umol/m2/s/nm",
    meta = list(depth = depth, source = "Naples",
                reference_depth_m = reference_depth_m,
                reference_medium = "water",
                provenance = provenance,
                import = .bundled_source_import(provenance))
  )
}

#' Load a reference solar spectrum as a lux_spectrum
#'
#' @param condition One of \code{"clear_noon"}, \code{"clear_dawn"},
#'   \code{"overcast"}, \code{"underwater_1m"}, or \code{"underwater_10m"}.
#' @return A \code{lux_spectrum} with unit \code{"W/m2/nm"}.
#' @seealso \code{\link{solar_irradiance}}, \code{\link{as_lux_spectrum}}
#' @examples
#' x <- from_solar("clear_noon")
#' print(x)
#' @export
from_solar <- function(condition = "clear_noon") {
  valid <- c("clear_noon", "clear_dawn", "overcast",
             "underwater_1m", "underwater_10m")
  if (!condition %in% valid)
    stop("condition must be one of: ", paste(valid, collapse = ", "))
  sp <- solar_irradiance(condition)
  provenance <- .bundled_dataset_provenance(solar_spectra, "solar_spectra")
  lux_spectrum(
    E = sp$irradiance, lambda = sp$wavelength, quantity = "irradiance",
    unit = "W/m2/nm",
    meta = list(condition = condition, source = "ASTM G173-03",
                reference_depth_m = attr(sp, "reference_depth_m", exact = TRUE),
                reference_medium = attr(sp, "reference_medium", exact = TRUE),
                provenance = provenance,
                import = .bundled_source_import(provenance))
  )
}

#' Read a TriOS RAMSES file as calibrated radiance spectra
#'
#' Wraps \code{\link{read_trios}}. The low-level reader preserves negative
#' instrument values. Construction of non-negative physical radiance spectra
#' therefore either fails (the default) or requires an explicit, recorded
#' zero-floor preprocessing policy.
#'
#' @param path Path to a TriOS RAMSES \code{.dat} file.
#' @param negative_policy Either \code{"error"} (default) or \code{"zero"}.
#' @return A named list of radiance \code{lux_spectrum} objects.
#' @seealso \code{\link{read_trios}}, \code{\link{read_spectrum}}
#' @export
from_trios <- function(path, negative_policy = c("error", "zero")) {
  negative_policy <- match.arg(negative_policy)
  df <- read_trios(path)
  import_context <- attr(df, "luxR.import", exact = TRUE)
  names <- unique(df$spectrum)
  out <- lapply(names, function(name) {
    block <- df[df$spectrum == name, , drop = FALSE]
    negative <- which(block$radiance < 0)
    preprocessing <- list(method = "none", affected_count = 0L,
                          affected_indices = integer())
    if (length(negative) && negative_policy == "error") {
      context <- import_context
      context$configuration$negative_policy <- negative_policy
      .stop_spectrum_import(
        paste0("Spectrum '", name, "' contains negative calibrated radiance ",
               "at row ", negative[[1L]], "; inspect it with `read_trios()` ",
               "or explicitly set `negative_policy = \"zero\"`."),
        context, class = "luxR_spectrum_value_error", field = "radiance",
        value = block$radiance[negative[[1L]]], row = negative[[1L]],
        spectrum = name
      )
    }
    if (length(negative)) {
      block$radiance[negative] <- 0
      preprocessing <- list(method = "zero_floor",
                            affected_count = length(negative),
                            affected_indices = negative)
    }
    .construct_imported_lux_spectrum(
      E = block$radiance, lambda = block$lambda, quantity = "radiance",
      unit = "W/m2/sr/nm",
      meta = list(
        label = name,
        calibration_state = "instrument-calibrated spectral radiance",
        import = import_context,
        preprocessing = preprocessing
      ),
      context = import_context
    )
  })
  names(out) <- names
  out
}

#' Strictly parse an Ocean Optics / Ocean Insight spectrum file
#'
#' Parses the plain-text format without assigning a physical quantity or unit.
#' Every row must contain exactly two tab-separated numeric fields. Instrument
#' values, including negatives, are preserved without clipping.
#'
#' @param path Path to the Ocean Optics \code{.txt} file.
#' @return A data frame containing \code{lambda} and \code{signal}. Parsed header
#'   and import provenance are attached as \code{"luxR.header"} and
#'   \code{"luxR.import"} attributes.
#' @export
read_ocean_optics <- function(path) {
  context <- .validate_import_path(
    path, format = "Ocean Optics", operation = "read_ocean_optics",
    configuration = list(physical_interpretation = "none",
                         negative_policy = "preserve")
  )
  input <- readLines(path, warn = FALSE)
  begin <- grep("^>>>>>Begin (Processed )?Spectral Data<<<<<$", input)
  if (length(begin) != 1L) {
    .stop_spectrum_import(
      paste0("Expected exactly one Ocean Optics spectral-data delimiter; found ",
             length(begin), "."),
      context, class = "luxR_spectrum_format_error", field = "data_delimiter",
      value = length(begin)
    )
  }
  begin <- begin[[1L]]
  end <- grep("^>>>>>End (Processed )?Spectral Data<<<<<$", input)
  if (length(end) > 1L || (length(end) == 1L && end[[1L]] <= begin)) {
    .stop_spectrum_import(
      "Ocean Optics spectral-data end delimiter is duplicated or misplaced.",
      context, class = "luxR_spectrum_format_error", field = "end_delimiter",
      value = end
    )
  }
  data_end <- if (length(end)) end[[1L]] - 1L else length(input)
  data_lines <- if (data_end >= begin + 1L) input[seq.int(begin + 1L, data_end)] else character()
  if (!length(data_lines)) {
    .stop_spectrum_import(
      "Ocean Optics spectral-data block is empty.", context,
      class = "luxR_spectrum_schema_error", field = "data"
    )
  }

  header <- list()
  header_lines <- if (begin > 1L) input[seq_len(begin - 1L)] else character()
  for (i in seq_along(header_lines)) {
    line <- header_lines[[i]]
    if (grepl("^Spectrometer:", line))
      header$instrument <- trimws(sub("^Spectrometer:[[:space:]]*", "", line))
    if (grepl("^Integration Time \\(usec\\):", line)) {
      token <- trimws(sub("^Integration Time \\(usec\\):[[:space:]]*", "", line))
      header$integration_time_us <- .parse_import_number(
        token, "integration_time_us", context, line = i
      )
      if (header$integration_time_us <= 0) {
        .stop_spectrum_import(
          paste0("Integration time must be positive; got ", token, "."),
          context, class = "luxR_spectrum_value_error",
          field = "integration_time_us", value = header$integration_time_us,
          line = i
        )
      }
    }
    if (grepl("^Date:", line))
      header$date <- trimws(sub("^Date:[[:space:]]*", "", line))
    if (grepl("^Number of Pixels in Spectrum:", line)) {
      token <- trimws(sub("^Number of Pixels in Spectrum:[[:space:]]*", "", line))
      header$declared_pixels <- .parse_import_number(
        token, "declared_pixels", context, line = i
      )
    }
  }

  parsed <- t(vapply(seq_along(data_lines), function(i) {
    source_line <- begin + i
    text <- trimws(data_lines[[i]])
    if (!nzchar(text)) {
      .stop_spectrum_import(
        paste0("Blank spectral row at source line ", source_line, "."),
        context, class = "luxR_spectrum_schema_error", field = "row",
        value = data_lines[[i]], row = i, line = source_line
      )
    }
    fields <- strsplit(text, "\t", fixed = TRUE)[[1L]]
    if (length(fields) != 2L) {
      .stop_spectrum_import(
        paste0("Ocean Optics spectral row ", i, " at source line ",
               source_line, " must contain exactly two tab-separated fields; ",
               "got ", length(fields), "."),
        context, class = "luxR_spectrum_schema_error", field = "row",
        value = data_lines[[i]], row = i, line = source_line
      )
    }
    c(lambda = .parse_import_number(fields[[1L]], "wavelength", context,
                                    i, source_line),
      signal = .parse_import_number(fields[[2L]], "signal", context,
                                    i, source_line))
  }, numeric(2L)))
  .validate_import_grid(parsed[, "lambda"], context,
                        seq.int(begin + 1L, data_end))
  if (!is.null(header$declared_pixels) &&
      (header$declared_pixels != nrow(parsed) ||
       header$declared_pixels != as.integer(header$declared_pixels))) {
    .stop_spectrum_import(
      paste0("Header declares ", format(header$declared_pixels),
             " pixels but ", nrow(parsed), " spectral rows were parsed."),
      context, class = "luxR_spectrum_schema_error",
      field = "declared_pixels", value = header$declared_pixels
    )
  }
  out <- data.frame(lambda = parsed[, "lambda"], signal = parsed[, "signal"])
  attr(out, "luxR.header") <- header
  attr(out, "luxR.import") <- context
  out
}

#' Read a calibrated Ocean Optics spectrum as a lux_spectrum
#'
#' Ocean Optics text files do not contain a standardized machine-readable unit
#' or calibration state. All physical declarations are therefore required.
#' Use \code{\link{read_ocean_optics}} to inspect raw or relative values.
#'
#' @param path Path to the Ocean Optics text file.
#' @param quantity Explicit physical quantity represented by the values.
#' @param unit Explicit unit compatible with \code{quantity}.
#' @param calibration Non-empty calibration identifier or description.
#' @return A validated \code{lux_spectrum} with import provenance in metadata.
#' @seealso \code{\link{read_ocean_optics}}, \code{\link{from_trios}},
#'   \code{\link{read_spectrum}}
#' @export
from_ocean_optics <- function(path, quantity = NULL, unit = NULL,
                              calibration = NULL) {
  context <- .validate_import_path(
    path, format = "Ocean Optics", operation = "from_ocean_optics",
    configuration = list(quantity = quantity, unit = unit,
                         calibration = calibration,
                         negative_policy = "error")
  )
  quantity <- .validate_import_string(quantity, "quantity", context)
  unit <- .validate_import_string(unit, "unit", context)
  calibration <- .validate_import_string(calibration, "calibration", context)
  context$configuration <- list(quantity = quantity, unit = unit,
                                calibration = calibration,
                                negative_policy = "error")
  raw <- tryCatch(
    read_ocean_optics(path),
    luxR_spectrum_import_error = function(e) {
      for (name in names(context)) e[[name]] <- context[[name]]
      stop(e)
    }
  )
  .construct_imported_lux_spectrum(
    E = raw$signal, lambda = raw$lambda, quantity = quantity, unit = unit,
    meta = c(
      attr(raw, "luxR.header", exact = TRUE),
      list(calibration_state = "declared calibrated",
           calibration = calibration, import = context,
           preprocessing = list(method = "none", affected_count = 0L))
    ),
    context = context
  )
}
