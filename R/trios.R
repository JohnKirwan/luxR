#' Read a TriOS RAMSES spectroradiometer data file
#'
#' Parses one or more spectra from a TriOS RAMSES `.dat` text file. Each
#' spectrum is preceded by a `Comment` header line and terminated by a `[END]`
#' marker. Data rows contain three whitespace-separated fields: index,
#' wavelength (nm), and spectral radiance (mW m\eqn{^{-2}} nm\eqn{^{-1}}
#' sr\eqn{^{-1}}). Radiance values are converted to W m\eqn{^{-2}} nm\eqn{^{-1}}
#' sr\eqn{^{-1}}. Negative instrument values are preserved; no clipping or
#' other preprocessing is performed by this low-level reader.
#'
#' @param path Character. Path to the `.dat` file.
#' @return A \code{data.frame} with columns:
#'   \describe{
#'     \item{spectrum}{Character. Spectrum label from the Comment header.}
#'     \item{lambda}{Numeric. Wavelength in nm.}
#'     \item{radiance}{Numeric. Spectral radiance in W m\eqn{^{-2}} nm\eqn{^{-1}} sr\eqn{^{-1}}.}
#'   }
#' @export
read_trios <- function(path) {
  context <- .validate_import_path(
    path, format = "TriOS RAMSES", operation = "read_trios",
    configuration = list(native_unit = "mW/m2/sr/nm",
                         output_unit = "W/m2/sr/nm",
                         negative_policy = "preserve")
  )
  raw <- readLines(path, warn = FALSE)
  comment_idx <- grep("^Comment", raw)
  if (length(comment_idx) == 0L) {
    .stop_spectrum_import(
      paste0("No 'Comment' blocks found in file: ", path), context,
      class = "luxR_spectrum_format_error", field = "Comment"
    )
  }

  result_list <- vector("list", length(comment_idx))
  labels <- character(length(comment_idx))
  for (k in seq_along(comment_idx)) {
    ci <- comment_idx[[k]]
    label <- trimws(sub("^Comment[[:space:]]+", "", raw[[ci]]))
    if (!nzchar(label) || identical(label, raw[[ci]])) {
      .stop_spectrum_import(
        paste0("Spectrum block at source line ", ci,
               " has an empty or malformed Comment label."),
        context, class = "luxR_spectrum_schema_error", field = "Comment",
        value = raw[[ci]], line = ci
      )
    }
    labels[[k]] <- label
    if (k > 1L && any(labels[seq_len(k - 1L)] == label)) {
      .stop_spectrum_import(
        paste0("Duplicate spectrum label '", label,
               "' at source line ", ci, "."),
        context, class = "luxR_spectrum_schema_error", field = "Comment",
        value = label, line = ci, spectrum = label
      )
    }

    data_start <- ci + 30L
    if (data_start > length(raw)) {
      .stop_spectrum_import(
        paste0("Spectrum '", label,
               "' ends before its required 29-line header is complete."),
        context, class = "luxR_spectrum_schema_error", field = "header",
        line = ci, spectrum = label
      )
    }
    next_comment <- if (k < length(comment_idx)) comment_idx[[k + 1L]] else Inf
    end_idx <- which(raw == "[END]" & seq_along(raw) >= data_start &
                     seq_along(raw) < next_comment)
    if (length(end_idx) == 0L) {
      .stop_spectrum_import(
        paste0("No [END] marker found after spectrum '", label, "'."),
        context, class = "luxR_spectrum_format_error", field = "[END]",
        line = ci, spectrum = label
      )
    }
    data_end <- end_idx[[1L]] - 1L
    if (data_start > data_end) {
      .stop_spectrum_import(
        paste0("Empty data block for spectrum '", label, "'."),
        context, class = "luxR_spectrum_schema_error", field = "data",
        line = end_idx[[1L]], spectrum = label
      )
    }

    data_lines <- raw[data_start:data_end]
    parsed <- t(vapply(seq_along(data_lines), function(i) {
      source_line <- data_start + i - 1L
      text <- trimws(data_lines[[i]])
      if (!nzchar(text)) {
        .stop_spectrum_import(
          paste0("Blank spectral row at source line ", source_line, "."),
          context, class = "luxR_spectrum_schema_error", field = "row",
          value = data_lines[[i]], row = i, line = source_line,
          spectrum = label
        )
      }
      fields <- strsplit(text, "[[:space:]]+")[[1L]]
      if (length(fields) != 3L) {
        .stop_spectrum_import(
          paste0("TriOS spectral row ", i, " at source line ", source_line,
                 " must contain exactly three fields; got ",
                 length(fields), "."),
          context, class = "luxR_spectrum_schema_error", field = "row",
          value = data_lines[[i]], row = i, line = source_line,
          spectrum = label
        )
      }
      c(
        index = .parse_import_number(fields[[1L]], "index", context,
                                     i, source_line, label),
        wavelength = .parse_import_number(fields[[2L]], "wavelength", context,
                                          i, source_line, label),
        radiance = .parse_import_number(fields[[3L]], "radiance", context,
                                        i, source_line, label)
      )
    }, numeric(3L)))

    first_index <- parsed[1L, "index"]
    expected_index <- first_index + seq_len(nrow(parsed)) - 1L
    valid_index <- first_index %in% c(0, 1) &&
      all(parsed[, "index"] == expected_index)
    if (!valid_index) {
      bad_index <- which(parsed[, "index"] != expected_index)
      i <- if (length(bad_index)) bad_index[[1L]] else 1L
      .stop_spectrum_import(
        paste0("TriOS row index must be consecutive from 0 or 1; row ", i,
               " contains ", format(parsed[i, "index"]), "."),
        context, class = "luxR_spectrum_schema_error", field = "index",
        value = parsed[i, "index"], row = i, line = data_start + i - 1L,
        spectrum = label
      )
    }
    wavelength <- parsed[, "wavelength"]
    .validate_import_grid(wavelength, context, seq.int(data_start, data_end),
                          label)
    result_list[[k]] <- data.frame(
      spectrum = label,
      lambda = wavelength,
      radiance = parsed[, "radiance"] * 1e-3,
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, result_list)
  rownames(out) <- NULL
  attr(out, "luxR.import") <- context
  out
}
