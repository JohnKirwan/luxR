# Shared numeric-vector validation.
#
# `fail(message, field, value, index, kind)` raises the calling module's typed
# error. `kind` is "type" for a non-numeric input and "value" otherwise.
.check_numeric <- function(x, field, fail, scalar = FALSE, lower = NULL,
                           upper = NULL, lower_open = FALSE) {
  name <- paste0("`", field, "`")
  if (!is.numeric(x) || is.complex(x) || is.object(x) || !is.null(dim(x))) {
    fail(paste0(name, " must be a numeric vector; got ",
                paste(class(x), collapse = "/"), "."),
         field, x, NULL, "type")
  }
  if (length(x) == 0L) {
    fail(paste0(name, " must be non-empty."), field, x, NULL, "value")
  }
  if (scalar && length(x) != 1L) {
    fail(paste0(name, " must be one numeric value; got length ", length(x),
                "."),
         field, x, NULL, "value")
  }
  require_all <- function(valid, requirement) {
    if (all(valid)) return(invisible())
    i <- which(!valid)[[1L]]
    fail(paste0(name, " must ", requirement, "; index ", i, " is ",
                format(x[[i]]), "."),
         field, x[[i]], i, "value")
  }
  require_all(is.finite(x), "contain only finite values")
  if (!is.null(lower)) {
    if (lower_open) {
      require_all(x > lower, paste0("be greater than ", format(lower)))
    } else if (lower == 0) {
      require_all(x >= 0, "contain only non-negative values")
    } else {
      require_all(x >= lower, paste0("be at least ", format(lower)))
    }
  }
  if (!is.null(upper)) {
    require_all(x <= upper, paste0("be at most ", format(upper)))
  }
  invisible(x)
}

# `fail` callback raising a typed lux_spectrum error prefixed with the
# operation, e.g. "photic_depth(): `Kd` must ...".
.input_fail <- function(operation) {
  function(message, field, value, index, kind) {
    .stop_lux_spectrum_validation(
      paste0(operation, ": ", message), field = field, value = value,
      index = index, subclass = paste0("lux_spectrum_", kind, "_error")
    )
  }
}

.check_input <- function(x, field, operation, ...) {
  .check_numeric(x, field, .input_fail(operation), ...)
}

# Bin width (nm) of a strictly increasing, regularly spaced wavelength grid.
# A supplied `binwidth` must equal the spacing; a single wavelength needs one.
.grid_binwidth <- function(lambda, binwidth = NULL, operation) {
  fail <- .input_fail(operation)
  .check_input(lambda, "lambda", operation, lower = 0, lower_open = TRUE)
  steps <- diff(lambda)
  bad <- which(steps <= 0)[1L]
  if (!is.na(bad)) {
    fail(paste0("`lambda` must be strictly increasing; index ", bad + 1L,
                " has value ", format(lambda[bad + 1L]), " after ",
                format(lambda[bad]), "."),
         "lambda", lambda[bad + 1L], bad + 1L, "grid")
  }
  bad <- which(abs(steps - steps[1L]) > .grid_tolerance(steps))[1L]
  if (!is.na(bad)) {
    fail(paste0("`lambda` must be regularly spaced; the step before index ",
                bad + 1L, " is ", format(steps[bad]), " nm, expected ",
                format(steps[1L]), " nm."),
         "lambda", lambda[bad + 1L], bad + 1L, "grid")
  }
  if (is.null(binwidth)) {
    if (length(lambda) == 1L) {
      fail("`binwidth` is required for a single wavelength.", "binwidth",
           NULL, NULL, "value")
    }
    return(steps[1L])
  }
  .check_input(binwidth, "binwidth", operation, scalar = TRUE, lower = 0,
               lower_open = TRUE)
  if (length(lambda) > 1L &&
      abs(binwidth - steps[1L]) > .grid_tolerance(binwidth, steps[1L])) {
    fail(paste0("`binwidth` (", format(binwidth), " nm) must equal the ",
                "wavelength spacing (", format(steps[1L]), " nm)."),
         "binwidth", binwidth, NULL, "grid")
  }
  binwidth
}

# `fail` callback raising lux_spectrum validation errors.
.lux_spectrum_fail <- function(context = list()) {
  function(message, field, value, index, kind) {
    .stop_lux_spectrum_validation(
      message, field = field, value = value, index = index,
      subclass = paste0("lux_spectrum_", kind, "_error"), context = context
    )
  }
}

# Two vectors combined elementwise must have equal lengths, or one of length 1.
.check_recyclable <- function(a, b, fields, operation) {
  if (length(a) == length(b) || length(a) == 1L || length(b) == 1L) {
    return(invisible())
  }
  .stop_lux_spectrum_validation(
    paste0(operation, ": `", fields[1L], "` (length ", length(a), ") and `",
           fields[2L], "` (length ", length(b), ") must have equal lengths, ",
           "or one must have length 1."),
    field = fields, value = c(length(a), length(b)),
    subclass = "lux_spectrum_dimension_error"
  )
}
