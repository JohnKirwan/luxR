# conditions.R -- one error hierarchy for luxR

#' luxR error conditions
#'
#' Every error raised by luxR inherits from \code{luxR_error} and carries
#' exactly one \emph{kind} class saying what went wrong, so callers can catch
#' errors by kind with \code{tryCatch()}.
#'
#' \tabular{ll}{
#'   \code{luxR_type_error} \tab Wrong R type or class: not numeric, not a
#'     \code{lux_spectrum}, not a list, not \code{TRUE}/\code{FALSE}, or an
#'     unsupported operand. \cr
#'   \code{luxR_value_error} \tab Right type, invalid value: out of range,
#'     non-finite, a required argument missing, a name not in a lookup
#'     (species, receptor, condition, water type, column), or a channel the
#'     species lacks. \cr
#'   \code{luxR_dimension_error} \tab Lengths or shapes disagree. \cr
#'   \code{luxR_grid_error} \tab A wavelength grid is invalid or
#'     incompatible: unordered, irregular, mismatched, or an empty window. \cr
#'   \code{luxR_unit_error} \tab A unit or physical quantity is unknown or
#'     incompatible. \cr
#'   \code{luxR_numerical_error} \tab A computation produced a non-finite or
#'     invalid result from valid input. \cr
#'   \code{luxR_format_error} \tab A file's contents do not match the
#'     expected format. \cr
#'   \code{luxR_data_error} \tab A bundled dataset or its metadata is
#'     inconsistent. \cr
#'   \code{luxR_dependency_error} \tab A suggested package needed for the
#'     call is not installed. \cr
#'   \code{luxR_internal_error} \tab A package invariant broke; please report
#'     it as a luxR bug. \cr
#' }
#'
#' Errors raised while importing a file also carry \code{luxR_import_error},
#' between the kind and \code{luxR_error}, whatever their kind.
#'
#' Conditions carry fields describing the failure where they apply:
#' \code{field} (the argument or column at fault), \code{value} (the
#' offending value) and \code{index} (its position). Import errors add
#' \code{line}, \code{row} and the source file's context (path, checksum,
#' reader configuration).
#'
#' @name luxR-conditions
#' @aliases luxR_error luxR_import_error luxR_type_error luxR_value_error
#'   luxR_dimension_error luxR_grid_error luxR_unit_error
#'   luxR_numerical_error luxR_format_error luxR_data_error
#'   luxR_dependency_error luxR_internal_error
#' @keywords classes
#' @examples
#' tryCatch(
#'   lux_spectrum(1:3, c(400, 410, 405), "irradiance", "W/m2/nm"),
#'   luxR_error = function(e) class(e)[1]
#' )
NULL

.LUXR_ERROR_KINDS <- c(
  "type", "value", "dimension", "grid", "unit", "numerical",
  "format", "data", "dependency", "internal"
)

.luxr_internal_error <- function(message) {
  stop(structure(
    list(message = paste0("luxR internal error: ", message), call = NULL),
    class = c("luxR_internal_error", "luxR_error", "error", "condition")
  ))
}

.luxr_abort <- function(message, kind, ..., import = FALSE,
                        .fields = list()) {
  if (!is.character(message) || length(message) == 0L || anyNA(message)) {
    .luxr_internal_error("`message` must be a non-missing character vector.")
  }
  # Collapse as stop() does when a user argument is a vector.
  message <- paste(message, collapse = "")
  if (!is.character(kind) || length(kind) != 1L ||
      !kind %in% .LUXR_ERROR_KINDS) {
    .luxr_internal_error(paste0("unknown error kind '",
                                paste(kind, collapse = ", "), "'."))
  }
  if (!isTRUE(import) && !isFALSE(import)) {
    .luxr_internal_error("`import` must be TRUE or FALSE.")
  }
  if (!is.list(.fields)) {
    .luxr_internal_error("`.fields` must be a list.")
  }
  # `.fields` carries context assembled elsewhere: it is stored verbatim,
  # never evaluated and never matched to this function's arguments.
  fields <- c(list(...), .fields)
  nms <- names(fields)
  if (length(fields) > 0L && (is.null(nms) || any(!nzchar(nms)))) {
    .luxr_internal_error("every condition field must be named.")
  }
  if (any(nms %in% c("message", "call", "call."))) {
    .luxr_internal_error(
      "condition fields may not be named `message`, `call` or `call.`."
    )
  }
  stop(structure(
    c(list(message = message, call = NULL), fields),
    class = c(paste0("luxR_", kind, "_error"),
              if (import) "luxR_import_error",
              "luxR_error", "error", "condition")
  ))
}

.luxr_error_kind <- function(e) {
  kind <- sub("^luxR_(.*)_error$", "\\1", class(e))
  kind <- kind[kind %in% .LUXR_ERROR_KINDS]
  if (length(kind) != 1L) {
    .luxr_internal_error(paste0("condition has no single luxR kind class: ",
                                paste(class(e), collapse = "/"), "."))
  }
  kind
}

# Wraps requireNamespace() so tests can mock a missing suggested package.
.is_installed <- function(pkg) requireNamespace(pkg, quietly = TRUE)

.require_suggested <- function(pkg, message) {
  if (!.is_installed(pkg)) .luxr_abort(message, "dependency", package = pkg)
  invisible(TRUE)
}
