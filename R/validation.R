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

# `fail` callback raising lux_spectrum validation errors.
.lux_spectrum_fail <- function(context = list()) {
  function(message, field, value, index, kind) {
    .stop_lux_spectrum_validation(
      message, field = field, value = value, index = index,
      subclass = paste0("lux_spectrum_", kind, "_error"), context = context
    )
  }
}
